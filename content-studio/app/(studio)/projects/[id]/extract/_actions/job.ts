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
  console.log(`[EXTRACT:createExtractionJob] START src=${sourceDocumentId} pages=${requestedPages.length}`);
  const t0 = Date.now();
  const supabase = await createClient();
  console.log(`[EXTRACT:createExtractionJob:createClient] ${Date.now() - t0}ms`);
  const t1 = Date.now();
  const { data: { user } } = await supabase.auth.getUser();
  console.log(`[EXTRACT:createExtractionJob:getUser] ${Date.now() - t1}ms`);
  if (!user) return { ok: false, error: "You must be signed in." };

  const t2 = Date.now();
  const { data: existing, error: existingError } = await supabase
    .from("extraction_jobs")
    .select("id, status")
    .eq("source_document_id", sourceDocumentId)
    .in("status", ["queued", "processing"])
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  console.log(`[EXTRACT:createExtractionJob:dedup] ${Date.now() - t2}ms existing=${existing?.id ?? "none"}`);

  if (existingError) {
    console.error("[createExtractionJob] Dedup query failed:", existingError.message);
  }

  if (existing) {
    console.log(`[EXTRACT:createExtractionJob] DEDUP_HIT jobId=${existing.id}`);
    revalidatePath(`/projects/${projectId}`);
    return { ok: true, jobId: existing.id, dispatchWarning: null };
  }

  const t3 = Date.now();
  const { data, error } = await supabase.rpc("create_extraction_job", {
    p_project_id: projectId,
    p_source_document_id: sourceDocumentId,
    p_requested_pages: requestedPages,
  });
  console.log(`[EXTRACT:createExtractionJob:rpc] ${Date.now() - t3}ms`);
  if (error) { console.error(`[EXTRACT:createExtractionJob] RPC_ERROR: ${error.message}`); return { ok: false, error: `Could not create extraction job: ${error.message}` }; }

  const jobId = data as string;
  revalidatePath(`/projects/${projectId}`);
  revalidatePath(`/projects/${projectId}/extract`);

  // Fire-and-forget: notify + dispatch in the background.
  // The client must NOT wait for these — the job is already created and queued.
  void (async () => {
    try {
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
    } catch (err) {
      console.error("[createExtractionJob] Notification failed:", err instanceof Error ? err.message : err);
    }

    try {
      const dispatchResult = await dispatchExtractionWorker(jobId);
      if (!dispatchResult.ok) {
        console.error("[createExtractionJob] Dispatch failed:", dispatchResult.error);
      }
    } catch (err) {
      console.error("[createExtractionJob] Dispatch failed:", err instanceof Error ? err.message : err);
    }
  })();

  console.log(`[EXTRACT:createExtractionJob] RETURNING jobId=${jobId}`);
  return { ok: true, jobId, dispatchWarning: null };
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

/**
 * Retry a failed or cancelled extraction job.
 * Reuses the existing source PDF and creates a new job with the same pages.
 * If an active job already exists for this source document, returns that instead.
 */
export async function retryExtractionJob(
  projectId: string,
  jobId: string,
): Promise<CreateJobResult> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { ok: false, error: "You must be signed in." };

  const { data: failedJob } = await supabase
    .from("extraction_jobs")
    .select("id, source_document_id, requested_pages, status")
    .eq("id", jobId)
    .eq("project_id", projectId)
    .single();

  if (!failedJob) return { ok: false, error: "Extraction job not found." };
  if (failedJob.status !== "failed" && failedJob.status !== "cancelled" && failedJob.status !== "completed_with_errors" && failedJob.status !== "quota_exhausted") {
    return { ok: false, error: "Only failed, cancelled, or partial jobs can be retried." };
  }

  // Check for existing active job (dedup)
  const { data: existing } = await supabase
    .from("extraction_jobs")
    .select("id, status")
    .eq("source_document_id", failedJob.source_document_id)
    .in("status", ["queued", "processing"])
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();

  if (existing) {
    revalidatePath(`/projects/${projectId}`);
    return { ok: true, jobId: existing.id, dispatchWarning: null };
  }

  const pages = failedJob.requested_pages as number[];

  // Create a new job for the same source document
  const { data, error } = await supabase.rpc("create_extraction_job", {
    p_project_id: projectId,
    p_source_document_id: failedJob.source_document_id,
    p_requested_pages: pages,
  });
  if (error) return { ok: false, error: `Could not retry extraction: ${error.message}` };

  const newJobId = data as string;
  revalidatePath(`/projects/${projectId}`);

  // Fire-and-forget: notify + dispatch in the background.
  void (async () => {
    try {
      const { data: projectRow } = await supabase
        .from("projects")
        .select("title")
        .eq("id", projectId)
        .single();
      await supabase.rpc("create_notification", {
        p_user_id: user.id,
        p_project_id: projectId,
        p_job_id: newJobId,
        p_kind: "extraction_started",
        p_title: projectRow?.title ?? "Paper",
        p_body: `Retrying extraction for ${pages.length} page${pages.length !== 1 ? "s" : ""}`,
      });
    } catch (err) {
      console.error("[retryExtractionJob] Notification failed:", err instanceof Error ? err.message : err);
    }

    try {
      const dispatchResult = await dispatchExtractionWorker(newJobId);
      if (!dispatchResult.ok) {
        console.error("[retryExtractionJob] Dispatch failed:", dispatchResult.error);
      }
    } catch (err) {
      console.error("[retryExtractionJob] Dispatch failed:", err instanceof Error ? err.message : err);
    }
  })();

  return { ok: true, jobId: newJobId, dispatchWarning: null };
}
