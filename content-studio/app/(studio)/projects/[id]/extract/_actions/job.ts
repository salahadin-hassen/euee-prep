"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { dispatchExtractionWorker } from "@/lib/github/dispatch";

export type CreateJobResult =
  | { ok: true; jobId: string; dispatchWarning: string | null }
  | { ok: false; error: string };

/**
 * Create an extraction job and automatically dispatch the GitHub Actions worker.
 *
 * Deduplication: if an existing job for the same source document is already
 * queued or processing, return that job instead of creating a duplicate.
 */
export async function createExtractionJob(
  projectId: string,
  sourceDocumentId: string,
  requestedPages: number[],
): Promise<CreateJobResult> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You must be signed in." };

  const { data: existing, error: existingError } = await supabase
    .from("extraction_jobs")
    .select("id, status")
    .eq("source_document_id", sourceDocumentId)
    .in("status", ["queued", "processing"])
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (existingError) {
    console.error("[createExtractionJob] Dedup query failed:", existingError.message);
  }

  if (existing) {
    revalidatePath(`/projects/${projectId}`);
    return { ok: true, jobId: existing.id, dispatchWarning: null };
  }

  const { data, error } = await supabase.rpc("create_extraction_job", {
    p_project_id: projectId,
    p_source_document_id: sourceDocumentId,
    p_requested_pages: requestedPages,
  });
  if (error) return { ok: false, error: `Could not create extraction job: ${error.message}` };

  const jobId = data as string;
  revalidatePath(`/projects/${projectId}`);
  revalidatePath(`/projects/${projectId}/extract`);

  // Notify the job creator that extraction has started
  const { data: projectRow } = await supabase
    .from("projects")
    .select("title")
    .eq("id", projectId)
    .single();
  await supabase.rpc("create_notification", {
    p_user_id: user.id,
    p_project_id: projectId,
    p_job_id: jobId,
    p_kind: "extraction_started",
    p_title: projectRow?.title ?? "Paper",
    p_body: `Extracting ${requestedPages.length} page${requestedPages.length !== 1 ? "s" : ""}`,
  });

  const dispatchResult = await dispatchExtractionWorker(jobId);
  const dispatchWarning = dispatchResult.ok
    ? null
    : dispatchResult.error ?? "Worker dispatch failed — the job will be retried by the daily recovery workflow.";

  return { ok: true, jobId, dispatchWarning };
}

export async function cancelExtractionJob(
  projectId: string,
  jobId: string,
): Promise<{ error: string | null }> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in." };

  const { error } = await supabase.rpc("cancel_extraction_job", { p_job_id: jobId });
  if (error) return { error: `Could not cancel extraction job: ${error.message}` };
  revalidatePath(`/projects/${projectId}/extract`);
  return { error: null };
}
