-- Notifications: lightweight event feed for extraction job lifecycle.
-- Each notification is scoped to a project member; only they can read/delete it.

create type public.notification_kind as enum (
  'extraction_started',
  'extraction_completed',
  'extraction_failed',
  'extraction_issues'
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  job_id uuid references public.extraction_jobs(id) on delete set null,
  kind public.notification_kind not null,
  title text not null check (char_length(title) between 1 and 200),
  body text,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index notifications_user_id_idx on public.notifications(user_id, created_at desc);
create index notifications_unread_idx on public.notifications(user_id, read) where not read;

alter table public.notifications enable row level security;

create policy "users can read their own notifications"
  on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));

create policy "users can delete their own notifications"
  on public.notifications for delete to authenticated
  using (user_id = (select auth.uid()));

-- Server-side insert only (via security definer RPC); no client insert policy.

grant select, delete on public.notifications to authenticated;

create or replace function public.create_notification(
  p_user_id uuid,
  p_project_id uuid,
  p_job_id uuid,
  p_kind public.notification_kind,
  p_title text,
  p_body text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
begin
  insert into public.notifications (user_id, project_id, job_id, kind, title, body)
  values (p_user_id, p_project_id, p_job_id, p_kind, left(btrim(p_title), 200), nullif(btrim(p_body), ''))
  returning id into new_id;
  return new_id;
end;
$$;

create or replace function public.mark_notifications_read(p_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  updated integer;
begin
  update public.notifications
  set read = true
  where id = any(p_ids)
    and user_id = (select auth.uid())
    and not read;
  get diagnostics updated = row_count;
  return updated;
end;
$$;

revoke execute on function public.create_notification(uuid, uuid, uuid, public.notification_kind, text, text) from public, anon;
revoke execute on function public.mark_notifications_read(uuid[]) from public, anon;
grant execute on function public.create_notification(uuid, uuid, uuid, public.notification_kind, text, text) to authenticated;
grant execute on function public.mark_notifications_read(uuid[]) to authenticated;
