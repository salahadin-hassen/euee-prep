import assert from "node:assert/strict";
import { createHash, randomUUID } from "node:crypto";
import { describe, it, before, after } from "node:test";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.TEST_SUPABASE_URL;
const SERVICE_KEY = process.env.TEST_SUPABASE_SERVICE_KEY;
const PUBLISHABLE_KEY = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const enabled = !!(SUPABASE_URL && SERVICE_KEY && PUBLISHABLE_KEY);

describe("M2 worker claim and staging integration", { skip: !enabled ? "Missing disposable test Supabase environment" : false }, () => {
  let service: SupabaseClient;
  let userClient: SupabaseClient;
  let userId = "";
  let projectId = "";
  let documentId = "";
  let storagePath = "";
  const jobIds: string[] = [];

  before(async () => {
    service = createClient(SUPABASE_URL!, SERVICE_KEY!);
    const email = `m2-worker-${Date.now()}@integration.test`;
    const password = "TestPassword123!";
    const created = await service.auth.admin.createUser({ email, password, email_confirm: true });
    assert.equal(created.error, null, created.error?.message);
    userId = created.data.user!.id;
    await service.from("profiles").upsert({ id: userId, role: "admin", display_name: "Worker Test Admin" });
    userClient = createClient(SUPABASE_URL!, PUBLISHABLE_KEY!);
    assert.equal((await userClient.auth.signInWithPassword({ email, password })).error, null);

    const project = await userClient.rpc("create_project", {
      p_title: "M2 Worker Test", p_exam_year: 2025, p_subject: "Physics", p_stream: "natural_science",
    });
    assert.equal(project.error, null, project.error?.message);
    projectId = project.data as string;

    documentId = randomUUID();
    storagePath = `${projectId}/${documentId}/source.pdf`;
    const pdf = Buffer.from("%PDF-1.4\nworker test\n", "ascii");
    const signed = await userClient.storage.from("source-pdfs").createSignedUploadUrl(storagePath);
    assert.equal(signed.error, null, signed.error?.message);
    const uploaded = await userClient.storage.from("source-pdfs").uploadToSignedUrl(storagePath, signed.data!.token, new Blob([pdf], { type: "application/pdf" }));
    assert.equal(uploaded.error, null, uploaded.error?.message);
    const registered = await userClient.rpc("create_source_document", {
      p_project_id: projectId, p_document_id: documentId, p_storage_path: storagePath,
      p_original_filename: "worker.pdf", p_mime_type: "application/pdf", p_byte_size: pdf.length,
      p_sha256: createHash("sha256").update(pdf).digest("hex"),
    });
    assert.equal(registered.error, null, registered.error?.message);
  });

  after(async () => {
    if (storagePath) await service.storage.from("source-pdfs").remove([storagePath]);
    if (projectId) {
      await service.from("audit_events").delete().eq("entity_id", projectId);
      for (const jobId of jobIds) await service.from("audit_events").delete().eq("entity_id", jobId);
      await service.from("projects").delete().eq("id", projectId);
    }
    if (userId) await service.auth.admin.deleteUser(userId);
  });

  it("atomically claims, reclaims, stages idempotently, and completes a job", async () => {
    const created = await userClient.rpc("create_extraction_job", {
      p_project_id: projectId, p_source_document_id: documentId, p_requested_pages: [1],
    });
    assert.equal(created.error, null, created.error?.message);
    const jobId = created.data as string;
    jobIds.push(jobId);

    const firstClaim = await service.rpc("claim_extraction_job", { p_job_id: jobId, p_worker_id: "worker-a", p_lease_seconds: 60 });
    assert.equal(firstClaim.error, null, firstClaim.error?.message);
    const secondClaim = await service.rpc("claim_extraction_job", { p_job_id: jobId, p_worker_id: "worker-b", p_lease_seconds: 60 });
    assert.ok(secondClaim.error, "A live lease must prevent a second claim");

    await service.from("extraction_jobs").update({ lease_expires_at: new Date(0).toISOString() }).eq("id", jobId);
    const reclaimed = await service.rpc("claim_extraction_job", { p_job_id: jobId, p_worker_id: "worker-b", p_lease_seconds: 60 });
    assert.equal(reclaimed.error, null, reclaimed.error?.message);

    const started = await service.rpc("record_extraction_page_started", { p_job_id: jobId, p_pdf_page: 1, p_worker_id: "worker-b" });
    assert.equal(started.error, null, started.error?.message);
    const hash = "sha256:" + "c".repeat(64);
    const result = {
      result_schema_version: "1",
      job: { protocol_version: "1", job_id: jobId, project_id: projectId, source_document_id: documentId, requested_pages: [1], pipeline_version: "test", result_schema_version: "1" },
      source: { source_document_id: documentId, source_pdf_sha256: "a".repeat(64), pipeline_version: "test", extraction_options: {} },
      source_page: 1,
      status: "completed",
      questions: [{
        id: `${jobId}:page-001:question-001`, source_page: 1, question_number: 1, prompt: "Test prompt", choices: ["A", "B", "C", "D"],
        source_region: { x: 0.1, y: 0.1, width: 0.8, height: 0.2 }, uncertainties: [],
        ai_answer: { predicted_choice_index: 2, confidence: "high", reasoning: "test", answer_basis: "ai_solution" },
        verification: { status: "needs_review", findings: [] }, visual_assets: [],
      }],
    };
    const recorded = await service.rpc("record_extraction_page_result", {
      p_job_id: jobId, p_pdf_page: 1, p_worker_id: "worker-b", p_result: result,
      p_result_checksum: hash, p_result_schema_version: "1",
    });
    assert.equal(recorded.error, null, recorded.error?.message);
    const duplicate = await service.rpc("record_extraction_page_result", {
      p_job_id: jobId, p_pdf_page: 1, p_worker_id: "worker-b", p_result: result,
      p_result_checksum: hash, p_result_schema_version: "1",
    });
    assert.equal(duplicate.error, null, duplicate.error?.message);

    const completed = await service.rpc("complete_extraction_job", { p_job_id: jobId, p_worker_id: "worker-b" });
    assert.equal(completed.data, "completed");
    const { data: staged } = await service.from("extraction_questions").select("question_number, ai_predicted_choice_index, imported_question_id").eq("job_page_id", (await service.from("extraction_job_pages").select("id").eq("job_id", jobId).single()).data!.id);
    assert.deepEqual(staged, [{ question_number: 1, ai_predicted_choice_index: 2, imported_question_id: null }]);
    const { data: productionQuestions } = await service.from("questions").select("id").eq("project_id", projectId);
    assert.deepEqual(productionQuestions, []);
  });

  it("rejects unauthorized worker calls and persists quota exhaustion", async () => {
    const unauthorized = await userClient.rpc("claim_extraction_job", { p_job_id: randomUUID(), p_worker_id: "browser", p_lease_seconds: 60 });
    assert.ok(unauthorized.error, "Browser clients must not claim jobs");

    const created = await userClient.rpc("create_extraction_job", {
      p_project_id: projectId, p_source_document_id: documentId, p_requested_pages: [2],
    });
    assert.equal(created.error, null, created.error?.message);
    const jobId = created.data as string;
    jobIds.push(jobId);
    assert.equal((await service.rpc("claim_extraction_job", { p_job_id: jobId, p_worker_id: "worker-c", p_lease_seconds: 60 })).error, null);
    assert.equal((await service.rpc("record_extraction_page_started", { p_job_id: jobId, p_pdf_page: 2, p_worker_id: "worker-c" })).error, null);
    assert.equal((await service.rpc("record_extraction_page_failure", { p_job_id: jobId, p_pdf_page: 2, p_worker_id: "worker-c", p_status: "quota_exhausted", p_error: "Gemini quota exhausted", p_result_schema_version: "1" })).error, null);
    const completed = await service.rpc("complete_extraction_job", { p_job_id: jobId, p_worker_id: "worker-c" });
    assert.equal(completed.data, "quota_exhausted");
  });
});
