import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync } from "node:fs";
import { resolve } from "node:path";

function readAllMigrations(): string {
  const migrationDir = resolve(process.cwd(), "supabase/migrations");
  const files = readdirSync(migrationDir).filter((f) => f.endsWith(".sql")).sort();
  return files.map((f) => readFileSync(resolve(migrationDir, f), "utf8")).join("\n");
}

describe("extraction-to-review promotion", () => {
  it("promote_extraction_questions function exists in migration", () => {
    const combined = readAllMigrations();
    assert.ok(
      combined.includes("promote_extraction_questions"),
      "Migration must define promote_extraction_questions function",
    );
  });

  it("promote_extraction_questions is security definer", () => {
    const combined = readAllMigrations();
    const idx = combined.indexOf("promote_extraction_questions");
    const snippet = combined.slice(idx, idx + 500);
    assert.ok(
      snippet.includes("security definer"),
      "promote_extraction_questions must be security definer",
    );
  });

  it("promote_extraction_questions is only executable by service_role", () => {
    const combined = readAllMigrations();
    const revokeRegex = /revoke\s+execute\s+on\s+function\s+public\.promote_extraction_questions/g;
    const matches = combined.match(revokeRegex);
    assert.ok(matches && matches.length > 0, "Must revoke execute from public/anon/authenticated");

    const grantRegex = /grant\s+execute\s+on\s+function\s+public\.promote_extraction_questions.*?to\s+service_role/g;
    const grantMatches = combined.match(grantRegex);
    assert.ok(grantMatches && grantMatches.length > 0, "Must grant execute to service_role");
  });

  it("worker completion route calls promote_extraction_questions", () => {
    const routeSource = readFileSync(
      resolve(process.cwd(), "app/api/worker/complete/route.ts"),
      "utf8",
    );
    assert.ok(
      routeSource.includes("promote_extraction_questions"),
      "Worker completion route must call promote_extraction_questions",
    );
  });

  it("worker completion route checks for duplicate notifications", () => {
    const routeSource = readFileSync(
      resolve(process.cwd(), "app/api/worker/complete/route.ts"),
      "utf8",
    );
    assert.ok(
      routeSource.includes("existingNotification"),
      "Worker completion route must check for existing notification to prevent duplicates",
    );
  });

  it("promotion does not auto-populate correct_answer from AI", () => {
    const combined = readAllMigrations();
    const idx = combined.indexOf("promote_extraction_questions");
    const funcBody = combined.slice(idx, idx + 3000);
    assert.ok(
      funcBody.includes("''") && funcBody.includes("correct_answer"),
      "Promotion must set empty correct_answer, not copy from AI predictions",
    );
  });

  it("inline extraction component has processing state", () => {
    const componentSource = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/inline-extraction.tsx"),
      "utf8",
    );
    assert.ok(
      componentSource.includes("Starting"),
      "Extract button must show Starting state during submission",
    );
    assert.ok(
      componentSource.includes("Ready for review"),
      "Must show Ready for review on completed jobs",
    );
  });

  it("inline extraction component has failure state", () => {
    const componentSource = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/inline-extraction.tsx"),
      "utf8",
    );
    assert.ok(
      componentSource.includes("Extraction failed"),
      "Must show Extraction failed state",
    );
    assert.ok(
      componentSource.includes("Completed with issues"),
      "Must show Completed with issues state",
    );
  });

  it("paper detail page shows extraction summary", () => {
    const pageSource = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/page.tsx"),
      "utf8",
    );
    assert.ok(
      pageSource.includes("ExtractionSummary"),
      "Paper page must render ExtractionSummary component",
    );
    assert.ok(
      pageSource.includes("Ready for review"),
      "Paper page must show Ready for review status",
    );
  });

  it("paper detail page shows review link when questions exist", () => {
    const pageSource = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/page.tsx"),
      "utf8",
    );
    assert.ok(
      pageSource.includes("Review questions"),
      "Paper page must show Review questions link",
    );
  });

  it("notification bell deep-links completion to review page", () => {
    const bellSource = readFileSync(
      resolve(process.cwd(), "components/notification-bell.tsx"),
      "utf8",
    );
    assert.ok(
      bellSource.includes("/review"),
      "Notification bell must deep-link completion notifications to review page",
    );
  });

  it("notification bell shows body text in notification items", () => {
    const bellSource = readFileSync(
      resolve(process.cwd(), "components/notification-bell.tsx"),
      "utf8",
    );
    assert.ok(
      bellSource.includes("n.body"),
      "Notification bell must display notification body text",
    );
  });

  it("status labels are updated for extraction jobs", () => {
    const statusSource = readFileSync(
      resolve(process.cwd(), "lib/status.ts"),
      "utf8",
    );
    assert.ok(
      statusSource.includes("Ready for review"),
      "Job status must show Ready for review for completed jobs",
    );
    assert.ok(
      statusSource.includes("Extraction failed"),
      "Job status must show Extraction failed",
    );
    assert.ok(
      statusSource.includes("Completed with issues"),
      "Job status must show Completed with issues",
    );
  });
});
