-- Published paper catalog for the student app's Past Papers download flow.
--
-- One row per published pack version. The ZIP itself is never stored in the
-- database — it lives in the private `published-papers` Storage bucket and is
-- referenced by storage_path.
--
-- Access model: students read the catalog through the Content Studio API
-- (service role), which issues short-lived signed download URLs. RLS keeps
-- direct table/storage access limited to admins (and the service role), so no
-- anon read policy is introduced.

create table public.published_papers (
  id uuid primary key default gen_random_uuid(),
  pack_id text not null,
  subject_slug text not null,
  subject_title text not null,
  stream text not null,
  year integer not null,
  title text not null,
  question_count integer not null,
  pack_version text not null,
  size_bytes bigint not null,
  storage_path text not null unique,
  published_at timestamptz not null default now(),
  minimum_app_version text not null,
  updated_at timestamptz not null default now(),
  constraint published_papers_stream_check
    check (stream in ('natural_science', 'social_science')),
  constraint published_papers_year_check
    check (year > 0),
  constraint published_papers_question_count_check
    check (question_count > 0),
  constraint published_papers_size_check
    check (size_bytes > 0),
  constraint published_papers_pack_id_check
    check (pack_id ~ '^[a-z0-9][a-z0-9_-]*$'),
  constraint published_papers_pack_version_check
    check (pack_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
  constraint published_papers_minimum_app_version_check
    check (minimum_app_version ~ '^[0-9]+\.[0-9]+\.[0-9]+$'),
  constraint published_papers_version_unique unique (pack_id, pack_version)
);

create index published_papers_stream_idx on public.published_papers (stream);
create index published_papers_subject_idx on public.published_papers (stream, subject_slug);
create index published_papers_year_idx on public.published_papers (year);
create index published_papers_pack_id_idx on public.published_papers (pack_id);

alter table public.published_papers enable row level security;

create policy "admins can read published papers"
  on public.published_papers for select to authenticated
  using (public.is_admin_or_owner());

create policy "admins can insert published papers"
  on public.published_papers for insert to authenticated
  with check (public.is_admin_or_owner());

create policy "admins can update published papers"
  on public.published_papers for update to authenticated
  using (public.is_admin_or_owner())
  with check (public.is_admin_or_owner());

create policy "admins can delete published papers"
  on public.published_papers for delete to authenticated
  using (public.is_admin_or_owner());

revoke all on public.published_papers from anon;
grant select, insert, update, delete on public.published_papers to authenticated;

-- Private bucket for published pack ZIPs. Student downloads go through
-- short-lived signed URLs minted by the API route below; nothing is public.
insert into storage.buckets (id, name, public)
  values ('published-papers', 'published-papers', false)
  on conflict (id) do nothing;

create policy "admins can upload published papers"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'published-papers' and public.is_admin_or_owner());

create policy "admins can update published papers"
  on storage.objects for update to authenticated
  using (bucket_id = 'published-papers' and public.is_admin_or_owner())
  with check (bucket_id = 'published-papers' and public.is_admin_or_owner());

create policy "admins can read published papers"
  on storage.objects for select to authenticated
  using (bucket_id = 'published-papers' and public.is_admin_or_owner());

create policy "admins can delete published papers"
  on storage.objects for delete to authenticated
  using (bucket_id = 'published-papers' and public.is_admin_or_owner());
