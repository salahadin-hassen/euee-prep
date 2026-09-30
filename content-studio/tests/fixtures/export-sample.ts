/**
 * Deterministic sample input for the export tests and the committed export
 * fixture (`exported-content-pack-v3.json`).
 *
 * The fixture is generated from these inputs, so the same values drive:
 * - the behavioral export tests in `tests/export.test.ts`
 * - the Python pipeline validation (`tools/content_pipeline/tests`)
 * - the Flutter import chain (`test/features/content`)
 *
 * If you change these inputs, regenerate the fixture:
 *   node --experimental-strip-types <script that JSON.stringifies
 *   buildContentPack(sampleProject, sampleQuestions, SAMPLE_GENERATED_AT)>
 */

import type { ExportProject, ExportQuestion } from "../../lib/export-pack.ts";

/** Fixed timestamp so the pack — and its checksum — are reproducible. */
export const SAMPLE_GENERATED_AT = "2026-09-16T12:00:00.000Z";

export const sampleProject: ExportProject = {
  id: "11111111-2222-3333-4444-555555555555",
  title: "2018 Natural Science — Biology",
  exam_year: 2018,
  subject: "Biology",
  stream: "natural_science",
  status: "approved",
};

export const sampleQuestions: ExportQuestion[] = [
  {
    id: "aaaaaaaa-0000-4000-8000-000000000001",
    order_index: 0,
    question_text: "Which organelle is responsible for ATP synthesis?",
    choices: ["Ribosome", "Golgi apparatus", "Mitochondrion", "Lysosome"],
    correct_answer: "Mitochondrion",
    explanation: "Mitochondria produce ATP via oxidative phosphorylation.",
    explanation_draft: null,
    source_pdf_page: 3,
    status: "verified",
    verified_by: "22222222-3333-4444-5555-666666666666",
    verified_at: "2026-09-15T10:00:00.000Z",
  },
  {
    id: "aaaaaaaa-0000-4000-8000-000000000002",
    order_index: 1,
    question_text:
      'Which statement about "facilitated diffusion" is correct?',
    choices: [
      "It needs a concentration gradient, and carrier proteins",
      "It requires ATP directly",
      "It moves solutes against a gradient",
      "It occurs only in plant cells",
    ],
    correct_answer: "It needs a concentration gradient, and carrier proteins",
    explanation: "Facilitated diffusion is passive: gradient + carrier.",
    explanation_draft: null,
    source_pdf_page: 4,
    status: "verified",
    verified_by: "22222222-3333-4444-5555-666666666666",
    verified_at: "2026-09-15T10:05:00.000Z",
  },
  {
    id: "aaaaaaaa-0000-4000-8000-000000000003",
    order_index: 2,
    question_text: "Approximately how many cells ≈ fit in 1 mm² of tissue?",
    choices: ["10²", "10⁴", "10⁶", "10⁸"],
    correct_answer: "10⁴",
    explanation: "",
    explanation_draft: "A typical animal cell is ≈ 10–20 µm across.",
    source_pdf_page: null,
    status: "verified",
    verified_by: "22222222-3333-4444-5555-666666666666",
    verified_at: "2026-09-15T10:10:00.000Z",
  },
  {
    id: "aaaaaaaa-0000-4000-8000-000000000004",
    order_index: 3,
    question_text: "Which molecule stores genetic information?",
    choices: ["DNA", "Glucose", "ATP", "Keratin"],
    correct_answer: "DNA",
    explanation: "DNA stores the hereditary information of an organism.",
    explanation_draft: null,
    source_pdf_page: 6,
    status: "verified",
    verified_by: "22222222-3333-4444-5555-666666666666",
    verified_at: "2026-09-15T10:15:00.000Z",
  },
];
