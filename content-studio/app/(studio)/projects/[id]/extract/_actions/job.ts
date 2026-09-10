"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";

export async function createExtractionJob(
  projectId: string,
  sourceDocumentId: string,
  requestedPages: number[],
): Promise<{ error: string | null; jobId: string | null }> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", jobId: null };

  const { data, error } = await supabase.rpc("create_extraction_job", {
    p_project_id: projectId,
    p_source_document_id: sourceDocumentId,
    p_requested_pages: requestedPages,
  });
  if (error) return { error: `Could not create extraction job: ${error.message}`, jobId: null };
  revalidatePath(`/projects/${projectId}`);
  revalidatePath(`/projects/${projectId}/extract`);
  return { error: null, jobId: data as string };
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
