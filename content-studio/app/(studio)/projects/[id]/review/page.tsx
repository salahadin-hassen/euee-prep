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
  status: string;
  flag_note: string | null;
  image_path: string | null;
}

function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

async function getSignedUrl(supabase: Awaited<ReturnType<typeof createClient>>, path: string): Promise<string | null> {
  const { data } = await supabase.storage.from("question-images").createSignedUrl(path, 3600);
  return data?.signedUrl ?? null;
}

export default async function ReviewPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ q?: string; show?: string }>;
}) {
  const { id } = await params;
  const { show } = await searchParams;

  if (!isValidUuid(id)) notFound();

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  if (!profile || (!isAdminRole(profile.role as AppRole) && profile.role !== "reviewer")) redirect("/assignments");

  const { data: project } = await supabase
    .from("projects")
    .select("id, title, subject, exam_year, status")
    .eq("id", id)
    .single();

  if (!project) notFound();

  const { count: total } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id);

  const { count: verified } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id)
    .eq("status", "verified");

  const { count: flagged } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id)
    .eq("status", "flagged");

  let query = supabase
    .from("questions")
    .select("*")
    .eq("project_id", id)
    .order("order_index", { ascending: true });

  if (show === "flagged") {
    query = query.eq("status", "flagged");
  } else {
    query = query.eq("status", "unverified");
  }

  const { data: questions } = await query;
  const questionList = (questions ?? []) as Question[];
  const current = questionList[0] ?? null;

  // Generate a signed URL for the current question's image (if any).
  let currentImageUrl: string | null = null;
  if (current?.image_path) {
    currentImageUrl = await getSignedUrl(supabase, current.image_path);
  }

  if (project.status === "approved") {
    return (
      <main className="content">
        <section className="hero">
          <div>
            <p className="eyebrow">All done!</p>
            <h1>Nice work</h1>
            <p className="lede">
              Every question in &ldquo;{project.title}&rdquo; has been verified.
              This paper is ready to go.
            </p>
          </div>
          <Link className="button" href={`/projects/${id}`}>
            Back to paper
          </Link>
        </section>
        <div className="grid">
          <div className="stat">
            <div className="stat-label">Total questions</div>
            <div className="stat-value">{total ?? 0}</div>
          </div>
          <div className="stat">
            <div className="stat-label">Verified</div>
            <div className="stat-value">{verified ?? 0}</div>
          </div>
          <div className="stat">
            <div className="stat-label">Flagged</div>
            <div className="stat-value">{flagged ?? 0}</div>
          </div>
        </div>
      </main>
    );
  }

  if (!current) {
    return (
      <main className="content">
        <section className="hero">
          <div>
            <p className="eyebrow">Review</p>
            <h1>Nothing to review right now</h1>
            <p className="lede">
              {show === "flagged"
                ? "No flagged questions on this paper."
                : "All questions have been reviewed. Nice!"}
            </p>
          </div>
          <Link className="button" href={`/projects/${id}`}>
            Back to paper
          </Link>
        </section>
        <div className="grid">
          <div className="stat">
            <div className="stat-label">Verified</div>
            <div className="stat-value">{verified ?? 0} / {total ?? 0}</div>
          </div>
          <div className="stat">
            <div className="stat-label">Flagged</div>
            <div className="stat-value">{flagged ?? 0}</div>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Review &middot; {project.title}</p>
          <h1>Question {current.order_index + 1} of {total ?? 0}</h1>
          <p className="lede">
            {verified ?? 0} verified
            {flagged ? <> &middot; <Link href={`/projects/${id}/review?show=flagged`} style={{ color: "var(--amber)" }}>{flagged} flagged</Link></> : null}
          </p>
        </div>
        <Link className="button" href={`/projects/${id}`}>
          Back to paper
        </Link>
      </section>

      <section className="panel">
        <div style={{ marginBottom: 20 }}>
          {currentImageUrl && (
            <div style={{ marginBottom: 16 }}>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={currentImageUrl}
                alt={`Diagram for question ${current.order_index + 1}`}
                style={{ maxWidth: "100%", borderRadius: 8, border: "1px solid var(--line)" }}
              />
            </div>
          )}
          <h2 style={{ fontSize: 20, lineHeight: 1.5, marginBottom: 16 }}>{current.question_text}</h2>
          {current.choices && current.choices.length > 0 && (
            <ul style={{ listStyle: "none", padding: 0, display: "grid", gap: 8 }}>
              {current.choices.map((choice, i) => (
                <li key={i} style={{
                  padding: "10px 14px",
                  border: "1px solid var(--line)",
                  borderRadius: 8,
                  background: choice === current.correct_answer ? "#edf7ed" : "var(--panel)",
                  fontWeight: choice === current.correct_answer ? 700 : 400,
                }}>
                  {String.fromCharCode(65 + i)}. {choice}
                  {choice === current.correct_answer && <span style={{ marginLeft: 8, fontSize: 12, color: "var(--teal)" }}>correct</span>}
                </li>
              ))}
            </ul>
          )}
          {current.explanation && (
            <div style={{ marginTop: 16, padding: 14, background: "#f8f9fa", borderRadius: 8, fontSize: 14, lineHeight: 1.6 }}>
              <strong>Explanation:</strong> {current.explanation}
            </div>
          )}
          {current.flag_note && (
            <div style={{ marginTop: 12, padding: 10, background: "#fff8ed", borderRadius: 8, fontSize: 13, color: "#875b14" }}>
              <strong>Flagged:</strong> {current.flag_note}
            </div>
          )}
        </div>

        <EditForm question={current} imageUrl={currentImageUrl} projectId={id} />

        <div className="btn-stack" style={{ marginTop: 16 }}>
          <form action={verifyAndRedirect}>
            <input type="hidden" name="question_id" value={current.id} />
            <input type="hidden" name="project_id" value={id} />
            <button className="button" type="submit">Looks good</button>
          </form>
          <FlagForm questionId={current.id} projectId={id} />
        </div>
      </section>
    </main>
  );
}
