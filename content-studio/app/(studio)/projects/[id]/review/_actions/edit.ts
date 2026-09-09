"use server";

import { createClient } from "@/lib/supabase/server";

export type EditState = {
  error: string | null;
  saved: boolean;
};

export async function editQuestion(
  _prev: EditState,
  formData: FormData,
): Promise<EditState> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", saved: false };

  const questionId = formData.get("question_id") as string;
  if (!questionId) return { error: "Missing question.", saved: false };

  const questionText = formData.get("question_text") as string;
  const correctAnswer = formData.get("correct_answer") as string;
  const explanation = formData.get("explanation") as string;
  const choicesRaw = formData.get("choices") as string;

  let choices: string[] = [];
  if (choicesRaw) {
    try {
      choices = JSON.parse(choicesRaw);
    } catch {
      return { error: "Invalid choices format.", saved: false };
    }
  }

  const { error } = await supabase
    .from("questions")
    .update({
      question_text: questionText,
      choices,
      correct_answer: correctAnswer,
      explanation,
      updated_at: new Date().toISOString(),
    })
    .eq("id", questionId);

  if (error) return { error: `Failed to save: ${error.message}`, saved: false };

  return { error: null, saved: true };
}
