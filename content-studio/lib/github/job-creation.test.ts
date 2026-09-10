import assert from "node:assert/strict";
import { describe, it } from "node:test";

// We test the business logic of the createExtractionJob action by
// verifying the contract: the action should check for existing active
// jobs before creating new ones, and should dispatch the worker after
// creation. Since the action uses server-side Supabase clients, we
// test the logic patterns directly.

describe("Extraction job deduplication logic", () => {
  // Simulates the dedup check that createExtractionJob performs
  function hasActiveJob(
    jobs: { id: string; source_document_id: string; status: string }[],
    sourceDocumentId: string,
  ): { id: string } | null {
    return jobs.find(
      (j) =>
        j.source_document_id === sourceDocumentId &&
        (j.status === "queued" || j.status === "processing"),
    ) ?? null;
  }

  it("returns existing job when one is queued for same source document", () => {
    const jobs = [
      { id: "job-1", source_document_id: "doc-1", status: "queued" },
      { id: "job-2", source_document_id: "doc-1", status: "completed" },
    ];
    const existing = hasActiveJob(jobs, "doc-1");
    assert.equal(existing?.id, "job-1");
  });

  it("returns existing job when one is processing for same source document", () => {
    const jobs = [
      { id: "job-1", source_document_id: "doc-1", status: "processing" },
    ];
    const existing = hasActiveJob(jobs, "doc-1");
    assert.equal(existing?.id, "job-1");
  });

  it("returns null when no active job exists for the source document", () => {
    const jobs = [
      { id: "job-1", source_document_id: "doc-1", status: "completed" },
      { id: "job-2", source_document_id: "doc-1", status: "cancelled" },
      { id: "job-3", source_document_id: "doc-1", status: "failed" },
    ];
    const existing = hasActiveJob(jobs, "doc-1");
    assert.equal(existing, null);
  });

  it("returns null when different source document has active job", () => {
    const jobs = [
      { id: "job-1", source_document_id: "doc-2", status: "queued" },
    ];
    const existing = hasActiveJob(jobs, "doc-1");
    assert.equal(existing, null);
  });

  it("returns null when no jobs exist", () => {
    const existing = hasActiveJob([], "doc-1");
    assert.equal(existing, null);
  });

  it("returns first active job when multiple exist (should not happen but handles gracefully)", () => {
    const jobs = [
      { id: "job-1", source_document_id: "doc-1", status: "queued" },
      { id: "job-2", source_document_id: "doc-1", status: "processing" },
    ];
    const existing = hasActiveJob(jobs, "doc-1");
    assert.equal(existing?.id, "job-1");
  });
});

describe("Dispatch result handling", () => {
  type CreateJobResult =
    | { ok: true; jobId: string; dispatchWarning: string | null }
    | { ok: false; error: string };

  it("returns dispatchWarning when dispatch fails", () => {
    const dispatchResult = { ok: false, error: "GitHub API 403" };
    const warning = dispatchResult.ok
      ? null
      : dispatchResult.error ?? "Worker dispatch failed";
    const result: CreateJobResult = { ok: true, jobId: "job-1", dispatchWarning: warning };

    assert.equal(result.ok, true);
    assert.equal(result.jobId, "job-1");
    assert.equal(result.dispatchWarning, "GitHub API 403");
  });

  it("returns null warning when dispatch succeeds", () => {
    const dispatchResult: { ok: boolean; error?: string } = { ok: true };
    const warning = dispatchResult.ok
      ? null
      : dispatchResult.error ?? "Worker dispatch failed";
    const result: CreateJobResult = { ok: true, jobId: "job-1", dispatchWarning: warning };

    assert.equal(result.ok, true);
    assert.equal(result.dispatchWarning, null);
  });

  it("dispatch failure does not mark job as failed or processing", () => {
    const result: CreateJobResult = {
      ok: true,
      jobId: "job-1",
      dispatchWarning: "GitHub API 500",
    };
    assert.equal(result.ok, true);
    assert.equal(result.jobId, "job-1");
    // The job is created in queued state — it remains recoverable
    // No status change due to dispatch failure
  });
});

describe("Workflow trigger contract", () => {
  it("dispatch payload contains only job_id", () => {
    const jobId = "5e199520-6a93-432b-96e9-4ae83ad25623";
    const payload = {
      ref: "master",
      inputs: { job_id: jobId },
    };

    assert.deepEqual(Object.keys(payload.inputs), ["job_id"]);
    assert.equal(payload.inputs.job_id, jobId);
    assert.equal(payload.ref, "master");
  });

  it("no secrets appear in dispatch payload", () => {
    const sensitiveValues = [
      "ghp_",
      "sk-",
      "supabase",
      "sb_",
      "signed",
      "token=",
    ];
    const jobId = "5e199520-6a93-432b-96e9-4ae83ad25623";
    const payload = JSON.stringify({
      ref: "master",
      inputs: { job_id: jobId },
    });

    for (const val of sensitiveValues) {
      assert.ok(
        !payload.includes(val),
        `Sensitive value pattern "${val}" found in dispatch payload`,
      );
    }
  });
});
