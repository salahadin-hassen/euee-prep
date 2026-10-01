"use server";

import { createClient } from "@/lib/supabase/server";
import {
  assertProjectReady,
  buildContentPack,
  createPackZip,
  type ExportProject,
  type ExportQuestion,
} from "@/lib/export-pack";
import {
  PUBLISHED_PAPERS_BUCKET,
  buildPublishedPaperRow,
  publishedPaperStoragePath,
  type PublishedPaperRow,
} from "@/lib/published-papers";

export interface PublishResult {
  error: string | null;
  packId: string | null;
  packVersion: string | null;
  storagePath: string | null;
}

/**
 * Publish an approved paper: build the signed v3 pack, upload its ZIP to the
 * private `published-papers` bucket, and register one `published_papers`
 * catalog row. The student app downloads from this catalog — it never imports
 * files by hand.
 *
 * Re-publishing the same `(pack_id, pack_version)` overwrites the object and
 * refreshes `updated_at` (pack versions stay immutable in content).
 */
export async function publishContentPack(formData: FormData): Promise<PublishResult> {
  const failed = (error: string): PublishResult => ({
    error,
    packId: null,
    packVersion: null,
    storagePath: null,
  });

  const projectId = formData.get("project_id") as string;
  if (!projectId) return failed("Missing project ID.");

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return failed("You must be signed in.");

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  const role = profile?.role;
  if (role !== "owner" && role !== "admin") {
    return failed("Only admins can publish.");
  }

  const { data: project, error: projectError } = await supabase
    .from("projects")
    .select("id, title, exam_year, subject, stream, status")
    .eq("id", projectId)
    .single();

  if (projectError || !project) return failed("Paper not found.");
  const typed = project as ExportProject;

  try {
    assertProjectReady(typed);
  } catch (e) {
    return failed((e as Error).message);
  }

  const { data: questions, error: questionsError } = await supabase
    .from("questions")
    .select("id, order_index, question_text, choices, correct_answer, explanation, explanation_draft, source_pdf_page, status, verified_by, verified_at")
    .eq("project_id", projectId)
    .order("order_index", { ascending: true });

  if (questionsError) return failed(`Failed to fetch questions: ${questionsError.message}`);

  const typedQuestions = (questions ?? []) as unknown as ExportQuestion[];

  let pack: Record<string, unknown>;
  try {
    pack = buildContentPack(typed, typedQuestions);
  } catch (e) {
    return failed((e as Error).message);
  }

  const packId = pack.pack_id as string;
  const packVersion = pack.pack_version as string;
  const storagePath = publishedPaperStoragePath(packId, packVersion);

  const zipBytes = await createPackZip(pack);

  const { error: uploadError } = await supabase.storage
    .from(PUBLISHED_PAPERS_BUCKET)
    .upload(storagePath, zipBytes, {
      contentType: "application/zip",
      upsert: true,
    });
  if (uploadError) return failed(`Failed to store pack ZIP: ${uploadError.message}`);

  let row: PublishedPaperRow;
  try {
    row = buildPublishedPaperRow(pack, zipBytes.byteLength);
  } catch (e) {
    return failed((e as Error).message);
  }

  const { error: publishError } = await supabase
    .from("published_papers")
    .upsert(row, { onConflict: "pack_id,pack_version" });
  if (publishError) return failed(`Failed to register published paper: ${publishError.message}`);

  return { error: null, packId, packVersion, storagePath };
}
