import assert from "node:assert/strict";
import { createHash, randomUUID } from "node:crypto";
import { describe, it, before, after } from "node:test";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.TEST_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.TEST_SUPABASE_SERVICE_KEY;
const SUPABASE_PUBLISHABLE_KEY = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const hasEnv = !!(SUPABASE_URL && SUPABASE_SERVICE_KEY && SUPABASE_PUBLISHABLE_KEY);

describe("M2 source upload and queued extraction integration", { skip: !hasEnv ? "Missing disposable test Supabase environment" : false }, () => {
  let serviceClient: SupabaseClient;
  let adminClient: SupabaseClient;
  let outsiderClient: SupabaseClient;
  let adminUserId = "";
  let outsiderUserId = "";
  let projectId = "";
  let documentId = "";
  let jobId = "";
  let storagePath = "";

  before(async () => {
    serviceClient = createClient(SUPABASE_URL!, SUPABASE_SERVICE_KEY!);
    const password = "TestPassword123!";
    const suffix = Date.now();
    const adminAuth = await serviceClient.auth.admin.createUser({
      email: `m2-admin-${suffix}@integration.test`, password, email_confirm: true,
    });
    assert.equal(adminAuth.error, null, adminAuth.error?.message);
    adminUserId = adminAuth.data.user!.id;
    await serviceClient.from("profiles").upsert({ id: adminUserId, role: "admin", display_name: "M2 Admin" });

    const outsiderAuth = await serviceClient.auth.admin.createUser({
      email: `m2-outsider-${suffix}@integration.test`, password, email_confirm: true,
    });
    assert.equal(outsiderAuth.error, null, outsiderAuth.error?.message);
    outsiderUserId = outsiderAuth.data.user!.id;
    await serviceClient.from("profiles").upsert({ id: outsiderUserId, role: "reviewer", display_name: "M2 Outsider" });

    adminClient = createClient(SUPABASE_URL!, SUPABASE_PUBLISHABLE_KEY!);
    outsiderClient = createClient(SUPABASE_URL!, SUPABASE_PUBLISHABLE_KEY!);
    assert.equal((await adminClient.auth.signInWithPassword({ email: `m2-admin-${suffix}@integration.test`, password })).error, null);
    assert.equal((await outsiderClient.auth.signInWithPassword({ email: `m2-outsider-${suffix}@integration.test`, password })).error, null);
  });

  after(async () => {
    if (storagePath) await serviceClient.storage.from("source-pdfs").remove([storagePath]);
    if (jobId) await serviceClient.from("audit_events").delete().eq("entity_id", jobId);
    if (documentId) await serviceClient.from("audit_events").delete().eq("entity_id", documentId);
    if (projectId) {
      await serviceClient.from("audit_events").delete().eq("entity_id", projectId);
      await serviceClient.from("projects").delete().eq("id", projectId);
    }
    if (adminUserId) await serviceClient.auth.admin.deleteUser(adminUserId);
    if (outsiderUserId) await serviceClient.auth.admin.deleteUser(outsiderUserId);
  });

  it("keeps source registration and job creation behind authorization", async () => {
    const project = await adminClient.rpc("create_project", {
      p_title: "M2 Source Test",
      p_exam_year: 2025,
      p_subject: "Mathematics",
      p_stream: "natural_science",
    });
    assert.equal(project.error, null, project.error?.message);
    projectId = project.data as string;

    const outsiderRead = await outsiderClient.from("source_documents").select("id").eq("project_id", projectId);
    assert.equal(outsiderRead.error, null);
    assert.deepEqual(outsiderRead.data, []);

    const forbiddenJob = await outsiderClient.rpc("create_extraction_job", {
      p_project_id: projectId,
      p_source_document_id: randomUUID(),
      p_requested_pages: [1],
    });
    assert.ok(forbiddenJob.error, "A non-member must not create a job");

    const outsiderDocumentId = randomUUID();
    const outsiderPath = `${projectId}/${outsiderDocumentId}/source.pdf`;
    const forbiddenUpload = await outsiderClient.storage.from("source-pdfs").upload(
      outsiderPath,
      new Blob(["%PDF-1.4"], { type: "application/pdf" }),
      { contentType: "application/pdf", upsert: false },
    );
    assert.ok(forbiddenUpload.error, "A non-member must not upload a source PDF");
    const forbiddenRegistration = await outsiderClient.rpc("create_source_document", {
      p_project_id: projectId,
      p_document_id: outsiderDocumentId,
      p_storage_path: outsiderPath,
      p_original_filename: "outsider.pdf",
      p_mime_type: "application/pdf",
      p_byte_size: 8,
      p_sha256: "a".repeat(64),
    });
    assert.ok(forbiddenRegistration.error, "A non-member must not register a source PDF");

    const invalidPathRegistration = await adminClient.rpc("create_source_document", {
      p_project_id: projectId,
      p_document_id: randomUUID(),
      p_storage_path: "not-a-project-path.pdf",
      p_original_filename: "invalid.pdf",
      p_mime_type: "application/pdf",
      p_byte_size: 8,
      p_sha256: "a".repeat(64),
    });
    assert.ok(invalidPathRegistration.error, "A malformed storage path must be rejected");
  });

  it("registers an uploaded private PDF and queues its selected pages", async () => {
    documentId = randomUUID();
    storagePath = `${projectId}/${documentId}/source.pdf`;
    const pdf = Buffer.from("%PDF-1.4\nM2 test PDF\n", "ascii");
    const signedUpload = await adminClient.storage.from("source-pdfs").createSignedUploadUrl(storagePath);
    assert.equal(signedUpload.error, null, signedUpload.error?.message);
    const upload = await adminClient.storage.from("source-pdfs").uploadToSignedUrl(
      storagePath,
      signedUpload.data!.token,
      new Blob([pdf], { type: "application/pdf" }),
    );
    assert.equal(upload.error, null, upload.error?.message);

    const registration = await adminClient.rpc("create_source_document", {
      p_project_id: projectId,
      p_document_id: documentId,
      p_storage_path: storagePath,
      p_original_filename: "exam.pdf",
      p_mime_type: "application/pdf",
      p_byte_size: pdf.byteLength,
      p_sha256: createHash("sha256").update(pdf).digest("hex"),
    });
    assert.equal(registration.error, null, registration.error?.message);
    assert.equal(registration.data, documentId);

    const job = await adminClient.rpc("create_extraction_job", {
      p_project_id: projectId,
      p_source_document_id: documentId,
      p_requested_pages: [1, 3, 4],
    });
    assert.equal(job.error, null, job.error?.message);
    jobId = job.data as string;

    const { data: storedJob } = await adminClient.from("extraction_jobs").select("status, requested_pages, total_pages, completed_pages, failed_pages").eq("id", jobId).single();
    assert.deepEqual(storedJob, {
      status: "queued", requested_pages: [1, 3, 4], total_pages: 3, completed_pages: 0, failed_pages: 0,
    });
    const { data: pages } = await adminClient.from("extraction_job_pages").select("pdf_page, status").eq("job_id", jobId).order("pdf_page");
    assert.deepEqual(pages, [
      { pdf_page: 1, status: "queued" },
      { pdf_page: 3, status: "queued" },
      { pdf_page: 4, status: "queued" },
    ]);
  });

  it("rejects duplicate pages and direct table mutation", async () => {
    const duplicateJob = await adminClient.rpc("create_extraction_job", {
      p_project_id: projectId, p_source_document_id: documentId, p_requested_pages: [1, 1],
    });
    assert.ok(duplicateJob.error, "Duplicate pages must be rejected");

    const directInsert = await adminClient.from("source_documents").insert({
      id: randomUUID(), project_id: projectId, storage_path: `${projectId}/${randomUUID()}/source.pdf`,
      original_filename: "spoof.pdf", mime_type: "application/pdf", byte_size: 10,
      sha256: "a".repeat(64), uploaded_by: adminUserId,
    });
    assert.ok(directInsert.error, "Direct source-document insertion must be blocked");
  });

  it("cancels a queued job and records the page state", async () => {
    const cancellation = await adminClient.rpc("cancel_extraction_job", { p_job_id: jobId });
    assert.equal(cancellation.error, null, cancellation.error?.message);
    const { data: job } = await adminClient.from("extraction_jobs").select("status, completed_at").eq("id", jobId).single();
    assert.equal(job?.status, "cancelled");
    assert.ok(job?.completed_at);
    const { data: pages } = await adminClient.from("extraction_job_pages").select("status").eq("job_id", jobId);
    assert.deepEqual(pages, [{ status: "cancelled" }, { status: "cancelled" }, { status: "cancelled" }]);
  });

  it("blocks an outsider from reading the job and source object", async () => {
    const jobRead = await outsiderClient.from("extraction_jobs").select("id").eq("id", jobId);
    assert.equal(jobRead.error, null);
    assert.deepEqual(jobRead.data, []);
    const objectRead = await outsiderClient.storage.from("source-pdfs").download(storagePath);
    assert.ok(objectRead.error, "A non-member must not download the source PDF");
  });
});
