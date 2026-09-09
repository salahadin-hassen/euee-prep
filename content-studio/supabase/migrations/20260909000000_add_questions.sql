create type public.question_status as enum ('unverified', 'verified', 'flagged');

create table public.questions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  order_index int not null,
  question_text text not null,
  choices jsonb not null default '[]'::jsonb,
  correct_answer text not null default '',
  explanation text not null default '',
  status public.question_status not null default 'unverified',
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  flag_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index questions_project_id_idx on public.questions(project_id);
create index questions_status_idx on public.questions(project_id, status);

alter table public.questions enable row level security;

create policy "project members can read questions"
  on public.questions for select to authenticated
  using (
    exists (
      select 1 from public.projects
      where id = project_id and public.is_project_member(id)
    )
  );

create policy "project members can update questions"
  on public.questions for update to authenticated
  using (
    exists (
      select 1 from public.projects
      where id = project_id and public.is_project_member(id)
    )
  )
  with check (
    exists (
      select 1 from public.projects
      where id = project_id and public.is_project_member(id)
    )
  );

create policy "admins can insert questions"
  on public.questions for insert to authenticated
  with check (
    exists (
      select 1 from public.projects
      where id = project_id and public.is_admin_or_owner()
    )
  );

grant select, update on public.questions to authenticated;
grant insert on public.questions to authenticated;
