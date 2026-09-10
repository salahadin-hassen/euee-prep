"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { PageSelectionError, parsePageSelection } from "@/lib/extraction/page-selection";
import {
  MAX_SOURCE_PDF_BYTES,
  prepareSourceDocumentUpload,
  registerSourceDocument,
} from "./_actions/source-document";
import { createExtractionJob } from "./_actions/job";

function formatBytes(bytes: number): string {
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

async function sha256(file: File): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", await file.arrayBuffer());
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function hasPdfSignature(file: File): Promise<boolean> {
  const bytes = new Uint8Array(await file.slice(0, 5).arrayBuffer());
  return new TextDecoder().decode(bytes) === "%PDF-";
}

export function ExtractionForm({ projectId }: { projectId: string }) {
  const router = useRouter();
  const [file, setFile] = useState<File | null>(null);
  const [pageInput, setPageInput] = useState("1");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function submit() {
    setError(null);
    if (!file) {
      setError("Choose a PDF first.");
      return;
    }

    let pages: number[];
    try {
      pages = parsePageSelection(pageInput);
    } catch (selectionError) {
      setError(selectionError instanceof PageSelectionError ? selectionError.message : "Invalid page selection.");
      return;
    }
    if (file.type !== "application/pdf" || !file.name.toLowerCase().endsWith(".pdf")) {
      setError("Only PDF files are allowed.");
      return;
    }
    if (file.size <= 0 || file.size > MAX_SOURCE_PDF_BYTES) {
      setError("PDF files must be smaller than 50 MB.");
      return;
    }
    if (!(await hasPdfSignature(file))) {
      setError("The file does not have a valid PDF signature.");
      return;
    }

    setPending(true);
    try {
      const prepared = await prepareSourceDocumentUpload(projectId, file.name, file.type, file.size);
      if (prepared.error || !prepared.documentId || !prepared.storagePath || !prepared.token) {
        setError(prepared.error ?? "Could not prepare the upload.");
        return;
      }

      const supabase = createClient();
      const { error: uploadError } = await supabase.storage
        .from("source-pdfs")
        .uploadToSignedUrl(prepared.storagePath, prepared.token, file);
      if (uploadError) {
        setError(`Upload failed: ${uploadError.message}`);
        return;
      }

      const registered = await registerSourceDocument({
        projectId,
        documentId: prepared.documentId,
        storagePath: prepared.storagePath,
        originalFilename: file.name,
        mimeType: file.type,
        byteSize: file.size,
        sha256: await sha256(file),
      });
      if (registered.error || !registered.documentId) {
        setError(registered.error ?? "Could not register the uploaded PDF.");
        return;
      }

      const job = await createExtractionJob(projectId, registered.documentId, pages);
      if (job.error) {
        setError(job.error);
        return;
      }

      setFile(null);
      router.refresh();
    } finally {
      setPending(false);
    }
  }

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Prepare extraction</h2>
      </div>
      <p className="empty" style={{ marginBottom: 16 }}>
        Upload a private exam PDF and choose the pages to process later. No extraction worker is connected yet.
      </p>
      <div className="form">
        <label>
          Source PDF
          <input
            type="file"
            accept="application/pdf,.pdf"
            onChange={(event) => setFile(event.target.files?.[0] ?? null)}
            disabled={pending}
          />
        </label>
        {file && <p className="project-meta">{file.name} · {formatBytes(file.size)}</p>}
        <label>
          Pages
          <input
            type="text"
            value={pageInput}
            onChange={(event) => setPageInput(event.target.value)}
            placeholder="e.g. 1,3,4-6"
            disabled={pending}
          />
        </label>
        <p className="project-meta">Use comma-separated pages and ranges. Pages must be positive and unique.</p>
        {error && <p className="error" role="alert">{error}</p>}
        <button className="button" type="button" onClick={submit} disabled={pending}>
          {pending ? "Uploading..." : "Upload and queue extraction"}
        </button>
      </div>
    </section>
  );
}
