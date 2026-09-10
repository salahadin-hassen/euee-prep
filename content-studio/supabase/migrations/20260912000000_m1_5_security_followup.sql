-- M1.5 follow-up hardening.
-- This migration keeps the historical chain intact and tightens the RPC-only
-- mutation model before the security migration is applied to a hosted project.

grant select on public.audit_events to authenticated;

-- RLS and storage policies invoke these helpers, so they are authenticated-only
-- rather than public/anonymous functions. Mutation helpers remain RPC-only.
revoke execute on function public.is_admin_or_owner() from public, anon;
revoke execute on function public.is_project_member(uuid) from public, anon;
revoke execute on function public.current_project_role(uuid) from public, anon, authenticated;
revoke execute on function public.can_edit_question_content(uuid) from public, anon, authenticated;
revoke execute on function public.can_manage_question_image(uuid) from public, anon, authenticated;
revoke execute on function public.is_valid_question_image_path(uuid, uuid, text) from public, anon, authenticated;
revoke execute on function public.can_access_question_image(text, boolean) from public, anon;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_updated_at() from public, anon, authenticated;
grant execute on function public.is_admin_or_owner() to authenticated;
grant execute on function public.is_project_member(uuid) to authenticated;
grant execute on function public.can_access_question_image(text, boolean) to authenticated;

-- Explicitly remove every direct audit mutation path.
revoke insert, update, delete on public.audit_events from public, anon, authenticated;

create or replace function public.project_is_reviewable(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.projects
    where id = target_project_id
      and status in ('draft', 'in_review', 'blocked')
  );
$$;

revoke execute on function public.project_is_reviewable(uuid) from public, anon, authenticated;

create or replace function public.create_project(
  p_title text,
  p_exam_year integer,
  p_subject text,
  p_stream text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_project_id uuid;
begin
  if not public.is_admin_or_owner() then
    raise exception 'Only admins can create projects' using errcode = '42501';
  end if;
  if nullif(btrim(p_title), '') is null or nullif(btrim(p_subject), '') is null then
    raise exception 'Title and subject are required' using errcode = '22023';
  end if;
  if p_exam_year is null or p_exam_year <= 0 then
    raise exception 'Exam year must be positive' using errcode = '22023';
  end if;
  if p_stream not in ('natural_science', 'social_science') then
    raise exception 'Invalid stream' using errcode = '22023';
  end if;

  insert into public.projects (title, exam_year, subject, stream, status, created_by)
  values (btrim(p_title), p_exam_year, btrim(p_subject), p_stream, 'draft', (select auth.uid()))
  returning id into new_project_id;

  insert into public.project_members (project_id, user_id, role)
  values (new_project_id, (select auth.uid()), 'admin');

  perform public.write_audit_event(
    'project.created', 'project', new_project_id,
    jsonb_build_object('title', btrim(p_title), 'subject', btrim(p_subject), 'stream', p_stream)
  );
  return new_project_id;
end;
$$;

create or replace function public.assign_project_member(
  p_project_id uuid,
  p_user_id uuid,
  p_role public.member_role
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  project_status_value public.project_status;
begin
  if not public.is_admin_or_owner() then
    raise exception 'Only admins can assign members' using errcode = '42501';
  end if;
  select status into project_status_value from public.projects where id = p_project_id for update;
  if not found then raise exception 'Project not found' using errcode = '23503'; end if;
  if project_status_value in ('exported', 'archived') then
    raise exception 'This paper is no longer assignable' using errcode = '55000';
  end if;
  if p_role not in ('reviewer', 'uploader') then
    raise exception 'Only reviewer or uploader assignments are allowed' using errcode = '22023';
  end if;
  if not exists (select 1 from public.profiles where id = p_user_id) then
    raise exception 'User not found' using errcode = '23503';
  end if;

  insert into public.project_members (project_id, user_id, role)
  values (p_project_id, p_user_id, p_role);
  perform public.write_audit_event(
    'member.assigned', 'project', p_project_id,
    jsonb_build_object('assigned_user_id', p_user_id, 'role', p_role)
  );
end;
$$;

create or replace function public.create_question(
  p_project_id uuid,
  p_order_index integer,
  p_question_text text,
  p_choices jsonb,
  p_correct_answer text default '',
  p_explanation text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_question_id uuid;
  project_status_value public.project_status;
  normalized_answer text := coalesce(btrim(p_correct_answer), '');
begin
  if not public.is_admin_or_owner() then
    raise exception 'Only admins can create questions' using errcode = '42501';
  end if;
  select status into project_status_value from public.projects where id = p_project_id for update;
  if not found then raise exception 'Project not found' using errcode = '23503'; end if;
  if project_status_value not in ('draft', 'in_review', 'blocked') then
    raise exception 'Questions cannot be added in the current paper state' using errcode = '55000';
  end if;
  if p_order_index is null or p_order_index < 0 then
    raise exception 'Order index must be non-negative' using errcode = '22023';
  end if;
  if nullif(btrim(p_question_text), '') is null then
    raise exception 'Question text is required' using errcode = '22023';
  end if;
  if jsonb_typeof(p_choices) <> 'array' or jsonb_array_length(p_choices) <> 4
     or exists (
       select 1 from jsonb_array_elements(p_choices) choice
       where jsonb_typeof(choice) <> 'string' or nullif(btrim(choice #>> '{}'), '') is null
     ) then
    raise exception 'Questions require exactly four non-empty choices' using errcode = '22023';
  end if;
  if normalized_answer <> '' and not exists (
    select 1 from jsonb_array_elements_text(p_choices) choice where choice = normalized_answer
  ) then
    raise exception 'Correct answer must match one of the choices' using errcode = '22023';
  end if;

  insert into public.questions (
    project_id, order_index, question_text, choices, correct_answer, explanation
  ) values (
    p_project_id, p_order_index, btrim(p_question_text), p_choices,
    normalized_answer, coalesce(p_explanation, '')
  ) returning id into new_question_id;

  perform public.write_audit_event(
    'question.created', 'question', new_question_id,
    jsonb_build_object('project_id', p_project_id, 'order_index', p_order_index)
  );
  return new_question_id;
end;
$$;

create or replace function public.edit_question(
  p_question_id uuid,
  p_question_text text,
  p_choices jsonb,
  p_correct_answer text,
  p_explanation text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  question_row public.questions%rowtype;
  project_status_value public.project_status;
  normalized_answer text := coalesce(btrim(p_correct_answer), '');
begin
  select project_id into question_row.project_id from public.questions where id = p_question_id;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  select status into project_status_value from public.projects where id = question_row.project_id for update;
  if project_status_value not in ('draft', 'in_review', 'blocked') then
    raise exception 'Questions cannot be edited in the current paper state' using errcode = '55000';
  end if;
  select * into question_row from public.questions where id = p_question_id for update;
  if not public.can_edit_question_content(question_row.project_id) then
    raise exception 'You cannot edit this question' using errcode = '42501';
  end if;
  if question_row.status = 'verified' then
    raise exception 'Verified questions must be explicitly reopened before editing' using errcode = '55000';
  end if;
  if nullif(btrim(p_question_text), '') is null then
    raise exception 'Question text is required' using errcode = '22023';
  end if;
  if jsonb_typeof(p_choices) <> 'array' or jsonb_array_length(p_choices) <> 4
     or exists (
       select 1 from jsonb_array_elements(p_choices) choice
       where jsonb_typeof(choice) <> 'string' or nullif(btrim(choice #>> '{}'), '') is null
     ) then
    raise exception 'Questions require exactly four non-empty choices' using errcode = '22023';
  end if;
  if normalized_answer <> '' and not exists (
    select 1 from jsonb_array_elements_text(p_choices) choice where choice = normalized_answer
  ) then
    raise exception 'Correct answer must match one of the choices' using errcode = '22023';
  end if;

  update public.questions
  set question_text = btrim(p_question_text), choices = p_choices,
      correct_answer = normalized_answer, explanation = coalesce(p_explanation, ''), updated_at = now()
  where id = p_question_id;
  perform public.write_audit_event(
    'question.updated', 'question', p_question_id,
    jsonb_build_object('project_id', question_row.project_id, 'fields', jsonb_build_array('question_text', 'choices', 'correct_answer', 'explanation'))
  );
end;
$$;

create or replace function public.flag_question(p_question_id uuid, p_flag_note text default '')
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  question_row public.questions%rowtype;
  project_status_value public.project_status;
begin
  select project_id into question_row.project_id from public.questions where id = p_question_id;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  select status into project_status_value from public.projects where id = question_row.project_id for update;
  if project_status_value not in ('draft', 'in_review', 'blocked') then
    raise exception 'Questions cannot be flagged in the current paper state' using errcode = '55000';
  end if;
  select * into question_row from public.questions where id = p_question_id for update;
  if not public.can_edit_question_content(question_row.project_id) then
    raise exception 'You cannot flag this question' using errcode = '42501';
  end if;
  if question_row.status = 'verified' then
    raise exception 'Verified questions must be explicitly reopened before flagging' using errcode = '55000';
  end if;
  update public.questions
  set status = 'flagged', flag_note = left(coalesce(p_flag_note, ''), 2000), updated_at = now()
  where id = p_question_id;
  if project_status_value in ('draft', 'in_review') then
    update public.projects set status = 'blocked', updated_at = now() where id = question_row.project_id;
    perform public.write_audit_event(
      'project.status_changed', 'project', question_row.project_id,
      jsonb_build_object('from_status', project_status_value, 'to_status', 'blocked', 'reason', 'question flagged')
    );
  end if;
  perform public.write_audit_event(
    'question.flagged', 'question', p_question_id,
    jsonb_build_object('project_id', question_row.project_id, 'has_note', nullif(btrim(coalesce(p_flag_note, '')), '') is not null)
  );
end;
$$;

create or replace function public.verify_question(p_question_id uuid)
returns public.project_status
language plpgsql
security definer
set search_path = public
as $$
declare
  question_row public.questions%rowtype;
  project_status_value public.project_status;
  remaining_count integer;
begin
  select project_id into question_row.project_id from public.questions where id = p_question_id;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  select status into project_status_value from public.projects where id = question_row.project_id for update;
  if project_status_value not in ('draft', 'in_review', 'blocked') then
    raise exception 'Questions cannot be verified in the current paper state' using errcode = '55000';
  end if;
  select * into question_row from public.questions where id = p_question_id for update;
  if not public.can_edit_question_content(question_row.project_id) then
    raise exception 'You cannot verify this question' using errcode = '42501';
  end if;
  if question_row.status not in ('unverified', 'flagged') then
    raise exception 'Only unverified or flagged questions can be verified' using errcode = '55000';
  end if;

  update public.questions
  set status = 'verified', verified_by = (select auth.uid()), verified_at = now(), flag_note = null, updated_at = now()
  where id = p_question_id;
  select count(*) into remaining_count
  from public.questions
  where project_id = question_row.project_id and status <> 'verified';

  if remaining_count = 0 then
    update public.projects set status = 'ready_for_approval', updated_at = now() where id = question_row.project_id;
    perform public.write_audit_event(
      'project.status_changed', 'project', question_row.project_id,
      jsonb_build_object('from_status', project_status_value, 'to_status', 'ready_for_approval', 'reason', 'all questions verified')
    );
  elsif project_status_value in ('draft', 'blocked') then
    update public.projects set status = 'in_review', updated_at = now() where id = question_row.project_id;
    perform public.write_audit_event(
      'project.status_changed', 'project', question_row.project_id,
      jsonb_build_object('from_status', project_status_value, 'to_status', 'in_review', 'reason', 'review started')
    );
  end if;
  perform public.write_audit_event(
    'question.verified', 'question', p_question_id,
    jsonb_build_object('project_id', question_row.project_id, 'resolved_flag', question_row.status = 'flagged')
  );
  return case when remaining_count = 0 then 'ready_for_approval'::public.project_status else 'in_review'::public.project_status end;
end;
$$;

create or replace function public.reopen_question(p_question_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  question_row public.questions%rowtype;
  project_status_value public.project_status;
begin
  select project_id into question_row.project_id from public.questions where id = p_question_id;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  select status into project_status_value from public.projects where id = question_row.project_id for update;
  if not public.is_admin_or_owner() then raise exception 'Only admins can reopen questions' using errcode = '42501'; end if;
  if project_status_value <> 'approved' then
    raise exception 'Only approved papers can be explicitly reopened' using errcode = '55000';
  end if;
  select * into question_row from public.questions where id = p_question_id for update;
  if question_row.status <> 'verified' then raise exception 'Only verified questions can be reopened' using errcode = '55000'; end if;
  update public.questions
  set status = 'unverified', verified_by = null, verified_at = null, flag_note = null, updated_at = now()
  where id = p_question_id;
  update public.projects set status = 'in_review', updated_at = now() where id = question_row.project_id;
  perform public.write_audit_event(
    'question.reopened', 'question', p_question_id,
    jsonb_build_object('project_id', question_row.project_id, 'from_status', 'verified')
  );
  perform public.write_audit_event(
    'project.status_changed', 'project', question_row.project_id,
    jsonb_build_object('from_status', 'approved', 'to_status', 'in_review', 'reason', 'explicit question reopen')
  );
end;
$$;

create or replace function public.approve_project(p_project_id uuid)
returns void
language plpgsql
security definer
set search_path = public, storage
as $$
declare
  project_status_value public.project_status;
  question_count integer;
  invalid_count integer;
begin
  if not public.is_admin_or_owner() then raise exception 'Only admins can approve papers' using errcode = '42501'; end if;
  select status into project_status_value from public.projects where id = p_project_id for update;
  if not found then raise exception 'Project not found' using errcode = 'P0002'; end if;
  if project_status_value <> 'ready_for_approval' then raise exception 'Paper is not ready for approval' using errcode = '55000'; end if;
  perform 1 from public.questions where project_id = p_project_id for update;
  select count(*) into question_count from public.questions where project_id = p_project_id;
  if question_count = 0 then raise exception 'A paper must contain questions' using errcode = '55000'; end if;
  select count(*) into invalid_count
  from public.questions q
  where q.project_id = p_project_id
    and (
      q.status <> 'verified'
      or q.verified_by is null
      or q.verified_at is null
      or (q.image_path is not null and not public.is_valid_question_image_path(p_project_id, q.id, q.image_path))
    );
  if invalid_count > 0 then raise exception 'Every question and attached image must be verified and valid' using errcode = '55000'; end if;
  update public.projects set status = 'approved', updated_at = now() where id = p_project_id;
  perform public.write_audit_event('project.approved', 'project', p_project_id, jsonb_build_object('question_count', question_count));
end;
$$;

create or replace function public.export_project(p_project_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare current_status public.project_status;
begin
  if not public.is_admin_or_owner() then raise exception 'Only admins can export papers' using errcode = '42501'; end if;
  select status into current_status from public.projects where id = p_project_id for update;
  if not found then raise exception 'Project not found' using errcode = 'P0002'; end if;
  if current_status <> 'approved' then raise exception 'Only approved papers can be exported' using errcode = '55000'; end if;
  update public.projects set status = 'exported', updated_at = now() where id = p_project_id;
  perform public.write_audit_event('project.status_changed', 'project', p_project_id, jsonb_build_object('from_status', 'approved', 'to_status', 'exported'));
end;
$$;

create or replace function public.is_valid_question_image_path(p_project_id uuid, p_question_id uuid, p_path text)
returns boolean
language sql
stable
security definer
set search_path = public, storage
as $$
  select p_path is not null
    and p_path ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/[A-Za-z0-9._-]{1,128}$'
    and split_part(p_path, '/', 1)::uuid = p_project_id
    and split_part(p_path, '/', 2)::uuid = p_question_id
    and exists (select 1 from public.questions q where q.id = p_question_id and q.project_id = p_project_id)
    and exists (select 1 from storage.objects o where o.bucket_id = 'question-images' and o.name = p_path);
$$;

create or replace function public.can_access_question_image(p_path text, p_write boolean default false)
returns boolean
language sql
stable
security definer
set search_path = public, storage
as $$
  select p_path ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/[A-Za-z0-9._-]{1,128}$'
    and exists (
      select 1 from public.questions q
      where q.id = split_part(p_path, '/', 2)::uuid
        and q.project_id = split_part(p_path, '/', 1)::uuid
        and case when p_write then public.can_manage_question_image(q.project_id) else public.is_project_member(q.project_id) end
    );
$$;

create or replace function public.set_question_image_path(p_question_id uuid, p_project_id uuid, p_image_path text)
returns text
language plpgsql
security definer
set search_path = public, storage
as $$
declare old_path text; project_status_value public.project_status;
begin
  if not public.can_manage_question_image(p_project_id) then raise exception 'You cannot manage images for this paper' using errcode = '42501'; end if;
  select status into project_status_value from public.projects where id = p_project_id for update;
  if not found then raise exception 'Project not found' using errcode = 'P0002'; end if;
  if project_status_value not in ('draft', 'in_review', 'blocked') then raise exception 'Images cannot be changed in the current paper state' using errcode = '55000'; end if;
  select image_path into old_path from public.questions where id = p_question_id and project_id = p_project_id for update;
  if not found then raise exception 'Question does not belong to this paper' using errcode = '42501'; end if;
  if p_image_path is not null and not public.is_valid_question_image_path(p_project_id, p_question_id, p_image_path) then
    raise exception 'Image path does not belong to this question or object is missing' using errcode = '22023';
  end if;
  update public.questions set image_path = p_image_path, updated_at = now() where id = p_question_id and project_id = p_project_id;
  perform public.write_audit_event('question.image_changed', 'question', p_question_id, jsonb_build_object('project_id', p_project_id, 'attached', p_image_path is not null));
  return old_path;
end;
$$;

-- Authenticated clients may execute only the intended RPC surface.
revoke execute on function public.create_project(text, integer, text, text) from public, anon;
revoke execute on function public.assign_project_member(uuid, uuid, public.member_role) from public, anon;
revoke execute on function public.create_question(uuid, integer, text, jsonb, text, text) from public, anon;
revoke execute on function public.edit_question(uuid, text, jsonb, text, text) from public, anon;
revoke execute on function public.flag_question(uuid, text) from public, anon;
revoke execute on function public.verify_question(uuid) from public, anon;
revoke execute on function public.reopen_question(uuid) from public, anon;
revoke execute on function public.approve_project(uuid) from public, anon;
revoke execute on function public.export_project(uuid) from public, anon;
revoke execute on function public.set_question_image_path(uuid, uuid, text) from public, anon;
grant execute on function public.create_project(text, integer, text, text) to authenticated;
grant execute on function public.assign_project_member(uuid, uuid, public.member_role) to authenticated;
grant execute on function public.create_question(uuid, integer, text, jsonb, text, text) to authenticated;
grant execute on function public.edit_question(uuid, text, jsonb, text, text) to authenticated;
grant execute on function public.flag_question(uuid, text) to authenticated;
grant execute on function public.verify_question(uuid) to authenticated;
grant execute on function public.reopen_question(uuid) to authenticated;
grant execute on function public.approve_project(uuid) to authenticated;
grant execute on function public.export_project(uuid) to authenticated;
grant execute on function public.set_question_image_path(uuid, uuid, text) to authenticated;

alter table public.questions drop constraint if exists questions_correct_answer_is_choice;
alter table public.questions add constraint questions_correct_answer_is_choice check (
  correct_answer = '' or (jsonb_typeof(choices) = 'array' and choices @> jsonb_build_array(correct_answer))
);
alter table public.questions validate constraint questions_verification_consistency;

drop policy if exists "authorized users can update question images" on storage.objects;
drop policy if exists "authorized users can delete question images" on storage.objects;

-- Objects can be uploaded before attachment, but attached objects cannot be
-- directly renamed or deleted. The RPC detaches first, then the caller cleans
-- up the now-unreferenced old object.
create policy "authorized users can delete unreferenced question images"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'question-images'
    and public.can_access_question_image(name, true)
    and not exists (select 1 from public.questions q where q.image_path = name)
  );
