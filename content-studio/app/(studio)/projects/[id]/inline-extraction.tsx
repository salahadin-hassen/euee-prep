"use client";

import { useCallback, useEffect, useRef, useState } from "react";
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

async function detectPdfPageCount(file: File): Promise<number> {
  const pdfjsLib = await import("pdfjs-dist");
  pdfjsLib.GlobalWorkerOptions.workerSrc = "/pdf.worker.min.mjs";
  const data = new Uint8Array(await file.arrayBuffer());
  const doc = await pdfjsLib.getDocument({ data, useSystemFonts: true }).promise;
  const count = doc.numPages;
  doc.destroy();
  return count;
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
  const [detectionState, setDetectionState] = useState<"idle" | "detecting" | "success" | "error">("idle");
  const [detectionError, setDetectionError] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [dispatchWarning, setDispatchWarning] = useState<string | null>(null);
  const [pending, setPending] = useState(false);
  const [cancellingId, setCancellingId] = useState<string | null>(null);
  const [retryingId, setRetryingId] = useState<string | null>(null);
  const detectionTokenRef = useRef(0);

  const detectPages = useCallback(async (fileToDetect: File) => {
    const token = ++detectionTokenRef.current;
    setDetectionState("detecting");
    setDetectedPages(null);
    setDetectionError(null);
    setError(null);
    try {
      const count = await detectPdfPageCount(fileToDetect);
      if (token !== detectionTokenRef.current) return;
      setDetectedPages(count);
      setDetectionState("success");
    } catch (err) {
      if (token !== detectionTokenRef.current) return;
      console.error("[InlineExtraction] PDF page detection failed:", err instanceof Error ? err.message : err);
      setDetectedPages(null);
      setDetectionState("error");
      setDetectionError("We couldn\u2019t determine the number of pages. No extraction was started.");
    }
  }, []);

  const onFileChange = useCallback(async (event: React.ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0] ?? null;
    setFile(selected);
    setSuccess(null);
    setDispatchWarning(null);
    setError(null);
    if (selected && selected.type === "application/pdf") {
      await detectPages(selected);
    } else {
      setDetectionState("idle");
      setDetectedPages(null);
      setDetectionError(null);
    }
  }, [detectPages]);

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

    if (detectionState !== "success" || !detectedPages || detectedPages <= 0) {
      return;
    }

    const pages = Array.from({ length: detectedPages }, (_, i) => i + 1);

    setPending(true);
    try {
      console.log("[EXTRACT_CLIENT] PREPARE_START");
      const prepared = await prepareSourceDocumentUpload(projectId, file.name, file.type, file.size);
      console.log("[EXTRACT_CLIENT] PREPARE_DONE", prepared.error ? `ERROR: ${prepared.error}` : "ok");
      if (prepared.error || !prepared.documentId || !prepared.storagePath || !prepared.token) {
        setError(prepared.error ?? "Could not prepare upload.");
        return;
      }

      const supabase = createClient();
      console.log("[EXTRACT_CLIENT] UPLOAD_START");
      const { error: uploadError } = await supabase.storage
        .from("source-pdfs")
        .uploadToSignedUrl(prepared.storagePath, prepared.token, file);
      console.log("[EXTRACT_CLIENT] UPLOAD_DONE", uploadError ? `ERROR: ${uploadError.message}` : "ok");
      if (uploadError) {
        setError(`Upload failed: ${uploadError.message}`);
        return;
      }

      console.log("[EXTRACT_CLIENT] HASH_START");
      const hash = await sha256Hex(file);
      console.log("[EXTRACT_CLIENT] HASH_DONE");

      console.log("[EXTRACT_CLIENT] REGISTER_START");
      const registered = await registerSourceDocument({
        projectId,
        documentId: prepared.documentId,
        storagePath: prepared.storagePath,
        originalFilename: file.name,
        mimeType: file.type,
        byteSize: file.size,
        sha256: hash,
      });
      console.log("[EXTRACT_CLIENT] REGISTER_DONE", registered.error ? `ERROR: ${registered.error}` : "ok");
      if (registered.error || !registered.documentId) {
        setError(registered.error ?? "Could not register PDF.");
        return;
      }

      console.log("[EXTRACT_CLIENT] JOB_START");
      const job = await createExtractionJob(projectId, registered.documentId, pages);
      console.log("[EXTRACT_CLIENT] JOB_DONE", job.ok ? `jobId=${job.jobId}` : `ERROR: ${job.error}`);
      if (!job.ok) {
        setError(job.error);
        return;
      }

      console.log("[EXTRACT_CLIENT] SETTING_SUCCESS");
      setFile(null);
      setDetectedPages(null);
      setSuccess("Extraction started");
      setDispatchWarning(job.dispatchWarning);
      console.log("[EXTRACT_CLIENT] REFRESHING");
      router.refresh();
      console.log("[EXTRACT_CLIENT] REFRESH_DONE");
    } finally {
      console.log("[EXTRACT_CLIENT] FINALLY setPending(false)");
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
            </p>
          )}
          {detectionState === "detecting" && (
            <p className="project-meta" role="status">
              {"\u25CC"} Checking PDF pages\u2026
            </p>
          )}
          {detectionState === "success" && detectedPages && (
            <p className="project-meta" role="status">
              {"\u2713"} {detectedPages} page{detectedPages !== 1 ? "s" : ""} detected
            </p>
          )}
          {detectionState === "error" && (
            <div className="error" role="alert">
              <p>{"\u26A0"} Couldn{"\u2019"}t read this PDF</p>
              <p>{detectionError}</p>
              <button className="button button-sm" type="button" onClick={() => file && detectPages(file)}>
                Try again
              </button>
            </div>
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
          <button
            className="button"
            type="button"
            onClick={submit}
            disabled={pending || detectionState !== "success"}
          >
            {pending ? "\u25CC Starting extraction\u2026" : "Extract paper"}
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
