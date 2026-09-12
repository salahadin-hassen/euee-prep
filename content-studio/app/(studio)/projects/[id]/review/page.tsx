import { redirect, notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { isAdminRole, type AppRole } from "@/lib/auth/roles";
import { verifyAndRedirect } from "./_actions/verify-redirect";
import { EditForm } from "./edit-form";
import { FlagForm } from "./flag-form";

export const dynamic = "force-dynamic";

interface Question {
  id: string;
  order_index: number;
  question_text: string;
  choices: string[];
  correct_answer: string;
  explanation: string;
  explanation_draft: string | null;
  status: string;
  flag_note: string | null;
  image_path: string | null;
  extraction_question_id: string | null;
  source_document_id: string | null;
  source_pdf_page: number | null;
  source_region: Record<string, number> | null;
  ai_predicted_choice_index: number | null;
  ai_confidence: string | null;
  ai_reasoning: string | null;
  ai_answer_basis: string | null;
}

interface Assignment {
  id: string;
  start_order_index: number | null;
  end_order_index: number | null;
}

function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

function inAssignment(question: Question, assignment: Assignment | null): boolean {
  if (!assignment) return true;
  return (assignment.start_order_index === null || question.order_index >= assignment.start_order_index)
    && (assignment.end_order_index === null || question.order_index <= assignment.end_order_index);
}

export default async function ReviewPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ q?: string; show?: string; assignment?: string; error?: string }>;
}) {
  const { id } = await params;
  const { q, assignment: assignmentId, error: errorMessage } = await searchParams;
  if (!isValidUuid(id)) notFound();

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  const role = profile?.role as AppRole | undefined;
  if (!role || (!isAdminRole(role) && role !== "reviewer")) redirect("/projects");
  const admin = isAdminRole(role);

  const { data: project } = await supabase
    .from("projects")
    .select("id, title, subject, exam_year, status")
    .eq("id", id)
    .single();
  if (!project) notFound();

  let assignment: Assignment | null = null;
  if (!admin) {
    const query = supabase
      .from("review_assignments")
      .select("id, start_order_index, end_order_index")
      .eq("project_id", id)
      .eq("reviewer_id", user.id)
      .neq("status", "completed");
    const { data } = assignmentId
      ? await query.eq("id", assignmentId).maybeSingle()
      : await query.order("assigned_at", { ascending: true }).limit(1).maybeSingle();
    if (!data) redirect(`/projects/${id}`);
    assignment = data as Assignment;
  } else if (assignmentId) {
    const { data } = await supabase
      .from("review_assignments")
      .select("id, start_order_index, end_order_index")
      .eq("id", assignmentId)
      .eq("project_id", id)
      .maybeSingle();
    assignment = data as Assignment | null;
  }

  const { data: allQuestions } = await supabase
    .from("questions")
    .select("*")
    .eq("project_id", id)
    .order("order_index", { ascending: true });
  const scopedQuestions = ((allQuestions ?? []) as Question[]).filter((question) => inAssignment(question, assignment));
  const pendingQuestions = scopedQuestions.filter((question) => question.status !== "verified");
  const requestedOrder = q ? Number(q) - 1 : null;
  const current = requestedOrder !== null && Number.isInteger(requestedOrder)
    ? pendingQuestions.find((question) => question.order_index === requestedOrder) ?? pendingQuestions[0] ?? null
    : pendingQuestions[0] ?? null;
  const currentIndex = current ? pendingQuestions.findIndex((question) => question.id === current.id) : -1;
  const previous = currentIndex > 0 ? pendingQuestions[currentIndex - 1] : null;
  const next = currentIndex >= 0 && currentIndex < pendingQuestions.length - 1 ? pendingQuestions[currentIndex + 1] : null;
  const verifiedCount = scopedQuestions.filter((question) => question.status === "verified").length;

  let sourceUrl: string | null = null;
  let sourceFilename: string | null = null;
  if (current?.source_document_id) {
    const { data: source } = await supabase
      .from("source_documents")
      .select("storage_path, original_filename")
      .eq("id", current.source_document_id)
      .maybeSingle();
    sourceFilename = source?.original_filename ?? null;
    if (source?.storage_path) {
      const { data: signed } = await supabase.storage.from("source-pdfs").createSignedUrl(source.storage_path, 3600);
      sourceUrl = signed?.signedUrl ?? null;
    }
  }

  let assetUrls: string[] = [];
  let currentImageUrl: string | null = null;
  if (current?.image_path) {
    const { data } = await supabase.storage.from("question-images").createSignedUrl(current.image_path, 3600);
    currentImageUrl = data?.signedUrl ?? null;
  }
  if (current?.extraction_question_id) {
    const { data: assets } = await supabase
      .from("extraction_visual_assets")
      .select("storage_path")
      .eq("extraction_question_id", current.extraction_question_id)
      .not("storage_path", "is", null);
    const signedAssets = await Promise.all((assets ?? []).map(async (asset) => {
      const { data } = await supabase.storage.from("extraction-assets").createSignedUrl(asset.storage_path, 3600);
      return data?.signedUrl ?? null;
    }));
    assetUrls = signedAssets.filter((url): url is string => Boolean(url));
  }

  const assignmentQuery = assignment ? `&assignment=${assignment.id}` : "";
  const reviewHref = (question: Question) => `/projects/${id}/review?q=${question.order_index + 1}${assignmentQuery}`;

  if (!current) {
    return (
      <main className="content">
        <section className="hero">
          <div>
            <p className="eyebrow">Review · {project.title}</p>
            <h1>Review complete</h1>
            <p className="lede">{verifiedCount} of {scopedQuestions.length} assigned questions verified.</p>
          </div>
          <Link className="button" href={`/projects/${id}`}>Back to paper</Link>
        </section>
      </main>
    );
  }

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Review · {project.title}</p>
          <h1>Question {current.order_index + 1}</h1>
          <p className="lede">
            {verifiedCount} / {scopedQuestions.length} verified · {pendingQuestions.length} remaining
            {assignment && <> · {assignment.start_order_index === null ? "Whole paper" : `Questions ${assignment.start_order_index + 1}-${(assignment.end_order_index ?? assignment.start_order_index) + 1}`}</>}
          </p>
        </div>
        <Link className="button" href={`/projects/${id}`}>Back to paper</Link>
      </section>

      <div className="btn-stack" style={{ marginBottom: 16 }}>
        {previous ? <Link className="button button-sm" href={reviewHref(previous)}>← Previous</Link> : <span />}
        {next && <Link className="button button-sm" href={reviewHref(next)}>Next →</Link>}
      </div>

      {errorMessage && <p className="error" role="alert">{errorMessage}</p>}

      <section className="panel">
        {(sourceUrl || assetUrls.length > 0) && (
          <div style={{ marginBottom: 20, padding: 14, background: "#f8f9fa", borderRadius: 8 }}>
            <strong>Source</strong>
            <div className="project-meta">
              {sourceFilename ?? "Original paper"}{current.source_pdf_page ? ` · PDF page ${current.source_pdf_page}` : ""}
              {sourceUrl && <> · <a href={`${sourceUrl}${current.source_pdf_page ? `#page=${current.source_pdf_page}` : ""}`} target="_blank" rel="noreferrer">Open PDF</a></>}
            </div>
            {assetUrls.map((url, index) => (
              <span key={url}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={url} alt={`Original source figure ${index + 1}`} style={{ maxWidth: "100%", maxHeight: 300, marginTop: 10, borderRadius: 8 }} />
              </span>
            ))}
          </div>
        )}

        {currentImageUrl && (
          <>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={currentImageUrl} alt="Question image" style={{ maxWidth: "100%", maxHeight: 300, marginBottom: 16, borderRadius: 8 }} />
          </>
        )}
        <h2 style={{ fontSize: 20, lineHeight: 1.5, marginBottom: 16 }}>{current.question_text}</h2>
        <ul style={{ listStyle: "none", padding: 0, display: "grid", gap: 8 }}>
          {current.choices.map((choice, index) => (
            <li key={choice} style={{ padding: "10px 14px", border: "1px solid var(--line)", borderRadius: 8 }}>
              {String.fromCharCode(65 + index)}. {choice}
            </li>
          ))}
        </ul>

        <div style={{ marginTop: 20, padding: 14, border: "1px solid var(--line)", borderRadius: 8 }}>
          <strong>AI suggestion</strong>
          <p className="project-meta">
            {current.ai_predicted_choice_index === null ? "No answer suggested" : `${String.fromCharCode(65 + current.ai_predicted_choice_index)} — ${current.ai_confidence ?? "unknown"} confidence`}
            {current.ai_answer_basis ? ` · ${current.ai_answer_basis}` : ""}
          </p>
          {current.ai_reasoning && <p style={{ fontSize: 14 }}>{current.ai_reasoning}</p>}
        </div>

        <EditForm question={current} imageUrl={currentImageUrl} projectId={id} />

        <form action={verifyAndRedirect} className="form" style={{ marginTop: 16 }}>
          <input type="hidden" name="question_id" value={current.id} />
          <input type="hidden" name="project_id" value={id} />
          {assignment && <input type="hidden" name="assignment_id" value={assignment.id} />}
          <fieldset>
            <legend>Verified answer</legend>
            <div className="choice-row">
              {current.choices.map((choice, index) => (
                <label key={choice}>
                  <input type="radio" name="correct_answer" value={choice} required />
                  {String.fromCharCode(65 + index)}
                </label>
              ))}
            </div>
          </fieldset>
          <label>
            Explanation draft
            <textarea name="explanation_draft" rows={3} defaultValue={current.explanation_draft ?? ""} placeholder="Explain why the verified answer is correct." />
          </label>
          <label>
            Final explanation
            <textarea name="explanation" rows={3} defaultValue={current.explanation} placeholder="Leave blank if the explanation still needs work." />
          </label>
          <label>
            <input type="checkbox" name="mark_explanation_verified" /> Explanation reviewed
          </label>
          <button className="button" type="submit">Save &amp; next</button>
        </form>

        {current.flag_note && <p style={{ marginTop: 12, padding: 10, background: "#fff8ed", borderRadius: 8, color: "#875b14" }}><strong>Flagged:</strong> {current.flag_note}</p>}
        <FlagForm questionId={current.id} projectId={id} />
      </section>
    </main>
  );
}
