"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";

export type CreateProjectState = {
  error: string | null;
};

export async function createProject(
  _prev: CreateProjectState,
  formData: FormData,
): Promise<CreateProjectState> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  if (!profile || !canAccessAdminSurface(profile.role as AppRole)) {
    return { error: "Only admins can create projects." };
  }

  const title = formData.get("title");
  const examYear = formData.get("exam_year");
  const subject = formData.get("subject");
  const stream = formData.get("stream");

  if (
    typeof title !== "string" ||
    title.trim().length === 0 ||
    typeof examYear !== "string" ||
    examYear.trim().length === 0 ||
    typeof subject !== "string" ||
    subject.trim().length === 0 ||
    typeof stream !== "string" ||
    stream.trim().length === 0
  ) {
    return { error: "All fields are required." };
  }

  const parsedYear = parseInt(examYear, 10);
  if (isNaN(parsedYear) || parsedYear <= 0) {
    return { error: "Exam year must be a positive number." };
  }

  if (stream !== "natural_science" && stream !== "social_science") {
    return { error: "Stream must be natural science or social science." };
  }

  const { data: project, error: insertError } = await supabase
    .from("projects")
    .insert({
      title: title.trim(),
      exam_year: parsedYear,
      subject: subject.trim(),
      stream,
      status: "draft",
      created_by: user.id,
    })
    .select("id")
    .single();

  if (insertError) {
    return { error: `Failed to create project: ${insertError.message}` };
  }

  const { error: memberError } = await supabase
    .from("project_members")
    .insert({
      project_id: project.id,
      user_id: user.id,
      role: "admin",
    });

  if (memberError) {
    return { error: `Project created but failed to add you as member: ${memberError.message}` };
  }

  const { error: auditError } = await supabase
    .from("audit_events")
    .insert({
      actor_id: user.id,
      action: "project.created",
      entity_type: "project",
      entity_id: project.id,
      metadata: { title: title.trim(), subject: subject.trim(), stream },
    });

  if (auditError) {
    return { error: `Project created but audit log failed: ${auditError.message}` };
  }

  redirect(`/projects/${project.id}`);
}
