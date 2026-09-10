-- Promote extraction_questions into reviewable questions.
-- Called by the server-side completion handler using service_role.
-- Idempotent: skips extraction_questions that already have an imported_question_id.
-- Does NOT populate correct_answer from AI predictions — human verification is the source of truth.

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
  if not found then
    raise exception 'Extraction job not found' using errcode = 'P0002';
  end if;

  if job_row.status not in ('completed', 'completed_with_errors') then
    return 0;
  end if;

  -- Get current max order_index for the project
  select coalesce(max(order_index), -1) + 1 into next_order
  from public.questions where project_id = job_row.project_id;

  -- Promote each extraction_question that hasn't been imported yet
  for eq_row in
    select eq.*
    from public.extraction_questions eq
    join public.extraction_job_pages jp on jp.id = eq.job_page_id
    where jp.job_id = p_job_id
      and eq.imported_question_id is null
    order by jp.pdf_page, eq.question_number
  loop
    declare
      new_qid uuid;
      eq_choices jsonb;
    begin
      -- Normalize choices to text array
      select coalesce(
        (select jsonb_agg(trim(both '"' from choice::text)) from jsonb_array_elements(eq_row.choices) choice),
        '[]'::jsonb
      ) into eq_choices;

      insert into public.questions (
        project_id, order_index, question_text, choices,
        correct_answer, explanation, status
      ) values (
        job_row.project_id, next_order, eq_row.prompt, eq_choices,
        '', '', 'unverified'
      ) returning id into new_qid;

      update public.extraction_questions
      set imported_question_id = new_qid, updated_at = now()
      where id = eq_row.id;

      next_order := next_order + 1;
      created_count := created_count + 1;
    end;
  end loop;

  -- Advance project status from draft to in_review if questions were promoted
  if created_count > 0 then
    select status into project_status_value
    from public.projects where id = job_row.project_id;

    if project_status_value = 'draft' then
      update public.projects
      set status = 'in_review', updated_at = now()
      where id = job_row.project_id;
    end if;
  end if;

  return created_count;
end;
$$;

revoke execute on function public.promote_extraction_questions(uuid) from public, anon, authenticated;
grant execute on function public.promote_extraction_questions(uuid) to service_role;
