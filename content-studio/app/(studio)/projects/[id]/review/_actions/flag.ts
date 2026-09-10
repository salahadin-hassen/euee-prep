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

  const { error } = await supabase.rpc("flag_question", {
    p_question_id: questionId,
    p_flag_note: flagNote,
  });

  if (error) return { error: `Failed to flag: ${error.message}`, done: false };

  return { error: null, done: true };
}
