-- Fix the claim update's PL/pgSQL variable/column ambiguity.

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
  new_lease timestamptz;
begin
  if not public.worker_request_is_valid(p_worker_id)
     or p_lease_seconds is null or p_lease_seconds < 60 or p_lease_seconds > 1800 then
    raise exception 'Invalid worker claim request' using errcode = '42501';
  end if;

  select * into job_row from public.extraction_jobs where id = p_job_id for update;
  if not found then raise exception 'Extraction job not found' using errcode = 'P0002'; end if;
  if job_row.status = 'cancelled' then raise exception 'Cancelled jobs cannot be claimed' using errcode = '55000'; end if;
  if job_row.status in ('completed', 'completed_with_errors', 'quota_exhausted') then raise exception 'Terminal jobs cannot be claimed' using errcode = '55000'; end if;
  if job_row.status = 'processing' and job_row.lease_expires_at is not null and job_row.lease_expires_at > now() then
    raise exception 'Job is already claimed' using errcode = '55000';
  end if;

  effective_attempt := job_row.worker_attempt_count + 1;
  new_lease := now() + make_interval(secs => p_lease_seconds);
  update public.extraction_jobs ej
  set status = 'processing', claimed_by = p_worker_id, claimed_at = now(), lease_expires_at = new_lease,
      worker_attempt_count = effective_attempt, started_at = coalesce(ej.started_at, now()), updated_at = now()
  where ej.id = p_job_id;

  select * into source_row from public.source_documents where id = job_row.source_document_id;
  insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
  values (
    job_row.created_by, 'extraction_job.claimed', 'extraction_job', job_row.id,
    jsonb_build_object('project_id', job_row.project_id, 'worker_id', p_worker_id, 'attempt', effective_attempt, 'actor_type', 'worker')
  );
  return jsonb_build_object(
    'job_id', job_row.id, 'project_id', job_row.project_id, 'source_document_id', job_row.source_document_id,
    'storage_path', source_row.storage_path, 'requested_pages', job_row.requested_pages,
    'worker_attempt_count', effective_attempt, 'lease_expires_at', new_lease
  );
end;
$$;
