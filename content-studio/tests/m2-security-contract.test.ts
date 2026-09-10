import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const migrationPath = resolve(process.cwd(), "supabase/migrations/20260913000000_m2_source_documents_jobs.sql");
const migration = readFileSync(migrationPath, "utf8");

describe("M2 source document and extraction job migration", () => {
  it("creates the private source and job tables with page uniqueness", () => {
    assert.match(migration, /create table public\.source_documents/);
    assert.match(migration, /create table public\.extraction_jobs/);
    assert.match(migration, /create table public\.extraction_job_pages/);
    assert.match(migration, /unique \(job_id, pdf_page\)/);
    assert.match(migration, /values \('source-pdfs', 'source-pdfs', false\)/);
  });

  it("keeps writes behind narrow authenticated RPCs", () => {
    assert.match(migration, /grant select on public\.source_documents, public\.extraction_jobs, public\.extraction_job_pages to authenticated/);
    assert.match(migration, /create or replace function public\.create_source_document/);
    assert.match(migration, /create or replace function public\.create_extraction_job/);
    assert.match(migration, /create or replace function public\.cancel_extraction_job/);
    assert.match(migration, /revoke execute on function public\.create_source_document/);
    assert.match(migration, /grant execute on function public\.create_source_document.*to authenticated/);
    assert.doesNotMatch(migration, /on public\.(source_documents|extraction_jobs|extraction_job_pages) for (insert|update|delete)/);
  });

  it("keeps source PDFs private and immutable", () => {
    assert.match(migration, /values \('source-pdfs', 'source-pdfs', false\)/);
    assert.match(migration, /authorized users can upload source PDFs/);
    assert.match(migration, /project members can read source PDFs/);
    assert.doesNotMatch(migration, /on storage\.objects for (update|delete)[\s\S]*bucket_id = 'source-pdfs'/);
    assert.match(migration, /source_documents_path_shape/);
    assert.match(migration, /source_documents_path_project/);
    assert.match(migration, /source_documents_path_document/);
  });

  it("derives actor identity and records audit events in RPCs", () => {
    assert.match(migration, /uploaded_by\n  \) values \([\s\S]*\(select auth\.uid\(\)\)/);
    assert.match(migration, /created_by, requested_pages/);
    assert.match(migration, /'source_document\.created'/);
    assert.match(migration, /'extraction_job\.created'/);
    assert.match(migration, /'extraction_job\.cancelled'/);
  });
});

describe("M2 application mutation boundary", () => {
  it("uses RPCs for job mutations", () => {
    const source = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/extract/_actions/job.ts"),
      "utf8",
    );
    assert.match(source, /supabase\.rpc\("create_extraction_job"/);
    assert.match(source, /supabase\.rpc\("cancel_extraction_job"/);
    assert.doesNotMatch(source, /from\("(source_documents|extraction_jobs|extraction_job_pages)"\)[\s\S]*\.(insert|update|delete)\(/);
  });
});
