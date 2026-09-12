-- Keep the final review RPC boundary closed to anon/public callers.

revoke execute on function public.assign_reviewer(uuid, uuid, integer, integer) from public, anon;
grant execute on function public.assign_reviewer(uuid, uuid, integer, integer) to authenticated;

revoke execute on function public.can_review_question(uuid) from public, anon;
grant execute on function public.can_review_question(uuid) to authenticated;

revoke execute on function public.verify_question(uuid, text) from public, anon;
grant execute on function public.verify_question(uuid, text) to authenticated;

revoke execute on function public.save_question_explanation(uuid, text, text, boolean) from public, anon;
grant execute on function public.save_question_explanation(uuid, text, text, boolean) to authenticated;
