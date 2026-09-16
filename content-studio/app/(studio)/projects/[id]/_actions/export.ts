"use server";

import { createClient } from "@/lib/supabase/server";
import JSZip from "jszip";

interface ProjectRow {
  id: string;
  title: string;
  exam_year: number;
  subject: string;
  stream: string;
  status: string;
}

interface QuestionRow {
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

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

export async function exportContentPack(formData: FormData): Promise<{ error: string | null; filename: string | null; blob: Blob | null }> {
  const projectId = formData.get("project_id") as string;
  if (!projectId) return { error: "Missing project ID.", filename: null, blob: null };

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", filename: null, blob: null };

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  const role = profile?.role;
  if (role !== "owner" && role !== "admin") {
    return { error: "Only admins can export.", filename: null, blob: null };
  }

  const { data: project, error: projectError } = await supabase
    .from("projects")
    .select("id, title, exam_year, subject, stream, status")
    .eq("id", projectId)
    .single();

  if (projectError || !project) return { error: "Paper not found.", filename: null, blob: null };
  const typed = project as ProjectRow;

  if (typed.status !== "approved") {
    return { error: "Paper must be approved before exporting.", filename: null, blob: null };
  }

  const { data: questions, error: questionsError } = await supabase
    .from("questions")
    .select("id, order_index, question_text, choices, correct_answer, explanation, explanation_draft, source_pdf_page, status, verified_by, verified_at")
    .eq("project_id", projectId)
    .order("order_index", { ascending: true });

  if (questionsError) return { error: `Failed to fetch questions: ${questionsError.message}`, filename: null, blob: null };
  if (!questions || questions.length === 0) return { error: "No questions found.", filename: null, blob: null };

  const typedQuestions = questions as unknown as QuestionRow[];

  for (const q of typedQuestions) {
    if (q.status !== "verified") {
      return { error: `Question ${q.order_index + 1} is not verified (status: ${q.status}).`, filename: null, blob: null };
    }
    if (!q.verified_by || !q.verified_at) {
      return { error: `Question ${q.order_index + 1} is missing verification metadata.`, filename: null, blob: null };
    }
    if (!q.correct_answer) {
      return { error: `Question ${q.order_index + 1} has no correct answer.`, filename: null, blob: null };
    }
  }

  const seenIds = new Set<string>();
  for (const q of typedQuestions) {
    if (seenIds.has(q.id)) {
      return { error: `Duplicate question ID: ${q.id}.`, filename: null, blob: null };
    }
    seenIds.add(q.id);
  }

  const streamLabel = typed.stream === "natural_science" ? "Natural Science" : "Social Science";
  const packId = `${slugify(typed.subject)}-${typed.exam_year}-${slugify(typed.stream)}`;

  const manifest = {
    schema_version: 1,
    pack_id: packId,
    title: typed.title,
    subject: typed.subject,
    year: typed.exam_year,
    stream: streamLabel,
    question_count: typedQuestions.length,
    generated_at: new Date().toISOString(),
  };

  const exportQuestions = typedQuestions.map((q, index) => ({
    id: `${packId}-q${index + 1}`,
    number: index + 1,
    prompt: q.question_text,
    choices: q.choices,
    correct_choice_index: q.choices.indexOf(q.correct_answer),
    explanation: q.explanation || q.explanation_draft || "",
    source_page: q.source_pdf_page,
  }));

  const questionsFile = {
    schema_version: 1,
    paper: {
      pack_id: packId,
      subject: typed.subject,
      year: typed.exam_year,
      stream: streamLabel,
    },
    questions: exportQuestions,
  };

  const zip = new JSZip();
  zip.file("manifest.json", JSON.stringify(manifest, null, 2));
  zip.file("questions.json", JSON.stringify(questionsFile, null, 2));

  const blob = await zip.generateAsync({ type: "nodebuffer" });
  const filename = `${slugify(typed.subject)}_${typed.exam_year}_${slugify(typed.stream)}.zip`;

  return { error: null, filename, blob: blob as unknown as Blob };
}
