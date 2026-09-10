"use server";

import { createClient } from "@/lib/supabase/server";
import { isAdminRole, type AppRole } from "@/lib/auth/roles";

export const MAX_SOURCE_PDF_BYTES = 50 * 1024 * 1024;

type ActionResult<T> = { error: string | null } & T;

async function authorizedForUpload(projectId: string) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { supabase, user: null, allowed: false };

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  const role = profile?.role as AppRole | undefined;
  if (role && isAdminRole(role)) return { supabase, user, allowed: true };

  const { data: membership } = await supabase
    .from("project_members")
    .select("role")
    .eq("project_id", projectId)
    .eq("user_id", user.id)
    .single();
  return { supabase, user, allowed: membership?.role === "uploader" };
}

export async function prepareSourceDocumentUpload(
  projectId: string,
  filename: string,
  mimeType: string,
  byteSize: number,
): Promise<ActionResult<{ documentId: string | null; storagePath: string | null; token: string | null }>> {
  const auth = await authorizedForUpload(projectId);
  if (!auth.user) return { error: "You must be signed in.", documentId: null, storagePath: null, token: null };
  if (!auth.allowed) return { error: "You cannot upload source documents for this paper.", documentId: null, storagePath: null, token: null };
  if (mimeType !== "application/pdf" || !filename.toLowerCase().endsWith(".pdf")) {
    return { error: "Only PDF files are allowed.", documentId: null, storagePath: null, token: null };
  }
  if (!Number.isSafeInteger(byteSize) || byteSize <= 0 || byteSize > MAX_SOURCE_PDF_BYTES) {
    return { error: "PDF files must be smaller than 50 MB.", documentId: null, storagePath: null, token: null };
  }

  const documentId = crypto.randomUUID();
  const storagePath = `${projectId}/${documentId}/source.pdf`;
  const { data, error } = await auth.supabase.storage
    .from("source-pdfs")
    .createSignedUploadUrl(storagePath);
  if (error || !data?.token) {
    return { error: `Could not prepare upload: ${error?.message ?? "No upload token returned."}`, documentId: null, storagePath: null, token: null };
  }

  return { error: null, documentId, storagePath, token: data.token };
}

export async function registerSourceDocument(input: {
  projectId: string;
  documentId: string;
  storagePath: string;
  originalFilename: string;
  mimeType: string;
  byteSize: number;
  sha256: string;
}): Promise<ActionResult<{ documentId: string | null }>> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", documentId: null };

  const { data, error } = await supabase.rpc("create_source_document", {
    p_project_id: input.projectId,
    p_document_id: input.documentId,
    p_storage_path: input.storagePath,
    p_original_filename: input.originalFilename,
    p_mime_type: input.mimeType,
    p_byte_size: input.byteSize,
    p_sha256: input.sha256,
  });
  if (error) return { error: `Could not register PDF: ${error.message}`, documentId: null };
  return { error: null, documentId: data as string };
}
