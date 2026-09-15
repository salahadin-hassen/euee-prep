-- Manual JSON question import for the editorial workbench.
-- Accepts untrusted AI-produced JSON and creates reviewable questions.

create table if not exists public.manual_imports (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  uploaded_by uuid not null references auth.users(id),
  source_filename text,
  raw_payload jsonb not null,
  payload_sha256 text not null,
  created_at timestamptz not null default now()
);

alter table public.manual_imports enable row level security;

create policy "admins can read manual imports"
  on public.manual_imports for select to authenticated
  using (public.is_admin_or_owner());

grant select on public.manual_imports to authenticated;

alter table public.questions
  add column if not exists manual_import_id uuid references public.manual_imports(id);

create index if not exists questions_manual_import_idx
  on public.questions(manual_import_id);

create or replace function public.import_manual_questions(
  p_project_id uuid,
  p_raw_payload jsonb,
  p_source_filename text default null
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  question jsonb;
  next_order integer;
  imported_count integer := 0;
  project_status_value public.project_status;
  import_id uuid;
  payload_text text;
  payload_hash text;
  q_prompt text;
  q_choices jsonb;
  q_explanation text;

begin
  if not public.is_admin_or_owner() then
    raise exception 'Only admins can import questions' using errcode = '42501';
  end if;

  select status into project_status_value
  from public.projects where id = p_project_id for update;
  if not found then raise exception 'Project not found' using errcode = '23503'; end if;
  if project_status_value not in ('draft', 'in_review', 'blocked') then
    raise exception 'Questions cannot be imported in the current paper state' using errcode = '55000';
  end if;

  if p_raw_payload is null then
    raise exception 'JSON payload is empty' using errcode = '22023';
  end if;

  -- Store the raw payload for provenance
  payload_text := p_raw_payload::text;
  payload_hash := encode(digest(payload_text, 'sha256'), 'hex');

  insert into public.manual_imports(project_id, uploaded_by, source_filename, raw_payload, payload_sha256)
  values (p_project_id, (select auth.uid()), p_source_filename, p_raw_payload, payload_hash)
  returning id into import_id;

  select coalesce(max(order_index), -1) + 1 into next_order
  from public.questions where project_id = p_project_id;

  -- Accept flat questions array or nested content-pack with chapters/topics
  for question in
    select jsonb_array_elements(
      case jsonb_typeof(p_raw_payload)
        when 'array' then p_raw_payload
        when 'object' then coalesce(
          (
            select jsonb_agg(elem)
            from jsonb_array_elements(
              coalesce(p_raw_payload->'chapters', '[]'::jsonb)
            ) chapter,
            jsonb_array_elements(coalesce(chapter->'topics', '[]'::jsonb)) topic,
            jsonb_array_elements(coalesce(topic->'questions', '[]'::jsonb)) elem
          ),
          '[]'::jsonb
        )
        else '[]'::jsonb
      end
    )
  loop
    q_prompt := nullif(btrim(question->>'prompt'), '');
    if q_prompt is null then
      raise exception 'Each question needs a prompt (question text)' using errcode = '22023';
    end if;

    q_choices := question->'choices';
    if q_choices is null or jsonb_typeof(q_choices) <> 'array' then
      raise exception 'Question needs a choices array' using errcode = '22023';
    end if;

    -- Normalize choices: trim whitespace, reject empties
    select coalesce(jsonb_agg(trim(both ' ' from c #>> '{}')), '[]'::jsonb)
    into q_choices
    from jsonb_array_elements(q_choices) c
    where nullif(btrim(c #>> '{}'), '') is not null;

    if jsonb_array_length(q_choices) <> 4 then
      raise exception 'Each question requires exactly four non-empty choices' using errcode = '22023';
    end if;

    q_explanation := coalesce(question->>'explanation', '');

    -- Do NOT write correct_answer here — human verification is authoritative.
    -- Store the AI-provided answer as a draft explanation for the reviewer to edit.
    insert into public.questions (
      project_id, order_index, question_text, choices,
      correct_answer, explanation_draft, status, manual_import_id
    ) values (
      p_project_id, next_order, q_prompt, q_choices,
      '', q_explanation, 'unverified', import_id
    );

    next_order := next_order + 1;
    imported_count := imported_count + 1;
  end loop;

  if imported_count = 0 then
    raise exception 'No questions found in JSON' using errcode = '22023';
  end if;

  if project_status_value = 'draft' then
    update public.projects set status = 'in_review', updated_at = now()
    where id = p_project_id;
  end if;

  perform public.write_audit_event(
    'project.questions_imported', 'project', p_project_id,
    jsonb_build_object('import_id', import_id, 'question_count', imported_count, 'source', p_source_filename)
  );

  return imported_count;
end;
$$;

grant execute on function public.import_manual_questions(uuid, jsonb, text) to authenticated;
