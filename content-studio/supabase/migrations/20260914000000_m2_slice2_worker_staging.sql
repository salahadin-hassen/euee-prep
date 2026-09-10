-- M2 Slice 2: worker leases, extraction staging, and trusted ingestion RPCs.
-- These mutation functions are intentionally executable only by the trusted
-- server-side control plane using the service_role, never by browser clients.

alter table public.extraction_jobs
  add column claimed_by text,
  add column claimed_at timestamptz,
  add column lease_expires_at timestamptz,
  add column worker_attempt_count integer not null default 0 check (worker_attempt_count >= 0);

alter table public.extraction_job_pages
  add column result_checksum text,
  add column result_schema_version text;

create index extraction_jobs_lease_idx
  on public.extraction_jobs(status, lease_expires_at);

create table public.extraction_questions (
  id uuid primary key default gen_random_uuid(),
  job_page_id uuid not null references public.extraction_job_pages(id) on delete cascade,
  extraction_question_key text not null unique,
  question_number integer not null check (question_number > 0),
  prompt text not null,
  choices jsonb not null check (jsonb_typeof(choices) = 'array'),
  source_region jsonb,
  uncertainties jsonb not null default '[]'::jsonb check (jsonb_typeof(uncertainties) = 'array'),
  ai_predicted_choice_index integer,
  ai_confidence text,
  ai_reasoning text,
  ai_answer_basis text,
  verification_status text,
  verification_findings jsonb not null default '[]'::jsonb check (jsonb_typeof(verification_findings) = 'array'),
  imported_question_id uuid references public.questions(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (job_page_id, question_number)
);

create index extraction_questions_job_page_idx on public.extraction_questions(job_page_id, question_number);
create index extraction_questions_imported_question_idx on public.extraction_questions(imported_question_id);

create table public.extraction_visual_assets (
  id uuid primary key default gen_random_uuid(),
  extraction_question_id uuid not null references public.extraction_questions(id) on delete cascade,
  asset_key text not null unique,
  asset_type text not null,
  storage_path text,
  source_region jsonb not null,
  confidence text not null,
  uncertainties jsonb not null default '[]'::jsonb check (jsonb_typeof(uncertainties) = 'array'),
  sha256 text not null,
  pixel_width integer not null check (pixel_width > 0),
  pixel_height integer not null check (pixel_height > 0),
  created_at timestamptz not null default now(),
  unique (extraction_question_id, asset_key)
);

create index extraction_visual_assets_question_idx
  on public.extraction_visual_assets(extraction_question_id);

alter table public.extraction_questions enable row level security;
alter table public.extraction_visual_assets enable row level security;

create policy "project members can read extraction questions"
  on public.extraction_questions for select to authenticated
  using (
    exists (
      select 1
      from public.extraction_job_pages jp
      join public.extraction_jobs j on j.id = jp.job_id
      where jp.id = job_page_id and public.is_project_member(j.project_id)
    )
  );

create policy "project members can read extraction visual assets"
  on public.extraction_visual_assets for select to authenticated
  using (
    exists (
      select 1
      from public.extraction_questions eq
      join public.extraction_job_pages jp on jp.id = eq.job_page_id
      join public.extraction_jobs j on j.id = jp.job_id
      where eq.id = extraction_question_id and public.is_project_member(j.project_id)
    )
  );

grant select on public.extraction_questions, public.extraction_visual_assets to authenticated;

create or replace function public.worker_request_is_valid(p_worker_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.role() = 'service_role'
    and p_worker_id ~ '^[A-Za-z0-9._:-]{1,128}$';
$$;

revoke execute on function public.worker_request_is_valid(text) from public, anon, authenticated, service_role;

create or replace function public.claim_extraction_job(
  p_job_id uuid,
  p_worker_id text,
  p_lease_seconds integer default 1800
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  job_row public.extraction_jobs%rowtype;
  source_row public.source_documents%rowtype;
  effective_attempt integer;
begin
  if not public.worker_request_is_valid(p_worker_id)
     or p_lease_seconds is null or p_lease_seconds < 60 or p_lease_seconds > 1800 then
    raise exception 'Invalid worker claim request' using errcode = '42501';
  end if;

  select * into job_row
  from public.extraction_jobs
  where id = p_job_id
  for update;
  if not found then raise exception 'Extraction job not found' using errcode = 'P0002'; end if;

  if job_row.status = 'cancelled' then
    raise exception 'Cancelled jobs cannot be claimed' using errcode = '55000';
  end if;
  if job_row.status in ('completed', 'completed_with_errors', 'quota_exhausted') then
    raise exception 'Terminal jobs cannot be claimed' using errcode = '55000';
  end if;
  if job_row.status = 'processing'
     and job_row.lease_expires_at is not null
     and job_row.lease_expires_at > now() then
    raise exception 'Job is already claimed' using errcode = '55000';
  end if;

  effective_attempt := job_row.worker_attempt_count + 1;
  update public.extraction_jobs
  set status = 'processing',
      claimed_by = p_worker_id,
      claimed_at = now(),
      lease_expires_at = now() + make_interval(secs => p_lease_seconds),
      worker_attempt_count = effective_attempt,
      started_at = coalesce(started_at, now()),
      updated_at = now()
  where id = p_job_id;

  select * into source_row from public.source_documents where id = job_row.source_document_id;
  insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
  values (
    job_row.created_by, 'extraction_job.claimed', 'extraction_job', job_row.id,
    jsonb_build_object('project_id', job_row.project_id, 'worker_id', p_worker_id, 'attempt', effective_attempt, 'actor_type', 'worker')
  );

  return jsonb_build_object(
    'job_id', job_row.id,
    'project_id', job_row.project_id,
    'source_document_id', job_row.source_document_id,
    'storage_path', source_row.storage_path,
    'requested_pages', job_row.requested_pages,
    'worker_attempt_count', effective_attempt,
    'lease_expires_at', now() + make_interval(secs => p_lease_seconds)
  );
end;
$$;

create or replace function public.renew_extraction_job_lease(
  p_job_id uuid,
  p_worker_id text,
  p_lease_seconds integer default 1800
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.worker_request_is_valid(p_worker_id)
     or p_lease_seconds is null or p_lease_seconds < 60 or p_lease_seconds > 1800 then
    raise exception 'Invalid worker lease request' using errcode = '42501';
  end if;
  update public.extraction_jobs
  set lease_expires_at = now() + make_interval(secs => p_lease_seconds), updated_at = now()
  where id = p_job_id and status = 'processing' and claimed_by = p_worker_id
    and (lease_expires_at is null or lease_expires_at > now());
  if not found then raise exception 'Job is not owned by this worker or its lease expired' using errcode = '42501'; end if;
end;
$$;

create or replace function public.record_extraction_page_started(
  p_job_id uuid,
  p_pdf_page integer,
  p_worker_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.worker_request_is_valid(p_worker_id) then raise exception 'Invalid worker request' using errcode = '42501'; end if;
  update public.extraction_job_pages jp
  set status = 'processing', started_at = coalesce(started_at, now()), attempt_count = attempt_count + 1, updated_at = now()
  from public.extraction_jobs j
  where jp.job_id = p_job_id and jp.pdf_page = p_pdf_page and j.id = jp.job_id
    and j.status = 'processing' and j.claimed_by = p_worker_id
    and (j.lease_expires_at is null or j.lease_expires_at > now())
    and jp.status = 'queued';
  if not found then raise exception 'Page cannot be started by this worker' using errcode = '42501'; end if;
end;
$$;

create or replace function public.record_extraction_page_failure(
  p_job_id uuid,
  p_pdf_page integer,
  p_worker_id text,
  p_status public.extraction_job_page_status,
  p_error text,
  p_result_schema_version text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  job_row public.extraction_jobs%rowtype;
begin
  if not public.worker_request_is_valid(p_worker_id) or p_status not in ('failed', 'quota_exhausted') or nullif(btrim(p_error), '') is null then
    raise exception 'Invalid page failure request' using errcode = '42501';
  end if;
  select * into job_row from public.extraction_jobs where id = p_job_id for update;
  if not found or job_row.status <> 'processing' or job_row.claimed_by <> p_worker_id
     or job_row.lease_expires_at <= now() then
    raise exception 'Job is not owned by this worker' using errcode = '42501';
  end if;
  update public.extraction_job_pages
  set status = p_status, error = left(p_error, 4000), result_schema_version = p_result_schema_version,
      completed_at = now(), updated_at = now()
  where job_id = p_job_id and pdf_page = p_pdf_page and status in ('queued', 'processing');
  if not found then raise exception 'Page is not available for failure recording' using errcode = '55000'; end if;
  if p_status = 'quota_exhausted' then
    update public.extraction_jobs set status = 'quota_exhausted', updated_at = now() where id = p_job_id;
  end if;
end;
$$;

create or replace function public.record_extraction_page_result(
  p_job_id uuid,
  p_pdf_page integer,
  p_worker_id text,
  p_result jsonb,
  p_result_checksum text,
  p_result_schema_version text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  job_row public.extraction_jobs%rowtype;
  page_row public.extraction_job_pages%rowtype;
  question_value jsonb;
  asset_value jsonb;
  question_row_id uuid;
  question_number_value integer;
begin
  if not public.worker_request_is_valid(p_worker_id)
     or p_result_schema_version <> '1'
     or p_result_checksum !~ '^(sha256:)?[0-9a-fA-F]{64}$'
     or jsonb_typeof(p_result) <> 'object' then
    raise exception 'Invalid page result request' using errcode = '42501';
  end if;
  select * into job_row from public.extraction_jobs where id = p_job_id for update;
  if not found then raise exception 'Extraction job not found' using errcode = 'P0002'; end if;
  select * into page_row from public.extraction_job_pages where job_id = p_job_id and pdf_page = p_pdf_page for update;
  if not found then raise exception 'Requested page was not found' using errcode = 'P0002'; end if;
  if job_row.status <> 'processing' or job_row.claimed_by <> p_worker_id or job_row.lease_expires_at <= now() then
    raise exception 'Job is not owned by this worker' using errcode = '42501';
  end if;
  if p_result -> 'job' ->> 'job_id' <> p_job_id::text
     or p_result -> 'job' ->> 'project_id' <> job_row.project_id::text
     or p_result -> 'job' ->> 'source_document_id' <> job_row.source_document_id::text
     or (p_result ->> 'source_page')::integer <> p_pdf_page
     or p_result ->> 'status' <> 'completed' then
    raise exception 'Page result identity or status does not match job' using errcode = '22023';
  end if;
  if page_row.status = 'completed' then
    if page_row.result_checksum = lower(p_result_checksum) then return; end if;
    raise exception 'Page already has a different result' using errcode = '55000';
  end if;
  if page_row.status not in ('queued', 'processing') then raise exception 'Page cannot accept a result' using errcode = '55000'; end if;

  for question_value in select value from jsonb_array_elements(coalesce(p_result -> 'questions', '[]'::jsonb))
  loop
    question_number_value := (question_value ->> 'question_number')::integer;
    insert into public.extraction_questions (
      job_page_id, extraction_question_key, question_number, prompt, choices, source_region,
      uncertainties, ai_predicted_choice_index, ai_confidence, ai_reasoning, ai_answer_basis,
      verification_status, verification_findings
    ) values (
      page_row.id, question_value ->> 'id', question_number_value, question_value ->> 'prompt',
      question_value -> 'choices', question_value -> 'source_region', coalesce(question_value -> 'uncertainties', '[]'::jsonb),
      nullif(question_value -> 'ai_answer' ->> 'predicted_choice_index', '')::integer,
      question_value -> 'ai_answer' ->> 'confidence', question_value -> 'ai_answer' ->> 'reasoning',
      question_value -> 'ai_answer' ->> 'answer_basis', question_value -> 'verification' ->> 'status',
      coalesce(question_value -> 'verification' -> 'findings', '[]'::jsonb)
    ) on conflict (extraction_question_key) do update set
      prompt = excluded.prompt, choices = excluded.choices, source_region = excluded.source_region,
      uncertainties = excluded.uncertainties, ai_predicted_choice_index = excluded.ai_predicted_choice_index,
      ai_confidence = excluded.ai_confidence, ai_reasoning = excluded.ai_reasoning,
      ai_answer_basis = excluded.ai_answer_basis, verification_status = excluded.verification_status,
      verification_findings = excluded.verification_findings, updated_at = now()
    returning id into question_row_id;

    for asset_value in select value from jsonb_array_elements(coalesce(question_value -> 'visual_assets', '[]'::jsonb))
    loop
      insert into public.extraction_visual_assets (
        extraction_question_id, asset_key, asset_type, storage_path, source_region,
        confidence, uncertainties, sha256, pixel_width, pixel_height
      ) values (
        question_row_id, asset_value ->> 'id', asset_value ->> 'asset_type', asset_value ->> 'storage_path',
        asset_value -> 'source_region', asset_value ->> 'confidence', coalesce(asset_value -> 'uncertainties', '[]'::jsonb),
        asset_value ->> 'sha256', (asset_value ->> 'pixel_width')::integer, (asset_value ->> 'pixel_height')::integer
      ) on conflict (asset_key) do update set
        storage_path = excluded.storage_path, source_region = excluded.source_region,
        confidence = excluded.confidence, uncertainties = excluded.uncertainties,
        sha256 = excluded.sha256, pixel_width = excluded.pixel_width, pixel_height = excluded.pixel_height;
    end loop;
  end loop;

  update public.extraction_job_pages
  set status = 'completed', result_checksum = lower(p_result_checksum), result_schema_version = p_result_schema_version,
      error = null, completed_at = now(), updated_at = now()
  where id = page_row.id;
end;
$$;

create or replace function public.complete_extraction_job(
  p_job_id uuid,
  p_worker_id text
)
returns public.extraction_job_status
language plpgsql
security definer
set search_path = public
as $$
declare
  job_row public.extraction_jobs%rowtype;
  remaining_count integer;
  failed_count integer;
  quota_count integer;
  next_status public.extraction_job_status;
begin
  if not public.worker_request_is_valid(p_worker_id) then raise exception 'Invalid worker request' using errcode = '42501'; end if;
  select * into job_row from public.extraction_jobs where id = p_job_id for update;
  if not found or job_row.status not in ('processing', 'quota_exhausted') or job_row.claimed_by <> p_worker_id then
    raise exception 'Job is not owned by this worker' using errcode = '42501';
  end if;
  select count(*) filter (where status in ('queued', 'processing')), count(*) filter (where status = 'failed'), count(*) filter (where status = 'quota_exhausted')
    into remaining_count, failed_count, quota_count
  from public.extraction_job_pages where job_id = p_job_id;
  if remaining_count > 0 then raise exception 'All pages must reach a terminal state before completion' using errcode = '55000'; end if;
  next_status := case when quota_count > 0 then 'quota_exhausted'::public.extraction_job_status when failed_count > 0 then 'completed_with_errors'::public.extraction_job_status else 'completed'::public.extraction_job_status end;
  update public.extraction_jobs
  set status = next_status, completed_pages = (select count(*) from public.extraction_job_pages where job_id = p_job_id and status = 'completed'),
      failed_pages = (select count(*) from public.extraction_job_pages where job_id = p_job_id and status in ('failed', 'quota_exhausted')),
      completed_at = now(), lease_expires_at = null, updated_at = now()
  where id = p_job_id;
  insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
  values (job_row.created_by, 'extraction_job.completed', 'extraction_job', p_job_id, jsonb_build_object('status', next_status, 'worker_id', p_worker_id, 'actor_type', 'worker'));
  return next_status;
end;
$$;

revoke execute on function public.claim_extraction_job(uuid, text, integer) from public, anon, authenticated;
revoke execute on function public.renew_extraction_job_lease(uuid, text, integer) from public, anon, authenticated;
revoke execute on function public.record_extraction_page_started(uuid, integer, text) from public, anon, authenticated;
revoke execute on function public.record_extraction_page_failure(uuid, integer, text, public.extraction_job_page_status, text, text) from public, anon, authenticated;
revoke execute on function public.record_extraction_page_result(uuid, integer, text, jsonb, text, text) from public, anon, authenticated;
revoke execute on function public.complete_extraction_job(uuid, text) from public, anon, authenticated;
grant execute on function public.claim_extraction_job(uuid, text, integer) to service_role;
grant execute on function public.renew_extraction_job_lease(uuid, text, integer) to service_role;
grant execute on function public.record_extraction_page_started(uuid, integer, text) to service_role;
grant execute on function public.record_extraction_page_failure(uuid, integer, text, public.extraction_job_page_status, text, text) to service_role;
grant execute on function public.record_extraction_page_result(uuid, integer, text, jsonb, text, text) to service_role;
grant execute on function public.complete_extraction_job(uuid, text) to service_role;
