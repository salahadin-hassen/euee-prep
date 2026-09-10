"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export async function approveProject(formData: FormData) {
  const projectId = formData.get("project_id");
  if (typeof projectId !== "string" || !projectId) redirect("/projects");

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { error } = await supabase.rpc("approve_project", { p_project_id: projectId });
  if (error) redirect(`/projects/${projectId}?error=${encodeURIComponent(error.message)}`);
  redirect(`/projects/${projectId}`);
}
