"use client";

import { useCallback, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import {
  MAX_SOURCE_PDF_BYTES,
  prepareSourceDocumentUpload,
  registerSourceDocument,
} from "./extract/_actions/source-document";
import { createExtractionJob, cancelExtractionJob, retryExtractionJob } from "./extract/_actions/job";

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

function ExtractionJobRow({
  job,
  projectId,
  canCancel,
  cancellingId,
  onCancel,
  onRetry,
  retryingId,
}: {
  job: Job;
  projectId: string;
  canCancel: boolean;
  cancellingId: string | null;
  onCancel: (jobId: string) => void;
  onRetry: (jobId: string) => void;
  retryingId: string | null;
}) {
  const isActive = job.status === "queued" || job.status === "processing";
  const isComplete = job.status === "completed";
  const hasIssues = job.status === "completed_with_errors";
  const isFailed = job.status === "failed" || job.status === "quota_exhausted";

  const totalPages = job.requested_pages.length;

  return (
    <div className="extraction-job">
      {isActive && (
        <div className="extraction-status extraction-processing">
          <span className="extraction-icon" aria-hidden="true">{"\u25CC"}</span>
          <div>
            <div className="extraction-status-text">Processing</div>
            <div className="extraction-status-detail">
              {job.completed_pages} / {totalPages} pages
              {job.failed_pages > 0 && <>, {job.failed_pages} failed</>}
            </div>
          </div>
        </div>
      )}

      {isComplete && (
        <div className="extraction-status extraction-complete">
          <span className="extraction-icon" aria-hidden="true">{"\u2713"}</span>
          <div>
            <div className="extraction-status-text">Ready for review</div>
            <div className="extraction-status-detail">
              All {totalPages} page{totalPages !== 1 ? "s" : ""} extracted
            </div>
          </div>
          <a className="button button-sm" href={`/projects/${projectId}/review`}>
            Review questions {"\u2192"}
          </a>
        </div>
      )}

      {hasIssues && (
        <div className="extraction-status extraction-issues">
          <span className="extraction-icon" aria-hidden="true">{"\u26A0"}</span>
          <div>
            <div className="extraction-status-text">Completed with issues</div>
            <div className="extraction-status-detail">
              {job.completed_pages} of {totalPages} pages succeeded, {job.failed_pages} failed
            </div>
          </div>
          <a className="button button-sm" href={`/projects/${projectId}/review`}>
            Review questions
          </a>
        </div>
      )}

      {isFailed && (
        <div className="extraction-status extraction-failed">
          <span className="extraction-icon" aria-hidden="true">{"\u2717"}</span>
          <div>
              <div className="extraction-status-text">{job.status === "quota_exhausted" ? "Extraction paused" : "Extraction failed"}</div>
              <div className="extraction-status-detail">
              {job.status === "quota_exhausted" ? "The AI quota was exhausted before the paper finished." : "We couldn&apos;t finish processing this paper."}
            </div>
          </div>
          {canCancel && (
            <button
              className="button button-sm"
              type="button"
              onClick={() => onRetry(job.id)}
              disabled={retryingId === job.id}
            >
              {retryingId === job.id ? "Retrying\u2026" : "Retry extraction"}
            </button>
          )}
        </div>
      )}

      {job.status === "queued" && (
        <div className="extraction-status extraction-queued">
          <span className="extraction-icon" aria-hidden="true">{"\u25CB"}</span>
          <div>
            <div className="extraction-status-text">Queued</div>
            <div className="extraction-status-detail">
              Waiting to start...
            </div>
          </div>
        </div>
      )}

      {(job.status === "cancelled") && (
        <div className="extraction-status extraction-cancelled">
          <span className="extraction-icon" aria-hidden="true">{"\u2716"}</span>
          <div>
            <div className="extraction-status-text">Cancelled</div>
          </div>
          {canCancel && (
            <button
              className="button button-sm"
              type="button"
              onClick={() => onRetry(job.id)}
              disabled={retryingId === job.id}
            >
              {retryingId === job.id ? "Retrying\u2026" : "Retry extraction"}
            </button>
          )}
        </div>
      )}

      {isActive && canCancel && (
        <button
          className="signout"
          type="button"
          onClick={() => onCancel(job.id)}
          disabled={cancellingId === job.id}
        >
          {cancellingId === job.id ? "Cancelling..." : "Cancel"}
        </button>
      )}
    </div>
  );
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
  const [dispatchWarning, setDispatchWarning] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const [cancellingId, setCancellingId] = useState<string | null>(null);
  const [retryingId, setRetryingId] = useState<string | null>(null);

  const onFileChange = useCallback(async (event: React.ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0] ?? null;
    setFile(selected);
    setDetectedPages(null);
    setError(null);
    setSuccess(null);
    setDispatchWarning(null);
    if (selected && selected.type === "application/pdf") {
      const count = await detectPdfPageCount(selected);
      if (count && count > 0) {
        setDetectedPages(count);
      } else {
        setError("We couldn't read the PDF page count. Choose a valid, readable PDF and try again.");
      }
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

    if (!detectedPages) {
      setError("Wait for the PDF page count before starting extraction.");
      return;
    }

    const pages = Array.from({ length: detectedPages }, (_, i) => i + 1);

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
      setSuccess("Extraction started");
      setDispatchWarning(job.dispatchWarning);
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

  async function retry(jobId: string) {
    setRetryingId(jobId);
    const result = await retryExtractionJob(projectId, jobId);
    if (!result.ok && result.error) {
      setError(result.error);
    }
    router.refresh();
    setRetryingId(null);
  }

  const activeJobs = jobs.filter((j) => j.status === "queued" || j.status === "processing");
  const hasActiveJobs = activeJobs.length > 0;

  useEffect(() => {
    if (!hasActiveJobs) return;
    const interval = window.setInterval(() => router.refresh(), 5000);
    return () => window.clearInterval(interval);
  }, [hasActiveJobs, router]);

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
              {detectedPages ? ` \u00B7 ${detectedPages} page${detectedPages !== 1 ? "s" : ""}` : ""}
            </p>
          )}
          {error && <p className="error" role="alert">{error}</p>}
          {dispatchWarning && (
            <p className="error" role="alert">
              Extraction is queued, but the worker could not be dispatched. It will be picked up by recovery: {dispatchWarning}
            </p>
          )}
          {success && (
            <p className="success" role="status">
              {"\u2713"} {success}
            </p>
          )}
          <button className="button" type="button" onClick={submit} disabled={pending}>
            {pending ? "\u25CC Starting extraction\u2026" : detectedPages ? "Extract paper" : "Extract paper"}
          </button>
        </div>
      )}

      {hasActiveJobs && (
        <p className="project-meta extraction-hint" style={{ marginTop: 12 }}>
          Processing in the background. You can leave this page.
        </p>
      )}

      {jobs.length > 0 && (
        <div className="extraction-jobs">
          {jobs.map((job) => (
            <ExtractionJobRow
              key={job.id}
              job={job}
              projectId={projectId}
              canCancel={canUpload}
              cancellingId={cancellingId}
              onCancel={cancel}
              onRetry={retry}
              retryingId={retryingId}
            />
          ))}
        </div>
      )}
    </section>
  );
}
