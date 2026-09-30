"use server";

import { createClient } from "@/lib/supabase/server";
import {
  assertProjectReady,
  buildContentPack,
  createPackZip,
  packZipFilename,
  type ExportProject,
  type ExportQuestion,
} from "@/lib/export-pack";

export async function exportContentPack(formData: FormData): Promise<{ error: string | null; filename: string | null; blob: Blob | null }> {
  const projectId = formData.get("project_id") as string;
  if (!projectId) return { error: "Missing project ID.", filename: null, blob: null };

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", filename: null, blob: null };

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  const role = profile?.role;
  if (role !== "owner" && role !== "admin") {
    return { error: "Only admins can export.", filename: null, blob: null };
  }

  const { data: project, error: projectError } = await supabase
    .from("projects")
    .select("id, title, exam_year, subject, stream, status")
    .eq("id", projectId)
    .single();

  if (projectError || !project) return { error: "Paper not found.", filename: null, blob: null };
  const typed = project as ExportProject;

  try {
    assertProjectReady(typed);
  } catch (e) {
    return { error: (e as Error).message, filename: null, blob: null };
  }

  const { data: questions, error: questionsError } = await supabase
    .from("questions")
    .select("id, order_index, question_text, choices, correct_answer, explanation, explanation_draft, source_pdf_page, status, verified_by, verified_at")
    .eq("project_id", projectId)
    .order("order_index", { ascending: true });

  if (questionsError) return { error: `Failed to fetch questions: ${questionsError.message}`, filename: null, blob: null };

  const typedQuestions = (questions ?? []) as unknown as ExportQuestion[];

  let pack: Record<string, unknown>;
  let filename: string;
  try {
    pack = buildContentPack(typed, typedQuestions);
    filename = packZipFilename(typed);
  } catch (e) {
    return { error: (e as Error).message, filename: null, blob: null };
  }

  const blob = await createPackZip(pack);

  return { error: null, filename, blob: blob as unknown as Blob };
}
