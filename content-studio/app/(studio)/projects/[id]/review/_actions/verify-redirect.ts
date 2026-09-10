"use server";

import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";

export async function verifyAndRedirect(formData: FormData) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const questionId = formData.get("question_id") as string;
  const projectId = formData.get("project_id") as string;
  if (!questionId || !projectId) redirect(`/projects/${projectId}/review`);

  await supabase.rpc("verify_question", { p_question_id: questionId });

  redirect(`/projects/${projectId}/review`);
}
