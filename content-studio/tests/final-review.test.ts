import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(process.cwd(), "..");
const read = (path: string) => readFileSync(resolve(root, path), "utf8");

describe("final extraction and review workflow", () => {
  it("does not let a health check claim extraction jobs", () => {
    const workflow = read(".github/workflows/euee-extraction-worker.yml");
    assert.doesNotMatch(workflow, /health-check|check-queue/);
    assert.match(workflow, /WORKER_JOB_ID/);
  });

  it("does not silently reduce an unreadable PDF to page one", () => {
    const source = read("content-studio/app/(studio)/projects/[id]/inline-extraction.tsx");
    assert.match(source, /Wait for the PDF page count/);
    assert.match(source, /Extract paper/);
    assert.doesNotMatch(source, /: \[1\]/);
  });

  it("preserves provenance and assignment authorization in the database contract", () => {
    const migration = read("content-studio/supabase/migrations/20260915000000_review_assignments_provenance.sql");
    for (const field of [
      "extraction_question_id",
      "source_document_id",
      "source_pdf_page",
      "source_region",
      "ai_predicted_choice_index",
      "explanation_draft",
      "review_assignments",
      "can_review_question",
      "assign_reviewer",
    ]) {
      assert.match(migration, new RegExp(field));
    }
    assert.match(migration, /Select one of the four choices as the verified answer/);
  });

  it("review requires an explicit answer choice and supports assignment scope", () => {
    const page = read("content-studio/app/(studio)/projects/[id]/review/page.tsx");
    assert.match(page, /name="correct_answer"/);
    assert.match(page, /assignment=/);
    assert.match(page, /AI suggestion/);
    assert.match(page, /Save &amp; next/);
  });
});
