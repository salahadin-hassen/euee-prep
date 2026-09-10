-- Fix the page-row insert alias without rewriting the already-applied M2 migration.

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
  select new_job_id, page_item
  from unnest(normalized_pages) as page_item;

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
