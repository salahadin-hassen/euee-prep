"use server";

import { createClient } from "@/lib/supabase/server";
import { isAdminRole, type AppRole } from "@/lib/auth/roles";

export const MAX_SOURCE_PDF_BYTES = 50 * 1024 * 1024;

type ActionResult<T> = { error: string | null } & T;

async function authorizedForUpload(projectId: string) {
  const t0 = Date.now();
  const supabase = await createClient();
  console.log(`[EXTRACT:createClient] ${Date.now() - t0}ms`);
  const t1 = Date.now();
  const { data: { user } } = await supabase.auth.getUser();
  console.log(`[EXTRACT:getUser] ${Date.now() - t1}ms`);
  if (!user) return { supabase, user: null, allowed: false };

  const t2 = Date.now();
  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  console.log(`[EXTRACT:profileQuery] ${Date.now() - t2}ms`);
  const role = profile?.role as AppRole | undefined;
  if (role && isAdminRole(role)) return { supabase, user, allowed: true };

  const t3 = Date.now();
  const { data: membership } = await supabase
    .from("project_members")
    .select("role")
    .eq("project_id", projectId)
    .eq("user_id", user.id)
    .single();
  console.log(`[EXTRACT:membershipQuery] ${Date.now() - t3}ms`);
  return { supabase, user, allowed: membership?.role === "uploader" };
}

export async function prepareSourceDocumentUpload(
  projectId: string,
  filename: string,
  mimeType: string,
  byteSize: number,
): Promise<ActionResult<{ documentId: string | null; storagePath: string | null; token: string | null }>> {
  console.log(`[EXTRACT:prepareSourceDocumentUpload] START filename=${filename} size=${byteSize}`);
  const auth = await authorizedForUpload(projectId);
  if (!auth.user) { console.log(`[EXTRACT:prepareSourceDocumentUpload] NO_USER`); return { error: "You must be signed in.", documentId: null, storagePath: null, token: null }; }
  if (!auth.allowed) { console.log(`[EXTRACT:prepareSourceDocumentUpload] NOT_ALLOWED`); return { error: "You cannot upload source documents for this paper.", documentId: null, storagePath: null, token: null }; }
  if (mimeType !== "application/pdf" || !filename.toLowerCase().endsWith(".pdf")) {
    console.log(`[EXTRACT:prepareSourceDocumentUpload] BAD_MIME`);
    return { error: "Only PDF files are allowed.", documentId: null, storagePath: null, token: null };
  }
  if (!Number.isSafeInteger(byteSize) || byteSize <= 0 || byteSize > MAX_SOURCE_PDF_BYTES) {
    console.log(`[EXTRACT:prepareSourceDocumentUpload] BAD_SIZE`);
    return { error: "PDF files must be smaller than 50 MB.", documentId: null, storagePath: null, token: null };
  }

  const documentId = crypto.randomUUID();
  const storagePath = `${projectId}/${documentId}/source.pdf`;
  const t4 = Date.now();
  const { data, error } = await auth.supabase.storage
    .from("source-pdfs")
    .createSignedUploadUrl(storagePath);
  console.log(`[EXTRACT:createSignedUploadUrl] ${Date.now() - t4}ms`);
  if (error || !data?.token) {
    console.error(`[EXTRACT:prepareSourceDocumentUpload] SIGN_URL_ERROR: ${error?.message}`);
    return { error: `Could not prepare upload: ${error?.message ?? "No upload token returned."}`, documentId: null, storagePath: null, token: null };
  }

  console.log(`[EXTRACT:prepareSourceDocumentUpload] DONE ${Date.now() - t4}ms`);
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
  console.log(`[EXTRACT:registerSourceDocument] START docId=${input.documentId}`);
  const t0 = Date.now();
  const supabase = await createClient();
  console.log(`[EXTRACT:registerSourceDocument:createClient] ${Date.now() - t0}ms`);
  const t1 = Date.now();
  const { data: { user } } = await supabase.auth.getUser();
  console.log(`[EXTRACT:registerSourceDocument:getUser] ${Date.now() - t1}ms`);
  if (!user) return { error: "You must be signed in.", documentId: null };

  const t2 = Date.now();
  const { data, error } = await supabase.rpc("create_source_document", {
    p_project_id: input.projectId,
    p_document_id: input.documentId,
    p_storage_path: input.storagePath,
    p_original_filename: input.originalFilename,
    p_mime_type: input.mimeType,
    p_byte_size: input.byteSize,
    p_sha256: input.sha256,
  });
  console.log(`[EXTRACT:registerSourceDocument:rpc] ${Date.now() - t2}ms`);
  if (error) { console.error(`[EXTRACT:registerSourceDocument] RPC_ERROR: ${error.message}`); return { error: `Could not register PDF: ${error.message}`, documentId: null }; }
  console.log(`[EXTRACT:registerSourceDocument] DONE`);
  return { error: null, documentId: data as string };
}
