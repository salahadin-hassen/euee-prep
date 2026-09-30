/**
 * Pure content-pack export transformation for Content Studio.
 *
 * Everything in this module is side-effect free so tests can execute the real
 * export path. `_actions/export.ts` only wraps this module with authentication,
 * database access, and download transport.
 *
 * The pack produced here is the shared v3 content-pack contract implemented by:
 * - the Flutter importer (`lib/features/content/domain/services/content_pack_validator.dart`)
 * - the pipeline validator (`tools/content_pipeline/validate_pack.py`)
 * The checksum comes from `lib/checksum.ts`, which is byte-compatible with the
 * Dart `ContentChecksum` and the Python `pack_checksum.compute_checksum`.
 */

import JSZip from "jszip";
import { computeChecksum } from "./checksum.ts";

/** Name of the single file the export ZIP contains. */
export const CONTENT_PACK_FILENAME = "content-pack.json";

/** Exact values allowed by the `projects.stream` CHECK constraint. */
export const CONTENT_PACK_STREAMS = ["natural_science", "social_science"] as const;

export type ContentPackStream = (typeof CONTENT_PACK_STREAMS)[number];

/**
 * Maps a stored `projects.stream` value onto its v3 pack value.
 *
 * Keys are the exact values the database can hold — deliberately explicit and
 * deterministic: no case folding, no trimming, no display-name aliases. Any
 * other value throws instead of silently exporting a malformed pack.
 */
const STREAM_MAP: Record<string, ContentPackStream> = {
  natural_science: "natural_science",
  social_science: "social_science",
};

export function normalizeStream(stream: string): ContentPackStream {
  const normalized = STREAM_MAP[stream];
  if (!normalized) {
    throw new Error(
      `Unknown stream: "${stream}". Expected "natural_science" or "social_science".`,
    );
  }
  return normalized;
}

export interface ExportProject {
  id: string;
  title: string;
  exam_year: number;
  subject: string;
  stream: string;
  status: string;
}

export interface ExportQuestion {
  id: string;
  order_index: number;
  question_text: string;
  choices: string[];
  correct_answer: string;
  explanation: string;
  explanation_draft: string | null;
  source_pdf_page: number | null;
  status: string;
  verified_by: string | null;
  verified_at: string | null;
}

export function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

/**
 * Rejects a project that cannot be exported yet and returns its normalized
 * stream. Throws with the same messages the server action surfaces to the UI.
 */
export function assertProjectReady(project: ExportProject): ContentPackStream {
  if (project.status !== "approved") {
    throw new Error("Paper must be approved before export.");
  }
  return normalizeStream(project.stream);
}

/**
 * Validate the rows and build the signed v3 pack for one approved project.
 *
 * Throws (never returns partial data) when a question is unverified, lacks
 * verification metadata, has no correct answer, or would produce a duplicate
 * or out-of-range `correct_choice_index`.
 *
 * `generatedAt` is injectable so tests can build a deterministic pack.
 */
export function buildContentPack(
  project: ExportProject,
  questions: ExportQuestion[],
  generatedAt: string = new Date().toISOString(),
): Record<string, unknown> {
  const stream = assertProjectReady(project);

  if (!questions || questions.length === 0) {
    throw new Error("No questions found.");
  }

  for (const q of questions) {
    if (q.status !== "verified") {
      throw new Error(`Question ${q.order_index + 1} is not verified (status: ${q.status}).`);
    }
    if (!q.verified_by || !q.verified_at) {
      throw new Error(`Question ${q.order_index + 1} is missing verification metadata.`);
    }
    if (!q.correct_answer) {
      throw new Error(`Question ${q.order_index + 1} has no correct answer.`);
    }
  }

  const seenIds = new Set<string>();
  for (const q of questions) {
    if (seenIds.has(q.id)) {
      throw new Error(`Duplicate question ID: ${q.id}.`);
    }
    seenIds.add(q.id);
  }

  const packId = `${slugify(project.subject)}-${project.exam_year}-${stream}`;

  const exportQuestions = questions.map((q, index) => {
    const correctChoiceIndex = q.choices.indexOf(q.correct_answer);
    if (correctChoiceIndex === -1) {
      throw new Error(
        `Question ${q.order_index + 1} correct answer "${q.correct_answer}" is not one of its choices.`,
      );
    }
    return {
      id: `${packId}-q${index + 1}`,
      number: index + 1,
      prompt: q.question_text,
      choices: q.choices,
      correct_choice_index: correctChoiceIndex,
      explanation: q.explanation || q.explanation_draft || "",
      ...(q.source_pdf_page != null ? { source_page: q.source_pdf_page } : {}),
    };
  });

  const pack: Record<string, unknown> = {
    schema_version: "3",
    pack_id: packId,
    pack_version: "1.0.0",
    generated_at: generatedAt,
    minimum_app_version: "1.0.0",
    stream,
    subject: {
      slug: slugify(project.subject),
      title: project.subject,
    },
    paper: {
      year: project.exam_year,
      title: project.title,
      question_count: exportQuestions.length,
    },
    questions: exportQuestions,
  };

  pack.checksum = computeChecksum(pack);

  return pack;
}

/** Deterministic download name for an exported pack. */
export function packZipFilename(project: ExportProject): string {
  const stream = normalizeStream(project.stream);
  return `${slugify(project.subject)}_${project.exam_year}_${stream}.zip`;
}

/** Wrap a signed pack into the single-entry ZIP the app imports. */
export async function createPackZip(pack: Record<string, unknown>): Promise<Uint8Array> {
  const zip = new JSZip();
  zip.file(CONTENT_PACK_FILENAME, JSON.stringify(pack, null, 2));
  return zip.generateAsync({ type: "nodebuffer" });
}
