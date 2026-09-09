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

  const { error } = await supabase
    .from("questions")
    .update({
      status: "verified",
      verified_by: user.id,
      verified_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("id", questionId);

  if (!error) {
    await supabase.from("audit_events").insert({
      actor_id: user.id,
      action: "question.verified",
      entity_type: "question",
      entity_id: questionId,
      metadata: { project_id: projectId },
    });

    const { count } = await supabase
      .from("questions")
      .select("id", { count: "exact", head: true })
      .eq("project_id", projectId)
      .eq("status", "unverified");

    if (count === 0) {
      await supabase
        .from("projects")
        .update({ status: "approved", updated_at: new Date().toISOString() })
        .eq("id", projectId);

      await supabase.from("audit_events").insert({
        actor_id: user.id,
        action: "project.auto_approved",
        entity_type: "project",
        entity_id: projectId,
        metadata: { reason: "all questions verified" },
      });
    }
  }

  redirect(`/projects/${projectId}/review`);
}
