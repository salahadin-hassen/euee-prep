"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import {
  MAX_SOURCE_PDF_BYTES,
  prepareSourceDocumentUpload,
  registerSourceDocument,
} from "./extract/_actions/source-document";
import { createExtractionJob, cancelExtractionJob } from "./extract/_actions/job";

function formatBytes(bytes: number): string {
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

async function sha256Hex(file: File): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", await file.arrayBuffer());
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function hasPdfSignature(file: File): Promise<boolean> {
  const bytes = new Uint8Array(await file.slice(0, 5).arrayBuffer());
  return new TextDecoder().decode(bytes) === "%PDF-";
}

async function detectPdfPageCount(file: File): Promise<number | null> {
  try {
    const pdfjsLib = await import("pdfjs-dist");
    pdfjsLib.GlobalWorkerOptions.workerSrc = "";
    const buffer = await file.arrayBuffer();
    const doc = await pdfjsLib.getDocument({ data: buffer, useSystemFonts: true }).promise;
    const count = doc.numPages;
    doc.destroy();
    return count;
  } catch {
    return null;
  }
}

const JOB_LABELS: Record<string, string> = {
  queued: "Queued",
  processing: "Processing",
  completed: "Done",
  completed_with_errors: "Done (some errors)",
  quota_exhausted: "Quota exhausted",
  failed: "Failed",
  cancelled: "Cancelled",
};

interface Job {
  id: string;
  source_document_id: string;
  requested_pages: number[];
  status: string;
  total_pages: number;
  completed_pages: number;
  failed_pages: number;
  created_at: string;
  completed_at: string | null;
}

export function InlineExtraction({
  projectId,
  jobs,
  canUpload,
}: {
  projectId: string;
  jobs: Job[];
  canUpload: boolean;
}) {
  const router = useRouter();
  const [file, setFile] = useState<File | null>(null);
  const [detectedPages, setDetectedPages] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const [cancellingId, setCancellingId] = useState<string | null>(null);

  const onFileChange = useCallback(async (event: React.ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0] ?? null;
    setFile(selected);
    setDetectedPages(null);
    setError(null);
    setSuccess(null);
    if (selected && selected.type === "application/pdf") {
      const count = await detectPdfPageCount(selected);
      if (count && count > 0) setDetectedPages(count);
    }
  }, []);

  async function submit() {
    setError(null);
    setSuccess(null);
    if (!file) {
      setError("Choose a PDF first.");
      return;
    }
    if (file.type !== "application/pdf" || !file.name.toLowerCase().endsWith(".pdf")) {
      setError("Only PDF files are allowed.");
      return;
    }
    if (file.size <= 0 || file.size > MAX_SOURCE_PDF_BYTES) {
      setError("PDF must be under 50 MB.");
      return;
    }
    if (!(await hasPdfSignature(file))) {
      setError("File is not a valid PDF.");
      return;
    }

    const pages = detectedPages ? Array.from({ length: detectedPages }, (_, i) => i + 1) : [1];

    setPending(true);
    try {
      const prepared = await prepareSourceDocumentUpload(projectId, file.name, file.type, file.size);
      if (prepared.error || !prepared.documentId || !prepared.storagePath || !prepared.token) {
        setError(prepared.error ?? "Could not prepare upload.");
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
        sha256: await sha256Hex(file),
      });
      if (registered.error || !registered.documentId) {
        setError(registered.error ?? "Could not register PDF.");
        return;
      }

      const job = await createExtractionJob(projectId, registered.documentId, pages);
      if (!job.ok) {
        setError(job.error);
        return;
      }

      setFile(null);
      setDetectedPages(null);
      setSuccess("Extraction started. The worker will process it automatically.");
      router.refresh();
    } finally {
      setPending(false);
    }
  }

  async function cancel(jobId: string) {
    setCancellingId(jobId);
    const result = await cancelExtractionJob(projectId, jobId);
    if (!result.error) router.refresh();
    setCancellingId(null);
  }

  const activeJobs = jobs.filter((j) => j.status === "queued" || j.status === "processing");

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Extraction</h2>
      </div>

      {canUpload && (
        <div className="form">
          <label>
            Upload PDF
            <input
              type="file"
              accept="application/pdf,.pdf"
              onChange={onFileChange}
              disabled={pending}
            />
          </label>
          {file && (
            <p className="project-meta">
              {file.name} &middot; {formatBytes(file.size)}
              {detectedPages ? ` · ${detectedPages} page${detectedPages !== 1 ? "s" : ""}` : ""}
            </p>
          )}
          {error && <p className="error" role="alert">{error}</p>}
          {success && <p className="success" role="status">{success}</p>}
          <button className="button" type="button" onClick={submit} disabled={pending}>
            {pending ? "Starting…" : detectedPages ? `Extract ${detectedPages} page${detectedPages !== 1 ? "s" : ""}` : "Extract"}
          </button>
        </div>
      )}

      {activeJobs.length > 0 && (
        <p className="project-meta" style={{ marginTop: 12 }}>
          Processing in background — you can leave this page.
        </p>
      )}

      {jobs.length > 0 && (
        <div style={{ marginTop: 12 }}>
          {jobs.map((job) => (
            <div key={job.id} className="project-row">
              <div>
                <div className="project-meta">
                  Pages {job.requested_pages.join(", ")} &middot; {job.completed_pages}/{job.requested_pages.length}
                  {job.failed_pages > 0 && <>, {job.failed_pages} failed</>}
                </div>
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span className="badge">{JOB_LABELS[job.status] ?? job.status}</span>
                {(job.status === "queued" || job.status === "processing") && (
                  <button
                    className="signout"
                    type="button"
                    onClick={() => cancel(job.id)}
                    disabled={cancellingId === job.id}
                  >
                    {cancellingId === job.id ? "…" : "Cancel"}
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </section>
  );
}
