"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { cancelExtractionJob } from "./_actions/job";

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

export function JobStatus({ projectId, job, sourceName }: { projectId: string; job: Job; sourceName: string }) {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function cancel() {
    setError(null);
    setPending(true);
    const result = await cancelExtractionJob(projectId, job.id);
    setPending(false);
    if (result.error) setError(result.error);
    else router.refresh();
  }

  const statusMessage: Record<string, string> = {
    queued: "Waiting for the extraction worker.",
    processing: "The worker is processing selected pages.",
    completed: "All selected pages completed.",
    completed_with_errors: "Completed with one or more page errors.",
    quota_exhausted: "AI provider quota was exhausted. Completed pages are preserved.",
    failed: "The extraction failed. Completed pages are preserved where available.",
    cancelled: "This extraction was cancelled.",
  };

  return (
    <article className="project-row" style={{ display: "block" }}>
      <div className="panel-head">
        <div>
          <div className="project-title">{sourceName}</div>
          <div className="project-meta">Job {job.id}</div>
        </div>
        <span className="badge">{job.status}</span>
      </div>
      <div className="project-meta">
        Requested pages: {job.requested_pages.join(", ")} · {job.completed_pages} completed · {job.failed_pages} failed
      </div>
      <div className="project-meta">{statusMessage[job.status] ?? "Status unavailable."}</div>
      <div className="project-meta">Created {new Date(job.created_at).toLocaleString()}</div>
      {(job.status === "queued" || job.status === "processing") && (
        <button className="signout" type="button" onClick={cancel} disabled={pending} style={{ marginTop: 10 }}>
          {pending ? "Cancelling..." : "Cancel queued job"}
        </button>
      )}
      {error && <p className="error" role="alert">{error}</p>}
    </article>
  );
}
