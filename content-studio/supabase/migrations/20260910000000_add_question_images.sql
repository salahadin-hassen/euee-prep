-- Add nullable image_path to store a storage-bucket path (not a public URL).
alter table public.questions
  add column image_path text;

-- Create a private bucket for question images.
insert into storage.buckets (id, name, public)
  values ('question-images', 'question-images', false)
  on conflict (id) do nothing;

-- Storage RLS policies using the existing is_project_member() function.
-- The image path format is: {project_id}/{question_id}/{filename}
-- storage.foldername(name) returns the path segments as a text array.

create policy "project members can upload question images"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'question-images'
    and public.is_project_member(
      (storage.foldername(name))[1]::uuid
    )
  );

create policy "project members can read question images"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'question-images'
    and public.is_project_member(
      (storage.foldername(name))[1]::uuid
    )
  );

create policy "project members can update question images"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'question-images'
    and public.is_project_member(
      (storage.foldername(name))[1]::uuid
    )
  )
  with check (
    bucket_id = 'question-images'
    and public.is_project_member(
      (storage.foldername(name))[1]::uuid
    )
  );

create policy "project members can delete question images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'question-images'
    and public.is_project_member(
      (storage.foldername(name))[1]::uuid
    )
  );
