import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

describe("export content pack", () => {
  const exportSource = readFileSync(
    resolve(process.cwd(), "app/(studio)/projects/[id]/_actions/export.ts"),
    "utf8",
  );

  it("checks project status is approved before export", () => {
    assert.ok(
      exportSource.includes(`typed.status !== "approved"`) || exportSource.includes(`status !== "approved"`),
      "export action must reject unapproved papers",
    );
  });

  it("checks admin role before export", () => {
    assert.ok(
      exportSource.includes('"owner"') && exportSource.includes('"admin"'),
      "export action must verify admin or owner role",
    );
  });

  it("validates all questions are verified", () => {
    assert.ok(
      exportSource.includes(`q.status !== "verified"`) || exportSource.includes(`status !== "verified"`),
      "export must reject unverified questions",
    );
  });

  it("validates correct_answer exists", () => {
    assert.ok(
      exportSource.includes("correct_answer"),
      "export must validate correct_answer is present",
    );
  });

  it("checks for duplicate question IDs", () => {
    assert.ok(
      exportSource.includes("seenIds") || exportSource.includes("duplicate") || exportSource.includes("Duplicate"),
      "export must check for duplicate question IDs",
    );
  });

  it("orders questions by order_index", () => {
    assert.ok(
      exportSource.includes("order_index") && exportSource.includes("ascending: true"),
      "export must order questions by order_index ascending",
    );
  });

  it("uses verified correct_answer, not AI prediction", () => {
    assert.ok(
      exportSource.includes("correct_answer") && exportSource.includes("indexOf"),
      "export must derive correct_choice_index from verified correct_answer",
    );
    assert.ok(
      !exportSource.includes("ai_predicted_choice_index") || exportSource.includes("indexOf"),
      "export must not use ai_predicted_choice_index as authoritative answer",
    );
  });

  it("exports final explanation, not draft", () => {
    assert.ok(
      exportSource.includes("q.explanation"),
      "export must include final explanation",
    );
  });

  it("generates deterministic pack IDs from paper metadata", () => {
    assert.ok(
      exportSource.includes("packId"),
      "export must generate a deterministic pack_id",
    );
    assert.ok(
      exportSource.includes("slugify"),
      "export must sanitize pack_id with slugify",
    );
  });

  it("creates ZIP with manifest.json and questions.json", () => {
    assert.ok(
      exportSource.includes('"manifest.json"'),
      "ZIP must contain manifest.json",
    );
    assert.ok(
      exportSource.includes('"questions.json"'),
      "ZIP must contain questions.json",
    );
  });

  it("includes schema_version in both files", () => {
    assert.ok(
      exportSource.includes("schema_version: 1"),
      "both manifest and questions must include schema_version",
    );
  });

  it("preserves source_page when available", () => {
    assert.ok(
      exportSource.includes("source_page") && exportSource.includes("source_pdf_page"),
      "export must preserve source_pdf_page as source_page",
    );
  });

  it("does not export AI confidence or reasoning", () => {
    assert.ok(
      !exportSource.includes("ai_confidence") || exportSource.includes("// ai_confidence"),
      "export must not include ai_confidence in output",
    );
    assert.ok(
      !exportSource.includes("ai_reasoning") || exportSource.includes("// ai_reasoning"),
      "export must not include ai_reasoning in output",
    );
  });

  it("does not export verified_by or verified_at", () => {
    const questionsSection = exportSource.split("questions.json")[1] || "";
    assert.ok(
      !questionsSection.includes("verified_by") || questionsSection.includes("// verified_by"),
      "export must not include verified_by in output questions",
    );
  });
});

describe("export button placement", () => {
  const pageSource = readFileSync(
    resolve(process.cwd(), "app/(studio)/projects/[id]/page.tsx"),
    "utf8",
  );

  it("only shows export button for approved papers", () => {
    assert.ok(
      pageSource.includes('status === "approved"') && pageSource.includes("ExportButton"),
      "export button must only render when status is approved",
    );
  });

  it("only shows export button for admins", () => {
    assert.ok(
      pageSource.includes("isAdmin") && pageSource.includes("ExportButton"),
      "export button must be gated behind isAdmin",
    );
  });

  it("imports ExportButton component", () => {
    assert.ok(
      pageSource.includes('import { ExportButton }'),
      "page must import ExportButton",
    );
  });
});
