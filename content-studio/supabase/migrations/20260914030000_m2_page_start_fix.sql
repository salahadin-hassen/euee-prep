-- Fix the page-start update's target/source column ambiguity.

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
  set status = 'processing', started_at = coalesce(jp.started_at, now()), attempt_count = jp.attempt_count + 1, updated_at = now()
  from public.extraction_jobs j
  where jp.job_id = p_job_id and jp.pdf_page = p_pdf_page and j.id = jp.job_id
    and j.status = 'processing' and j.claimed_by = p_worker_id
    and (j.lease_expires_at is null or j.lease_expires_at > now())
    and jp.status = 'queued';
  if not found then raise exception 'Page cannot be started by this worker' using errcode = '42501'; end if;
end;
$$;
