-- Allow a user to cancel a claimed job; the worker will observe the terminal
-- state on its next control-plane operation and preserve completed pages.

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
  if not found then raise exception 'Extraction job not found' using errcode = 'P0002'; end if;
  if not public.can_upload_source_document(job_row.project_id)
     or ((select auth.uid()) <> job_row.created_by and not public.is_admin_or_owner()) then
    raise exception 'You cannot cancel this extraction job' using errcode = '42501';
  end if;
  if job_row.status not in ('queued', 'processing') then
    raise exception 'Only queued or processing extraction jobs can be cancelled' using errcode = '55000';
  end if;

  update public.extraction_jobs
  set status = 'cancelled', completed_at = now(), lease_expires_at = null, updated_at = now()
  where id = p_job_id;
  update public.extraction_job_pages
  set status = 'cancelled', completed_at = now(), updated_at = now()
  where job_id = p_job_id and status in ('queued', 'processing');

  perform public.write_audit_event(
    'extraction_job.cancelled', 'extraction_job', p_job_id,
    jsonb_build_object('project_id', job_row.project_id, 'previous_status', job_row.status)
  );
end;
$$;
