-- Auto-update `updated_at` on any row change
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger questions_set_updated_at
  before update on public.questions
  for each row
  execute function public.set_updated_at();

-- Log every status change to audit_events automatically.
-- SECURITY DEFINER because the existing audit_events INSERT policy only allows
-- admin/owner actors — but any project member (reviewer/uploader) can change a
-- question's status, so the trigger must bypass that policy to log on their behalf.
-- actor_id is still set to the real acting user via auth.uid(), not the definer.
create or replace function public.log_question_status_change()
returns trigger
security definer
set search_path = public
language plpgsql
as $$
begin
  if old.status is distinct from new.status then
    insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
    values (
      auth.uid(),
      'question_status_changed',
      'question',
      new.id,
      jsonb_build_object(
        'project_id', new.project_id,
        'from_status', old.status,
        'to_status', new.status,
        'flag_note', new.flag_note
      )
    );
  end if;
  return new;
end;
$$;

create trigger questions_log_status_change
  after update on public.questions
  for each row
  execute function public.log_question_status_change();

-- Prevent two questions in the same paper from silently sharing an order position,
-- which would break "resume at first unverified question" logic.
alter table public.questions
  add constraint questions_project_order_unique unique (project_id, order_index);
