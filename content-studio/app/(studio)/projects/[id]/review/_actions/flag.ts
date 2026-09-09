"use server";

import { createClient } from "@/lib/supabase/server";

export type FlagState = {
  error: string | null;
  done: boolean;
};

export async function flagQuestion(
  _prev: FlagState,
  formData: FormData,
): Promise<FlagState> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", done: false };

  const questionId = formData.get("question_id") as string;
  const projectId = formData.get("project_id") as string;
  const flagNote = (formData.get("flag_note") as string) || "";
  if (!questionId || !projectId) return { error: "Missing question or project.", done: false };

  const { error } = await supabase
    .from("questions")
    .update({
      status: "flagged",
      flag_note: flagNote,
      updated_at: new Date().toISOString(),
    })
    .eq("id", questionId);

  if (error) return { error: `Failed to flag: ${error.message}`, done: false };

  await supabase.from("audit_events").insert({
    actor_id: user.id,
    action: "question.flagged",
    entity_type: "question",
    entity_id: questionId,
    metadata: { project_id: projectId, note: flagNote },
  });

  return { error: null, done: true };
}
