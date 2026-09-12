-- Final review workflow: preserve extraction evidence and scope reviewer work.

alter type public.notification_kind add value if not exists 'review_assigned';
alter type public.notification_kind add value if not exists 'review_ready';

create type public.review_assignment_status as enum ('assigned', 'in_progress', 'completed');

alter table public.questions
  add column if not exists extraction_question_id uuid references public.extraction_questions(id),
  add column if not exists source_document_id uuid references public.source_documents(id),
  add column if not exists source_pdf_page integer,
  add column if not exists source_region jsonb,
  add column if not exists ai_predicted_choice_index integer,
  add column if not exists ai_confidence text,
  add column if not exists ai_reasoning text,
  add column if not exists ai_answer_basis text,
  add column if not exists official_answer text,
  add column if not exists explanation_draft text,
  add column if not exists explanation_verified_by uuid references public.profiles(id),
  add column if not exists explanation_verified_at timestamptz;

create index if not exists questions_extraction_question_idx
  on public.questions(extraction_question_id);

create table public.review_assignments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  reviewer_id uuid not null references auth.users(id) on delete cascade,
  start_order_index integer,
  end_order_index integer,
  assigned_by uuid not null references auth.users(id),
  assigned_at timestamptz not null default now(),
  status public.review_assignment_status not null default 'assigned',
  completed_at timestamptz,
  constraint review_assignments_range_check check (
    (start_order_index is null and end_order_index is null)
    or (start_order_index is not null and end_order_index is not null
      and start_order_index >= 0 and end_order_index >= start_order_index)
  )
);

create index review_assignments_reviewer_idx
  on public.review_assignments(reviewer_id, status);
create index review_assignments_project_idx
  on public.review_assignments(project_id, status);

alter table public.notifications
  add column if not exists assignment_id uuid references public.review_assignments(id) on delete set null;

create or replace function public.create_notification(
  p_user_id uuid,
  p_project_id uuid,
  p_job_id uuid,
  p_kind public.notification_kind,
  p_title text,
  p_body text,
  p_assignment_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare new_id uuid;
begin
  insert into public.notifications(user_id, project_id, job_id, assignment_id, kind, title, body)
  values (p_user_id, p_project_id, p_job_id, p_assignment_id, p_kind, left(btrim(p_title), 200), nullif(btrim(p_body), ''))
  returning id into new_id;
  return new_id;
end;
$$;

revoke execute on function public.create_notification(uuid, uuid, uuid, public.notification_kind, text, text, uuid) from public, anon;
grant execute on function public.create_notification(uuid, uuid, uuid, public.notification_kind, text, text, uuid) to authenticated, service_role;

alter table public.review_assignments enable row level security;

create policy "admins can read review assignments"
  on public.review_assignments for select to authenticated
  using (public.is_admin_or_owner());

create policy "reviewers can read their assignments"
  on public.review_assignments for select to authenticated
  using (reviewer_id = (select auth.uid()));

grant select on public.review_assignments to authenticated;

create or replace function public.can_review_question(p_question_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin_or_owner()
    or exists (
      select 1
      from public.questions q
      join public.review_assignments ra on ra.project_id = q.project_id
      where q.id = p_question_id
        and ra.reviewer_id = (select auth.uid())
        and ra.status in ('assigned', 'in_progress', 'completed')
        and (ra.start_order_index is null or q.order_index >= ra.start_order_index)
        and (ra.end_order_index is null or q.order_index <= ra.end_order_index)
    );
$$;

create or replace function public.can_edit_question_content(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin_or_owner()
    or exists (
      select 1
      from public.questions q
      where q.project_id = target_project_id
        and public.can_review_question(q.id)
    );
$$;

create or replace function public.can_edit_question(target_question_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin_or_owner() or public.can_review_question(target_question_id);
$$;

create or replace function public.can_manage_question_image(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin_or_owner()
    or exists (
      select 1
      from public.questions q
      where q.project_id = target_project_id
        and public.can_review_question(q.id)
    );
$$;

create or replace function public.can_access_question_image(p_path text, p_write boolean default false)
returns boolean
language sql
stable
security definer
set search_path = public, storage
as $$
  select p_path ~ '^[0-9a-fA-F-]{36}/[0-9a-fA-F-]{36}/[^/]+$'
    and exists (
      select 1 from public.questions q
      where q.id = split_part(p_path, '/', 2)::uuid
        and q.project_id = split_part(p_path, '/', 1)::uuid
        and case when p_write then public.can_edit_question(q.id) else public.is_admin_or_owner() or public.can_review_question(q.id) end
    );
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
declare question_row public.questions%rowtype;
begin
  select * into question_row from public.questions where id = p_question_id for update;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  if not public.can_edit_question(p_question_id) then raise exception 'You cannot edit this question' using errcode = '42501'; end if;
  if question_row.status = 'verified' then raise exception 'Verified questions must be explicitly reopened before editing' using errcode = '55000'; end if;
  if nullif(btrim(p_question_text), '') is null then raise exception 'Question text is required' using errcode = '22023'; end if;
  if jsonb_typeof(p_choices) <> 'array' or jsonb_array_length(p_choices) <> 4
     or exists (select 1 from jsonb_array_elements(p_choices) choice where jsonb_typeof(choice) <> 'string' or nullif(btrim(choice #>> '{}'), '') is null) then
    raise exception 'Questions require exactly four non-empty choices' using errcode = '22023';
  end if;
  if nullif(btrim(coalesce(p_correct_answer, '')), '') is not null
     and not (p_choices @> jsonb_build_array(btrim(p_correct_answer))) then
    raise exception 'Correct answer must match one of the choices' using errcode = '22023';
  end if;
  update public.questions
  set question_text = btrim(p_question_text), choices = p_choices,
      correct_answer = coalesce(btrim(p_correct_answer), ''),
      explanation_draft = coalesce(nullif(btrim(p_explanation), ''), explanation_draft), updated_at = now()
  where id = p_question_id;
  perform public.write_audit_event('question.updated', 'question', p_question_id,
    jsonb_build_object('project_id', question_row.project_id, 'fields', jsonb_build_array('question_text', 'choices', 'correct_answer', 'explanation')));
end;
$$;

create or replace function public.flag_question(p_question_id uuid, p_flag_note text default '')
returns void
language plpgsql
security definer
set search_path = public
as $$
declare question_row public.questions%rowtype;
begin
  select * into question_row from public.questions where id = p_question_id for update;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  if not public.can_edit_question(p_question_id) then raise exception 'You cannot flag this question' using errcode = '42501'; end if;
  if question_row.status = 'verified' then raise exception 'Verified questions must be explicitly reopened before flagging' using errcode = '55000'; end if;
  update public.questions set status = 'flagged', flag_note = left(coalesce(p_flag_note, ''), 2000), updated_at = now()
  where id = p_question_id;
  perform public.write_audit_event('question.flagged', 'question', p_question_id,
    jsonb_build_object('project_id', question_row.project_id, 'has_note', nullif(btrim(coalesce(p_flag_note, '')), '') is not null));
end;
$$;

drop policy if exists "project members can read questions" on public.questions;
create policy "authorized reviewers can read questions"
  on public.questions for select to authenticated
  using (
    public.is_admin_or_owner()
    or public.can_review_question(id)
  );

drop policy if exists "project members can read extraction visual assets" on public.extraction_visual_assets;
create policy "assigned reviewers can read extraction visual assets"
  on public.extraction_visual_assets for select to authenticated
  using (
    public.is_admin_or_owner()
    or exists (
      select 1
      from public.extraction_questions eq
      where eq.id = extraction_question_id
        and eq.imported_question_id is not null
        and public.can_review_question(eq.imported_question_id)
    )
  );

create or replace function public.can_access_extraction_asset(path text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select path ~ '^[0-9a-fA-F-]{36}/[A-Za-z0-9._:-]{1,160}\.png$'
    and exists (
      select 1
      from public.extraction_visual_assets eva
      join public.extraction_questions eq on eq.id = eva.extraction_question_id
      join public.extraction_job_pages jp on jp.id = eq.job_page_id
      join public.extraction_jobs ej on ej.id = jp.job_id
      where ej.id = split_part(path, '/', 1)::uuid
        and eva.asset_key = regexp_replace(split_part(path, '/', 2), '\.png$', '')
        and eq.imported_question_id is not null
        and public.can_review_question(eq.imported_question_id)
    );
$$;

create or replace function public.assign_reviewer(
  p_project_id uuid,
  p_reviewer_id uuid,
  p_start_order_index integer default null,
  p_end_order_index integer default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  assignment_id uuid;
  project_title text;
  start_label integer;
  end_label integer;
begin
  if not public.is_admin_or_owner() then
    raise exception 'Only admins can assign reviewers' using errcode = '42501';
  end if;
  if not exists (select 1 from public.projects where id = p_project_id) then
    raise exception 'Paper not found' using errcode = '23503';
  end if;
  if not exists (select 1 from public.profiles where id = p_reviewer_id and role = 'reviewer') then
    raise exception 'Reviewer not found' using errcode = '23503';
  end if;
  if (p_start_order_index is null) <> (p_end_order_index is null)
     or (p_start_order_index is not null and (p_start_order_index < 0 or p_end_order_index < p_start_order_index)) then
    raise exception 'Reviewer range is invalid' using errcode = '22023';
  end if;

  insert into public.project_members(project_id, user_id, role)
  values (p_project_id, p_reviewer_id, 'reviewer')
  on conflict (project_id, user_id) do update set role = 'reviewer';

  select id into assignment_id
  from public.review_assignments
  where project_id = p_project_id
    and reviewer_id = p_reviewer_id
    and start_order_index is not distinct from p_start_order_index
    and end_order_index is not distinct from p_end_order_index
    and status <> 'completed'
  order by assigned_at desc
  limit 1;

  if assignment_id is null then
    insert into public.review_assignments(project_id, reviewer_id, start_order_index, end_order_index, assigned_by)
    values (p_project_id, p_reviewer_id, p_start_order_index, p_end_order_index, (select auth.uid()))
    returning id into assignment_id;

    perform public.write_audit_event(
      'review_assignment.created', 'review_assignment', assignment_id,
      jsonb_build_object('project_id', p_project_id, 'reviewer_id', p_reviewer_id,
        'start_order_index', p_start_order_index, 'end_order_index', p_end_order_index)
    );
  end if;

  select title into project_title from public.projects where id = p_project_id;
  start_label := case when p_start_order_index is null then null else p_start_order_index + 1 end;
  end_label := case when p_end_order_index is null then null else p_end_order_index + 1 end;
  perform public.create_notification(
    p_reviewer_id, p_project_id, null, 'review_assigned', project_title,
    case when start_label is null then 'You were assigned this paper for review.'
      else format('You were assigned questions %s-%s for review.', start_label, end_label) end,
    assignment_id
  );

  return assignment_id;
end;
$$;

create or replace function public.revoke_review_assignment(p_assignment_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_admin_or_owner() then
    raise exception 'Only admins can revoke reviewer assignments' using errcode = '42501';
  end if;
  update public.review_assignments
  set status = 'completed', completed_at = coalesce(completed_at, now())
  where id = p_assignment_id;
  if not found then raise exception 'Assignment not found' using errcode = 'P0002'; end if;
end;
$$;

grant execute on function public.assign_reviewer(uuid, uuid, integer, integer) to authenticated;
grant execute on function public.revoke_review_assignment(uuid) to authenticated;

-- Preserve staging provenance and AI evidence when promoting to review.
create or replace function public.promote_extraction_questions(p_job_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  job_row public.extraction_jobs%rowtype;
  eq_row record;
  next_order integer;
  created_count integer := 0;
  project_status_value public.project_status;
begin
  select * into job_row from public.extraction_jobs where id = p_job_id;
  if not found then raise exception 'Extraction job not found' using errcode = 'P0002'; end if;
  if job_row.status not in ('completed', 'completed_with_errors') then return 0; end if;

  select coalesce(max(order_index), -1) + 1 into next_order
  from public.questions where project_id = job_row.project_id;

  for eq_row in
    select eq.*, jp.pdf_page, sd.id as document_id
    from public.extraction_questions eq
    join public.extraction_job_pages jp on jp.id = eq.job_page_id
    join public.extraction_jobs ej on ej.id = jp.job_id
    join public.source_documents sd on sd.id = ej.source_document_id
    where jp.job_id = p_job_id and eq.imported_question_id is null
    order by jp.pdf_page, eq.question_number
  loop
    declare
      new_qid uuid;
      eq_choices jsonb;
    begin
      select coalesce(
        (select jsonb_agg(trim(both '"' from choice::text)) from jsonb_array_elements(eq_row.choices) choice),
        '[]'::jsonb
      ) into eq_choices;

      insert into public.questions (
        project_id, order_index, question_text, choices, correct_answer, explanation, status,
        extraction_question_id, source_document_id, source_pdf_page, source_region,
        ai_predicted_choice_index, ai_confidence, ai_reasoning, ai_answer_basis
      ) values (
        job_row.project_id, next_order, eq_row.prompt, eq_choices, '', '', 'unverified',
        eq_row.id, eq_row.document_id, eq_row.pdf_page, eq_row.source_region,
        eq_row.ai_predicted_choice_index, eq_row.ai_confidence, eq_row.ai_reasoning, eq_row.ai_answer_basis
      ) returning id into new_qid;

      update public.extraction_questions
      set imported_question_id = new_qid, updated_at = now()
      where id = eq_row.id;
      next_order := next_order + 1;
      created_count := created_count + 1;
    end;
  end loop;

  if created_count > 0 then
    select status into project_status_value from public.projects where id = job_row.project_id;
    if project_status_value = 'draft' then
      update public.projects set status = 'in_review', updated_at = now()
      where id = job_row.project_id;
    end if;
  end if;
  return created_count;
end;
$$;

revoke execute on function public.promote_extraction_questions(uuid) from public, anon, authenticated;
grant execute on function public.promote_extraction_questions(uuid) to service_role;

-- Answer verification must select one of the extracted choices.
drop function if exists public.verify_question(uuid);
create or replace function public.verify_question(p_question_id uuid, p_correct_answer text)
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
  select * into question_row from public.questions where id = p_question_id for update;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  if not public.can_edit_question(p_question_id) then
    raise exception 'You cannot verify this question' using errcode = '42501';
  end if;
  if question_row.status not in ('unverified', 'flagged') then
    raise exception 'Only unverified or flagged questions can be verified' using errcode = '55000';
  end if;
  if nullif(btrim(p_correct_answer), '') is null or not (question_row.choices @> jsonb_build_array(btrim(p_correct_answer))) then
    raise exception 'Select one of the four choices as the verified answer' using errcode = '22023';
  end if;

  select status into project_status_value from public.projects where id = question_row.project_id for update;
  if project_status_value in ('approved', 'exported', 'archived') then
    raise exception 'This paper is no longer reviewable' using errcode = '55000';
  end if;

  update public.questions
  set status = 'verified', correct_answer = btrim(p_correct_answer),
      verified_by = (select auth.uid()), verified_at = now(), flag_note = null, updated_at = now()
  where id = p_question_id;

  update public.review_assignments ra
  set status = 'in_progress'
  where ra.project_id = question_row.project_id
    and ra.reviewer_id = (select auth.uid())
    and ra.status = 'assigned'
    and (ra.start_order_index is null or question_row.order_index >= ra.start_order_index)
    and (ra.end_order_index is null or question_row.order_index <= ra.end_order_index);

  select count(*) into remaining_count
  from public.questions q
  where q.project_id = question_row.project_id and q.status <> 'verified';

  if remaining_count = 0 then
    update public.projects set status = 'ready_for_approval', updated_at = now()
    where id = question_row.project_id;
  elsif project_status_value in ('draft', 'blocked') then
    update public.projects set status = 'in_review', updated_at = now()
    where id = question_row.project_id;
  end if;

  update public.review_assignments ra
  set status = 'completed', completed_at = now()
  where ra.project_id = question_row.project_id
    and ra.reviewer_id = (select auth.uid())
    and ra.status <> 'completed'
    and (ra.start_order_index is null or question_row.order_index >= ra.start_order_index)
    and (ra.end_order_index is null or question_row.order_index <= ra.end_order_index)
    and not exists (
      select 1 from public.questions q
      where q.project_id = ra.project_id and q.status <> 'verified'
        and (ra.start_order_index is null or q.order_index >= ra.start_order_index)
        and (ra.end_order_index is null or q.order_index <= ra.end_order_index)
    );

  perform public.write_audit_event(
    'question.verified', 'question', p_question_id,
    jsonb_build_object('project_id', question_row.project_id, 'correct_answer', btrim(p_correct_answer))
  );
  return case when remaining_count = 0 then 'ready_for_approval'::public.project_status else 'in_review'::public.project_status end;
end;
$$;

grant execute on function public.verify_question(uuid, text) to authenticated;

create or replace function public.save_question_explanation(
  p_question_id uuid,
  p_explanation_draft text,
  p_explanation text,
  p_mark_verified boolean default false
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  question_row public.questions%rowtype;
begin
  select * into question_row from public.questions where id = p_question_id for update;
  if not found then raise exception 'Question not found' using errcode = 'P0002'; end if;
  if not public.can_edit_question(p_question_id) then
    raise exception 'You cannot edit this explanation' using errcode = '42501';
  end if;
  if question_row.status <> 'verified' then
    raise exception 'Verify the answer before saving a final explanation' using errcode = '55000';
  end if;
  update public.questions
  set explanation_draft = nullif(btrim(p_explanation_draft), ''),
      explanation = coalesce(btrim(p_explanation), explanation),
      explanation_verified_by = case when p_mark_verified then (select auth.uid()) else explanation_verified_by end,
      explanation_verified_at = case when p_mark_verified then now() else explanation_verified_at end,
      updated_at = now()
  where id = p_question_id;
end;
$$;

grant execute on function public.save_question_explanation(uuid, text, text, boolean) to authenticated;

create or replace function public.set_question_image_path(
  p_question_id uuid,
  p_project_id uuid,
  p_image_path text
)
returns text
language plpgsql
security definer
set search_path = public, storage
as $$
declare old_path text;
begin
  if not public.can_edit_question(p_question_id) then
    raise exception 'You cannot manage this question image' using errcode = '42501';
  end if;
  select image_path into old_path from public.questions
  where id = p_question_id and project_id = p_project_id for update;
  if not found then raise exception 'Question does not belong to this paper' using errcode = '42501'; end if;
  if p_image_path is not null and not public.is_valid_question_image_path(p_project_id, p_question_id, p_image_path) then
    raise exception 'Image path does not belong to this question or object is missing' using errcode = '22023';
  end if;
  update public.questions set image_path = p_image_path, updated_at = now() where id = p_question_id;
  perform public.write_audit_event('question.image_changed', 'question', p_question_id,
    jsonb_build_object('project_id', p_project_id, 'attached', p_image_path is not null));
  return old_path;
end;
$$;

grant execute on function public.set_question_image_path(uuid, uuid, text) to authenticated;
