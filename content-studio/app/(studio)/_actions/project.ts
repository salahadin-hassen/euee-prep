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

  const { data: projectId, error } = await supabase.rpc("create_project", {
    p_title: title.trim(),
    p_exam_year: parsedYear,
    p_subject: subject.trim(),
    p_stream: stream,
  });

  if (error || !projectId) {
    return { error: `Failed to create project: ${error?.message ?? "No project was created."}` };
  }

  redirect(`/projects/${projectId}`);
}
