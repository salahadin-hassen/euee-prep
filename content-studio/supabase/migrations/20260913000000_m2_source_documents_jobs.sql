-- M2 Slice 1: private source PDFs and queued extraction jobs.
-- Mutations remain RPC-only; authenticated clients receive read access only.

create type public.extraction_job_status as enum (
  'queued', 'processing', 'completed', 'completed_with_errors',
  'quota_exhausted', 'failed', 'cancelled'
);

create type public.extraction_job_page_status as enum (
  'queued', 'processing', 'completed', 'failed', 'quota_exhausted', 'cancelled'
);

create table public.source_documents (
  id uuid primary key,
  project_id uuid not null references public.projects(id) on delete cascade,
  storage_path text not null unique,
  original_filename text not null check (char_length(original_filename) between 1 and 255),
  mime_type text not null check (mime_type = 'application/pdf'),
  byte_size bigint not null check (byte_size > 0 and byte_size <= 52428800),
  sha256 text not null check (sha256 ~ '^[0-9a-fA-F]{64}$'),
  uploaded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  constraint source_documents_path_shape check (
    storage_path ~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[A-Za-z0-9._-]{1,128}\.pdf$'
  ),
  constraint source_documents_path_project check (
    split_part(storage_path, '/', 1)::uuid = project_id
  ),
  constraint source_documents_path_document check (
    split_part(storage_path, '/', 2)::uuid = id
  ),
  unique (id, project_id)
);

create index source_documents_project_id_idx on public.source_documents(project_id);
create index source_documents_uploaded_by_idx on public.source_documents(uploaded_by);

create table public.extraction_jobs (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  source_document_id uuid not null references public.source_documents(id),
  created_by uuid not null references auth.users(id),
  requested_pages jsonb not null check (jsonb_typeof(requested_pages) = 'array'),
  status public.extraction_job_status not null default 'queued',
  total_pages integer not null check (total_pages > 0),
  completed_pages integer not null default 0 check (completed_pages >= 0),
  failed_pages integer not null default 0 check (failed_pages >= 0),
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (id, project_id),
  constraint extraction_jobs_document_project foreign key (source_document_id, project_id)
    references public.source_documents(id, project_id),
  constraint extraction_jobs_progress_bounds check (
    completed_pages + failed_pages <= total_pages
  )
);

create index extraction_jobs_project_id_idx on public.extraction_jobs(project_id, created_at desc);
create index extraction_jobs_document_id_idx on public.extraction_jobs(source_document_id);
create index extraction_jobs_status_idx on public.extraction_jobs(status);

create table public.extraction_job_pages (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.extraction_jobs(id) on delete cascade,
  pdf_page integer not null check (pdf_page > 0),
  status public.extraction_job_page_status not null default 'queued',
  attempt_count integer not null default 0 check (attempt_count >= 0),
  error text,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (job_id, pdf_page)
);

create index extraction_job_pages_job_id_idx on public.extraction_job_pages(job_id, pdf_page);
create index extraction_job_pages_status_idx on public.extraction_job_pages(status);

alter table public.source_documents enable row level security;
alter table public.extraction_jobs enable row level security;
alter table public.extraction_job_pages enable row level security;

create policy "project members can read source documents"
  on public.source_documents for select to authenticated
  using (public.is_project_member(project_id));

create policy "project members can read extraction jobs"
  on public.extraction_jobs for select to authenticated
  using (public.is_project_member(project_id));

create policy "project members can read extraction job pages"
  on public.extraction_job_pages for select to authenticated
  using (
    exists (
      select 1 from public.extraction_jobs j
      where j.id = job_id and public.is_project_member(j.project_id)
    )
  );

grant select on public.source_documents, public.extraction_jobs, public.extraction_job_pages to authenticated;

create or replace function public.can_upload_source_document(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
      select 1 from public.projects
      where id = target_project_id
        and status in ('draft', 'in_review', 'blocked')
    )
    and (
      public.is_admin_or_owner()
      or exists (
      select 1
      from public.project_members pm
      where pm.project_id = target_project_id
        and pm.user_id = (select auth.uid())
        and pm.role = 'uploader'
      )
    );
$$;

create or replace function public.can_access_source_pdf(path text, write_access boolean default false)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select path ~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[A-Za-z0-9._-]{1,128}\.pdf$'
    and case
      when write_access then public.can_upload_source_document(split_part(path, '/', 1)::uuid)
      else public.is_project_member(split_part(path, '/', 1)::uuid)
    end;
$$;

revoke execute on function public.can_upload_source_document(uuid) from public, anon, authenticated;
revoke execute on function public.can_access_source_pdf(text, boolean) from public, anon;
grant execute on function public.can_access_source_pdf(text, boolean) to authenticated;

insert into storage.buckets (id, name, public)
values ('source-pdfs', 'source-pdfs', false)
on conflict (id) do nothing;

create policy "authorized users can upload source PDFs"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'source-pdfs'
    and public.can_access_source_pdf(name, true)
  );

create policy "project members can read source PDFs"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'source-pdfs'
    and public.can_access_source_pdf(name, false)
  );

-- Source objects are immutable in this slice. Cleanup requires a later, explicit
-- garbage-collection path rather than allowing direct authenticated deletion.

create or replace function public.create_source_document(
  p_project_id uuid,
  p_document_id uuid,
  p_storage_path text,
  p_original_filename text,
  p_mime_type text,
  p_byte_size bigint,
  p_sha256 text
)
returns uuid
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  object_mime text;
  object_size bigint;
begin
  if not public.can_upload_source_document(p_project_id) then
    raise exception 'You cannot upload source documents for this paper' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.projects
    where id = p_project_id and status in ('draft', 'in_review', 'blocked')
  ) then
    raise exception 'This paper is not accepting source documents' using errcode = '55000';
  end if;
  if p_document_id is null then
    raise exception 'Document identity is required' using errcode = '22023';
  end if;
  if p_storage_path is null
     or p_storage_path !~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[A-Za-z0-9._-]{1,128}\.pdf$'
     or split_part(p_storage_path, '/', 1)::uuid <> p_project_id
     or split_part(p_storage_path, '/', 2)::uuid <> p_document_id then
    raise exception 'Storage path does not belong to this project and document' using errcode = '22023';
  end if;
  if nullif(btrim(p_original_filename), '') is null
     or length(p_original_filename) > 255
     or lower(p_original_filename) not like '%.pdf' then
    raise exception 'A PDF filename is required' using errcode = '22023';
  end if;
  if p_mime_type <> 'application/pdf' then
    raise exception 'Only PDF documents are allowed' using errcode = '22023';
  end if;
  if p_byte_size is null or p_byte_size <= 0 or p_byte_size > 52428800 then
    raise exception 'PDF must be between 1 byte and 50 MB' using errcode = '22023';
  end if;
  if p_sha256 is null or p_sha256 !~ '^[0-9a-fA-F]{64}$' then
    raise exception 'A SHA-256 checksum is required' using errcode = '22023';
  end if;

  select o.metadata ->> 'mimetype', nullif(o.metadata ->> 'size', '')::bigint
    into object_mime, object_size
  from storage.objects o
  where o.bucket_id = 'source-pdfs' and o.name = p_storage_path;
  if not found then
    raise exception 'Uploaded PDF was not found' using errcode = 'P0002';
  end if;
  if object_mime is distinct from 'application/pdf' then
    raise exception 'Stored object is not a PDF' using errcode = '22023';
  end if;
  if object_size is distinct from p_byte_size then
    raise exception 'Stored object size does not match registration' using errcode = '22023';
  end if;

  insert into public.source_documents (
    id, project_id, storage_path, original_filename, mime_type,
    byte_size, sha256, uploaded_by
  ) values (
    p_document_id, p_project_id, p_storage_path, left(btrim(p_original_filename), 255),
    p_mime_type, p_byte_size, lower(p_sha256), (select auth.uid())
  );

  perform public.write_audit_event(
    'source_document.created', 'source_document', p_document_id,
    jsonb_build_object(
      'project_id', p_project_id,
      'original_filename', left(btrim(p_original_filename), 255),
      'byte_size', p_byte_size,
      'sha256', lower(p_sha256)
    )
  );
  return p_document_id;
end;
$$;

create or replace function public.create_extraction_job(
  p_project_id uuid,
  p_source_document_id uuid,
  p_requested_pages jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_job_id uuid;
  page_value jsonb;
  page_number integer;
  normalized_pages integer[] := '{}';
begin
  if not public.can_upload_source_document(p_project_id) then
    raise exception 'You cannot create extraction jobs for this paper' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.projects
    where id = p_project_id and status in ('draft', 'in_review', 'blocked')
  ) then
    raise exception 'This paper is not accepting extraction jobs' using errcode = '55000';
  end if;
  if not exists (
    select 1 from public.source_documents
    where id = p_source_document_id and project_id = p_project_id
  ) then
    raise exception 'Source document does not belong to this paper' using errcode = '42501';
  end if;
  if jsonb_typeof(p_requested_pages) <> 'array'
     or jsonb_array_length(p_requested_pages) = 0
     or jsonb_array_length(p_requested_pages) > 500 then
    raise exception 'Select between 1 and 500 pages' using errcode = '22023';
  end if;

  for page_value in select value from jsonb_array_elements(p_requested_pages)
  loop
    if jsonb_typeof(page_value) <> 'number'
       or page_value::text !~ '^[0-9]+$' then
      raise exception 'Requested pages must be positive integers' using errcode = '22023';
    end if;
    page_number := page_value::text::integer;
    if page_number <= 0 then
      raise exception 'Requested pages must be positive integers' using errcode = '22023';
    end if;
    if page_number = any(normalized_pages) then
      raise exception 'Requested pages must not contain duplicates' using errcode = '22023';
    end if;
    normalized_pages := array_append(normalized_pages, page_number);
  end loop;

  insert into public.extraction_jobs (
    project_id, source_document_id, created_by, requested_pages, total_pages
  ) values (
    p_project_id, p_source_document_id, (select auth.uid()),
    to_jsonb(normalized_pages), cardinality(normalized_pages)
  ) returning id into new_job_id;

  insert into public.extraction_job_pages (job_id, pdf_page)
  select new_job_id, page_number from unnest(normalized_pages) as page_number;

  perform public.write_audit_event(
    'extraction_job.created', 'extraction_job', new_job_id,
    jsonb_build_object(
      'project_id', p_project_id,
      'source_document_id', p_source_document_id,
      'requested_pages', to_jsonb(normalized_pages)
    )
  );
  return new_job_id;
end;
$$;

create or replace function public.cancel_extraction_job(p_job_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  job_row public.extraction_jobs%rowtype;
begin
  select * into job_row from public.extraction_jobs where id = p_job_id for update;
  if not found then
    raise exception 'Extraction job not found' using errcode = 'P0002';
  end if;
  if not public.can_upload_source_document(job_row.project_id)
     or ((select auth.uid()) <> job_row.created_by and not public.is_admin_or_owner()) then
    raise exception 'You cannot cancel this extraction job' using errcode = '42501';
  end if;
  if job_row.status <> 'queued' then
    raise exception 'Only queued extraction jobs can be cancelled' using errcode = '55000';
  end if;

  update public.extraction_jobs
  set status = 'cancelled', completed_at = now(), updated_at = now()
  where id = p_job_id;
  update public.extraction_job_pages
  set status = 'cancelled', completed_at = now(), updated_at = now()
  where job_id = p_job_id and status = 'queued';

  perform public.write_audit_event(
    'extraction_job.cancelled', 'extraction_job', p_job_id,
    jsonb_build_object('project_id', job_row.project_id)
  );
end;
$$;

create trigger extraction_jobs_set_updated_at
  before update on public.extraction_jobs
  for each row execute function public.set_updated_at();

create trigger extraction_job_pages_set_updated_at
  before update on public.extraction_job_pages
  for each row execute function public.set_updated_at();

revoke execute on function public.create_source_document(uuid, uuid, text, text, text, bigint, text) from public, anon;
revoke execute on function public.create_extraction_job(uuid, uuid, jsonb) from public, anon;
revoke execute on function public.cancel_extraction_job(uuid) from public, anon;
grant execute on function public.create_source_document(uuid, uuid, text, text, text, bigint, text) to authenticated;
grant execute on function public.create_extraction_job(uuid, uuid, jsonb) to authenticated;
grant execute on function public.cancel_extraction_job(uuid) to authenticated;
