-- Fix: add 'extensions' to import_manual_questions search_path
-- so digest() from pgcrypto (installed in extensions schema) is found.

drop function if exists public.import_manual_questions(uuid, jsonb, text);

create function public.import_manual_questions(
  p_project_id uuid,
  p_raw_payload jsonb,
  p_source_filename text default null
)
returns integer
language plpgsql
security definer
set search_path = public, extensions
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
  q_source_page integer;

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

  payload_text := p_raw_payload::text;
  payload_hash := encode(digest(payload_text, 'sha256'), 'hex');

  insert into public.manual_imports(project_id, uploaded_by, source_filename, raw_payload, payload_sha256)
  values (p_project_id, (select auth.uid()), p_source_filename, p_raw_payload, payload_hash)
  returning id into import_id;

  select coalesce(max(order_index), -1) + 1 into next_order
  from public.questions where project_id = p_project_id;

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

    select coalesce(jsonb_agg(trim(both ' ' from c #>> '{}')), '[]'::jsonb)
    into q_choices
    from jsonb_array_elements(q_choices) c
    where nullif(btrim(c #>> '{}'), '') is not null;

    if jsonb_array_length(q_choices) <> 4 then
      raise exception 'Each question requires exactly four non-empty choices' using errcode = '22023';
    end if;

    q_explanation := coalesce(question->>'explanation', '');

    q_source_page := nullif(question->>'source_page', '')::integer;

    insert into public.questions (
      project_id, order_index, question_text, choices,
      correct_answer, explanation_draft, status, manual_import_id,
      source_pdf_page
    ) values (
      p_project_id, next_order, q_prompt, q_choices,
      '', q_explanation, 'unverified', import_id,
      q_source_page
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

notify pgrst, 'reload schema';
