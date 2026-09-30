import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import JSZip from "jszip";
import {
  assertProjectReady,
  buildContentPack,
  createPackZip,
  normalizeStream,
  packZipFilename,
  type ExportProject,
  type ExportQuestion,
} from "../lib/export-pack.ts";
import { computeChecksum } from "../lib/checksum.ts";
import {
  SAMPLE_GENERATED_AT,
  sampleProject,
  sampleQuestions,
} from "./fixtures/export-sample.ts";

const actionSource = readFileSync(
  resolve(process.cwd(), "app/(studio)/projects/[id]/_actions/export.ts"),
  "utf8",
);
const packSource = readFileSync(resolve(process.cwd(), "lib/export-pack.ts"), "utf8");
/** Guards may live in the action or in the pure export module. */
const combinedSource = `${actionSource}\n${packSource}`;

describe("export content pack — v3 flat schema", () => {
  it("checks project status is approved before export", () => {
    assert.ok(
      combinedSource.includes(`typed.status !== "approved"`) || combinedSource.includes(`status !== "approved"`),
      "export action must reject unapproved papers",
    );
  });

  it("checks admin role before export", () => {
    assert.ok(
      actionSource.includes('"owner"') && actionSource.includes('"admin"'),
      "export action must verify admin or owner role",
    );
  });

  it("validates all questions are verified", () => {
    assert.ok(
      combinedSource.includes(`q.status !== "verified"`) || combinedSource.includes(`status !== "verified"`),
      "export must reject unverified questions",
    );
  });

  it("validates correct_answer exists", () => {
    assert.ok(
      combinedSource.includes("correct_answer"),
      "export must validate correct_answer is present",
    );
  });

  it("checks for duplicate question IDs", () => {
    assert.ok(
      combinedSource.includes("seenIds") || combinedSource.includes("duplicate") || combinedSource.includes("Duplicate"),
      "export must check for duplicate question IDs",
    );
  });

  it("orders questions by order_index", () => {
    assert.ok(
      actionSource.includes("order_index") && actionSource.includes("ascending: true"),
      "export must order questions by order_index ascending",
    );
  });

  it("uses verified correct_answer, not AI prediction", () => {
    assert.ok(
      combinedSource.includes("correct_answer") && combinedSource.includes("indexOf"),
      "export must derive correct_choice_index from verified correct_answer",
    );
  });

  it("exports final explanation", () => {
    assert.ok(
      combinedSource.includes("q.explanation"),
      "export must include final explanation",
    );
  });

  it("generates deterministic pack IDs from paper metadata", () => {
    assert.ok(
      combinedSource.includes("packId"),
      "export must generate a deterministic pack_id",
    );
    assert.ok(
      combinedSource.includes("slugify"),
      "export must sanitize pack_id with slugify",
    );
  });

  it("produces single content-pack.json in ZIP", () => {
    assert.ok(
      combinedSource.includes('"content-pack.json"'),
      "ZIP must contain content-pack.json",
    );
    assert.ok(
      !combinedSource.includes('"manifest.json"'),
      "ZIP must NOT contain manifest.json",
    );
    assert.ok(
      !combinedSource.includes('"questions.json"'),
      "ZIP must NOT contain questions.json",
    );
  });

  it("uses schema_version 3", () => {
    assert.ok(
      combinedSource.includes('schema_version: "3"'),
      "export must set schema_version to \"3\"",
    );
  });

  it("includes pack_version", () => {
    assert.ok(
      combinedSource.includes('pack_version: "1.0.0"'),
      "export must include pack_version",
    );
  });

  it("includes minimum_app_version", () => {
    assert.ok(
      combinedSource.includes('minimum_app_version: "1.0.0"'),
      "export must include minimum_app_version",
    );
  });

  it("computes and includes checksum", () => {
    assert.ok(
      combinedSource.includes("computeChecksum"),
      "export must compute checksum",
    );
    assert.ok(
      combinedSource.includes("checksum") && combinedSource.includes("pack.checksum"),
      "export must assign checksum to pack",
    );
  });

  it("normalizes stream to snake_case", () => {
    assert.ok(
      combinedSource.includes("normalizeStream"),
      "export must normalize stream via normalizeStream",
    );
    assert.ok(
      combinedSource.includes("natural_science") && combinedSource.includes("social_science"),
      "export must map natural_science and social_science through the stream map",
    );
  });

  it("rejects unknown stream values", () => {
    assert.ok(
      combinedSource.includes("Unknown stream"),
      "export must reject unknown stream values",
    );
  });

  it("exports subject as object with slug and title", () => {
    assert.ok(
      combinedSource.includes("subject:") && combinedSource.includes("slug:") && combinedSource.includes("title:"),
      "export must include subject.slug and subject.title",
    );
  });

  it("exports paper metadata with year, title, question_count", () => {
    assert.ok(
      combinedSource.includes("paper:") && combinedSource.includes("year:") && combinedSource.includes("question_count:"),
      "export must include paper.year, paper.title, paper.question_count",
    );
  });

  it("preserves source_page when available", () => {
    assert.ok(
      combinedSource.includes("source_page") && combinedSource.includes("source_pdf_page"),
      "export must preserve source_pdf_page as source_page",
    );
  });

  it("does not export AI confidence or reasoning", () => {
    assert.ok(
      !combinedSource.includes("ai_confidence") || combinedSource.includes("// ai_confidence"),
      "export must not include ai_confidence in output",
    );
    assert.ok(
      !combinedSource.includes("ai_reasoning") || combinedSource.includes("// ai_reasoning"),
      "export must not include ai_reasoning in output",
    );
  });
});

describe("export content pack — behavioral", () => {
  const build = (project: ExportProject, questions: ExportQuestion[] = sampleQuestions) =>
    buildContentPack(project, questions, SAMPLE_GENERATED_AT);

  it("exports a real natural_science project", () => {
    const pack = build(sampleProject);
    assert.equal(pack.stream, "natural_science");
    assert.equal(pack.pack_id, "biology-2018-natural_science");
    assert.equal(packZipFilename(sampleProject), "biology_2018_natural_science.zip");
  });

  it("exports a real social_science project", () => {
    const project: ExportProject = { ...sampleProject, stream: "social_science" };
    const pack = build(project);
    assert.equal(pack.stream, "social_science");
    assert.equal(pack.pack_id, "biology-2018-social_science");
    assert.equal(packZipFilename(project), "biology_2018_social_science.zip");
  });

  it("rejects unknown stream values instead of normalizing them", () => {
    assert.throws(() => normalizeStream("Natural Science"), /Unknown stream/);
    assert.throws(() => normalizeStream("engineering"), /Unknown stream/);
    assert.throws(() => normalizeStream(""), /Unknown stream/);
    assert.throws(
      () => build({ ...sampleProject, stream: "Natural Science" }),
      /Unknown stream/,
    );
    assert.throws(
      () => assertProjectReady({ ...sampleProject, stream: "Natural Science" }),
      /Unknown stream/,
    );
  });

  it("exports a pack that conforms to the v3 schema", () => {
    const pack = build(sampleProject);

    assert.equal(pack.schema_version, "3");
    assert.equal(pack.pack_version, "1.0.0");
    assert.equal(pack.minimum_app_version, "1.0.0");
    assert.equal(pack.generated_at, SAMPLE_GENERATED_AT);
    assert.equal(pack.stream, "natural_science");
    assert.deepEqual(pack.subject, { slug: "biology", title: "Biology" });
    assert.deepEqual(pack.paper, {
      year: 2018,
      title: "2018 Natural Science — Biology",
      question_count: sampleQuestions.length,
    });

    const questions = pack.questions as Record<string, unknown>[];
    assert.equal(questions.length, sampleQuestions.length);
    questions.forEach((q, index) => {
      assert.equal(q.id, `biology-2018-natural_science-q${index + 1}`);
      assert.equal(q.number, index + 1);
      assert.equal(typeof q.prompt, "string");
      assert.ok(Array.isArray(q.choices));
      assert.equal(q.choices.length, 4);
      assert.equal(typeof q.correct_choice_index, "number");
      assert.equal(
        (q.choices as string[])[q.correct_choice_index as number],
        sampleQuestions[index].correct_answer,
      );
      assert.equal(typeof q.explanation, "string");
    });

    // source_page is only present when the row has a page.
    const exported = questions.map((q) => "source_page" in q);
    assert.deepEqual(exported, [true, true, false, true]);

    // explanation falls back to the reviewer draft when the final is empty.
    assert.equal(
      (questions[2] as Record<string, unknown>).explanation,
      "A typical animal cell is ≈ 10–20 µm across.",
    );
  });

  it("keeps database-only and AI fields out of the pack", () => {
    const pack = build(sampleProject);
    const serialized = JSON.stringify(pack);
    for (const forbidden of [
      "verified_by",
      "verified_at",
      "correct_answer",
      "ai_predicted",
      "ai_confidence",
      "ai_reasoning",
      "explanation_draft",
      "status",
    ]) {
      assert.ok(
        !serialized.includes(forbidden),
        `pack must not contain "${forbidden}"`,
      );
    }
  });

  it("computes a checksum that matches the shared FNV-1a contract", () => {
    const pack = build(sampleProject);
    const checksum = pack.checksum as string;
    assert.match(checksum, /^fnv1a64:[0-9a-f]{16}$/);
    assert.equal(
      checksum,
      computeChecksum(pack),
      "declared checksum must equal the recomputed checksum",
    );
    // The checksum must not depend on the checksum field itself.
    const tampered = { ...pack, checksum: "fnv1a64:0000000000000000" };
    assert.equal(computeChecksum(tampered), checksum);
  });

  it("rejects an unapproved project", () => {
    assert.throws(
      () => build({ ...sampleProject, status: "in_review" }),
      /approved before export/,
    );
  });

  it("rejects questions that are not verified", () => {
    const questions = sampleQuestions.map((q, i) =>
      i === 1 ? { ...q, status: "unverified" } : q,
    );
    assert.throws(() => build(sampleProject, questions), /not verified/);
  });

  it("rejects questions missing verification metadata", () => {
    const questions = sampleQuestions.map((q, i) =>
      i === 0 ? { ...q, verified_at: null } : q,
    );
    assert.throws(() => build(sampleProject, questions), /verification metadata/);
  });

  it("rejects duplicate question IDs", () => {
    const questions = [...sampleQuestions, { ...sampleQuestions[0] }];
    assert.throws(() => build(sampleProject, questions), /Duplicate question ID/);
  });

  it("rejects a correct answer that is not one of the choices", () => {
    const questions = sampleQuestions.map((q, i) =>
      i === 0 ? { ...q, correct_answer: "Not a choice" } : q,
    );
    assert.throws(() => build(sampleProject, questions), /not one of its choices/);
  });

  it("rejects an empty question list", () => {
    assert.throws(() => build(sampleProject, []), /No questions found/);
  });

  it("packs exactly one content-pack.json into the ZIP", async () => {
    const pack = build(sampleProject);
    const zipBytes = await createPackZip(pack);
    const zip = await JSZip.loadAsync(zipBytes);

    const names = Object.keys(zip.files).filter((name) => !zip.files[name].dir);
    assert.deepEqual(names, ["content-pack.json"]);

    const raw = await zip.file("content-pack.json")!.async("string");
    assert.deepEqual(JSON.parse(raw), pack);
  });
});

describe("export fixture parity", () => {
  const fixturePath = resolve(
    process.cwd(),
    "tests/fixtures/exported-content-pack-v3.json",
  );
  const fixture = JSON.parse(readFileSync(fixturePath, "utf8")) as Record<string, unknown>;

  it("builds the committed fixture byte-for-byte", () => {
    const pack = buildContentPack(sampleProject, sampleQuestions, SAMPLE_GENERATED_AT);
    assert.deepEqual(pack, fixture);
  });

  it("fixture carries a checksum that verifies in TypeScript", () => {
    assert.equal(computeChecksum(fixture), fixture.checksum);
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
