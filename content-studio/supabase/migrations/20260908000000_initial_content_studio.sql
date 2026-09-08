create extension if not exists "pgcrypto";

create type public.app_role as enum ('owner', 'admin', 'reviewer', 'uploader');
create type public.project_status as enum (
  'draft', 'processing', 'in_review', 'blocked',
  'ready_for_approval', 'approved', 'exported', 'archived'
);
create type public.member_role as enum ('admin', 'reviewer', 'uploader');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role public.app_role not null default 'uploader',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  exam_year integer not null check (exam_year > 0),
  subject text not null,
  stream text not null check (stream in ('natural_science', 'social_science')),
  status public.project_status not null default 'draft',
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.project_members (
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.member_role not null,
  assigned_at timestamptz not null default now(),
  primary key (project_id, user_id)
);

create table public.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid not null references auth.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index project_members_user_id_idx on public.project_members(user_id);
create index projects_created_by_idx on public.projects(created_by);
create index audit_events_created_at_idx on public.audit_events(created_at desc);

create or replace function public.is_admin_or_owner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role in ('owner', 'admin')
  );
$$;

create or replace function public.is_project_member(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin_or_owner()
    or exists (
      select 1 from public.project_members
      where project_id = target_project_id and user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.projects
      where id = target_project_id and created_by = (select auth.uid())
    );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', new.email));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.projects enable row level security;
alter table public.project_members enable row level security;
alter table public.audit_events enable row level security;

create policy "users can read their profile"
  on public.profiles for select to authenticated
  using (id = (select auth.uid()));

create policy "admins can read all profiles"
  on public.profiles for select to authenticated
  using (public.is_admin_or_owner());

create policy "admins can update profiles"
  on public.profiles for update to authenticated
  using (public.is_admin_or_owner())
  with check (public.is_admin_or_owner());

create policy "members can read assigned projects"
  on public.projects for select to authenticated
  using (public.is_project_member(id));

create policy "authenticated users can create draft projects"
  on public.projects for insert to authenticated
  with check (created_by = (select auth.uid()) and status = 'draft');

create policy "admins can update projects"
  on public.projects for update to authenticated
  using (public.is_admin_or_owner())
  with check (public.is_admin_or_owner());

create policy "admins can delete projects"
  on public.projects for delete to authenticated
  using (public.is_admin_or_owner());

create policy "admins can read all memberships"
  on public.project_members for select to authenticated
  using (public.is_admin_or_owner());

create policy "reviewers can read their own membership"
  on public.project_members for select to authenticated
  using (user_id = (select auth.uid()));

create policy "admins can manage memberships"
  on public.project_members for all to authenticated
  using (public.is_admin_or_owner())
  with check (public.is_admin_or_owner());

create policy "admins can read audit events"
  on public.audit_events for select to authenticated
  using (public.is_admin_or_owner());

create policy "admins can append audit events"
  on public.audit_events for insert to authenticated
  with check (public.is_admin_or_owner() and actor_id = (select auth.uid()));

revoke all on public.profiles, public.projects, public.project_members, public.audit_events from anon;
grant select on public.profiles, public.projects, public.project_members to authenticated;
grant insert on public.audit_events to authenticated;
grant update on public.profiles, public.projects to authenticated;
grant insert, update, delete on public.projects, public.project_members to authenticated;
