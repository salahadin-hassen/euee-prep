-- M2 worker follow-up: polling claim, progress counters, and private asset storage.

create or replace function public.claim_next_extraction_job(
  p_worker_id text,
  p_lease_seconds integer default 1800
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  candidate_id uuid;
begin
  if not public.worker_request_is_valid(p_worker_id)
     or p_lease_seconds is null or p_lease_seconds < 60 or p_lease_seconds > 1800 then
    raise exception 'Invalid worker claim request' using errcode = '42501';
  end if;
  select id into candidate_id
  from public.extraction_jobs
  where status = 'queued'
     or (status = 'processing' and lease_expires_at is not null and lease_expires_at <= now())
  order by created_at asc
  for update skip locked
  limit 1;
  if candidate_id is null then return null; end if;
  return public.claim_extraction_job(candidate_id, p_worker_id, p_lease_seconds);
end;
$$;

revoke execute on function public.claim_next_extraction_job(text, integer) from public, anon, authenticated;
grant execute on function public.claim_next_extraction_job(text, integer) to service_role;

create or replace function public.refresh_extraction_job_progress()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.extraction_jobs
  set completed_pages = (
        select count(*) from public.extraction_job_pages where job_id = coalesce(new.job_id, old.job_id) and status = 'completed'
      ),
      failed_pages = (
        select count(*) from public.extraction_job_pages where job_id = coalesce(new.job_id, old.job_id) and status in ('failed', 'quota_exhausted')
      ),
      updated_at = now()
  where id = coalesce(new.job_id, old.job_id);
  return coalesce(new, old);
end;
$$;

create trigger extraction_job_pages_refresh_progress
  after insert or update on public.extraction_job_pages
  for each row execute function public.refresh_extraction_job_progress();

create or replace function public.requeue_expired_extraction_pages()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.status = 'processing'
     and new.status = 'processing'
     and old.lease_expires_at is not null
     and old.lease_expires_at <= now() then
    update public.extraction_job_pages
    set status = 'queued', error = 'Requeued after worker lease expiration', updated_at = now()
    where job_id = new.id and status = 'processing';
  end if;
  return new;
end;
$$;

create trigger extraction_jobs_requeue_expired_pages
  before update on public.extraction_jobs
  for each row execute function public.requeue_expired_extraction_pages();

insert into storage.buckets (id, name, public)
values ('extraction-assets', 'extraction-assets', false)
on conflict (id) do nothing;

create or replace function public.can_access_extraction_asset(path text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select path ~ '^[0-9a-fA-F-]{36}/[A-Za-z0-9._:-]{1,160}\.png$'
    and exists (
      select 1 from public.extraction_jobs j
      where j.id = split_part(path, '/', 1)::uuid
        and public.is_project_member(j.project_id)
    );
$$;

revoke execute on function public.can_access_extraction_asset(text) from public, anon;
grant execute on function public.can_access_extraction_asset(text) to authenticated;

create policy "project members can read extraction assets"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'extraction-assets'
    and public.can_access_extraction_asset(name)
  );
