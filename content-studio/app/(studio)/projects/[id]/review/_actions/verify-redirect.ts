"use server";

import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export async function verifyAndRedirect(formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const questionId = formData.get("question_id") as string;
  const projectId = formData.get("project_id") as string;
  const correctAnswer = String(formData.get("correct_answer") ?? "").trim();
  const explanationDraft = String(formData.get("explanation_draft") ?? "").trim();
  const explanation = String(formData.get("explanation") ?? "").trim();
  const markExplanationVerified = formData.get("mark_explanation_verified") === "on";
  const assignmentId = String(formData.get("assignment_id") ?? "").trim();
  if (!questionId || !projectId || !correctAnswer) redirect(`/projects/${projectId}/review`);

  const { error } = await supabase.rpc("verify_question", {
    p_question_id: questionId,
    p_correct_answer: correctAnswer,
  });
  if (error) redirect(`/projects/${projectId}/review?error=${encodeURIComponent(error.message)}`);

  if (explanationDraft || explanation || markExplanationVerified) {
    await supabase.rpc("save_question_explanation", {
      p_question_id: questionId,
      p_explanation_draft: explanationDraft,
      p_explanation: explanation,
      p_mark_verified: markExplanationVerified,
    });
  }

  redirect(`/projects/${projectId}/review${assignmentId ? `?assignment=${assignmentId}` : ""}`);
}
