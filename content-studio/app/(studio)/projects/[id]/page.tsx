import { redirect, notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";
import { InviteForm } from "./invite-form";
import { RevokeButton } from "./revoke-button";
import { ExportButton } from "./export-button";
import { approveProject } from "../../_actions/approval";
import { ImportQuestionsForm } from "./import-questions-form";

export const dynamic = "force-dynamic";

interface ProjectRow {
  id: string;
  title: string;
  exam_year: number;
  subject: string;
  stream: string;
  status: string;
  created_by: string;
}

interface MemberRow {
  user_id: string;
  role: string;
  profiles: { display_name: string | null } | null;
}

interface AssignmentRow {
  id: string;
  reviewer_id: string;
  start_order_index: number | null;
  end_order_index: number | null;
  status: string;
  profiles: { display_name: string | null } | null;
}

interface QuestionSummary {
  id: string;
  order_index: number;
  question_text: string;
  status: string;
  flag_note: string | null;
  image_path: string | null;
  source_pdf_page: number | null;
  ai_predicted_choice_index: number | null;
  correct_answer: string;
}

function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

export default async function PaperDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  if (!isValidUuid(id)) notFound();

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  const role = (profile?.role || "uploader") as AppRole;
  const isAdmin = canAccessAdminSurface(role);

  const { data: project } = await supabase
    .from("projects")
    .select("id, title, exam_year, subject, stream, status, created_by")
    .eq("id", id)
    .single();

  if (!project) notFound();
  const typed = project as ProjectRow;

  const { data: memberRows } = await supabase
    .from("project_members")
    .select("user_id, role, profiles(display_name)")
    .eq("project_id", id)
    .order("assigned_at", { ascending: true });

  const members = (memberRows ?? []) as unknown as MemberRow[];

  const { data: assignmentRows } = isAdmin
    ? await supabase
        .from("review_assignments")
        .select("id, reviewer_id, start_order_index, end_order_index, status")
        .eq("project_id", id)
        .order("assigned_at", { ascending: true })
    : { data: [] };
  const rawAssignments = assignmentRows ?? [];
  const reviewerIds = rawAssignments.map((assignment) => assignment.reviewer_id);
  const { data: assignmentReviewerProfiles } = reviewerIds.length > 0
    ? await supabase.from("profiles").select("id, display_name").in("id", reviewerIds)
    : { data: [] };
  const profileById = new Map((assignmentReviewerProfiles ?? []).map((profile) => [profile.id, profile]));
  const assignments = rawAssignments.map((assignment) => ({
    ...assignment,
    profiles: profileById.get(assignment.reviewer_id) ?? null,
  })) as unknown as AssignmentRow[];

  const { count: totalQuestions } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id);

  const { count: verifiedQuestions } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id)
    .eq("status", "verified");

  const { count: flaggedQuestions } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id)
    .eq("status", "flagged");

  const { count: unverifiedCount } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id)
    .eq("status", "unverified");

  const assignmentProgress: Record<string, { verified: number; total: number }> = {};
  let allQuestionsForList: QuestionSummary[] = [];

  if ((totalQuestions ?? 0) > 0) {
    const { data: allQuestions } = await supabase
      .from("questions")
      .select("id, order_index, question_text, status, flag_note, image_path, source_pdf_page, ai_predicted_choice_index, correct_answer")
      .eq("project_id", id)
      .order("order_index", { ascending: true });

    allQuestionsForList = (allQuestions ?? []) as QuestionSummary[];

    for (const assignment of assignments) {
      const start = assignment.start_order_index;
      const end = assignment.end_order_index;
      const scoped = allQuestionsForList.filter((q) => {
        if (start === null || end === null) return true;
        return q.order_index >= start && q.order_index <= end;
      });
      assignmentProgress[assignment.id] = {
        verified: scoped.filter((q) => q.status === "verified").length,
        total: scoped.length,
      };
    }
  }

  const { data: reviewerProfiles } = isAdmin
    ? await supabase
        .from("profiles")
        .select("id, display_name")
        .eq("role", "reviewer")
        .order("display_name", { ascending: true })
    : { data: [] };
  const reviewerList = (reviewerProfiles ?? []) as { id: string; display_name: string | null }[];

  const hasQuestions = (totalQuestions ?? 0) > 0;
  const flaggedList = allQuestionsForList.filter((q) => q.status === "flagged");
  const needsAttention = allQuestionsForList.filter((q) =>
    q.status === "flagged"
    || q.status === "unverified"
    || !q.correct_answer
  );

  return (
    <main className="content">
      <div className="paper-header">
        <Link className="back-link" href="/projects">Papers</Link>
        <h1>{typed.title}</h1>
        <div className="paper-meta">
          {typed.subject} &middot; EC {typed.exam_year} &middot;{" "}
          {typed.stream === "natural_science" ? "Natural Science" : "Social Science"}
          <span className="badge" style={{ marginLeft: 12 }}>
            {friendlyStatus(typed.status)}
          </span>
        </div>
      </div>

      {hasQuestions && (
        <div className="qa-stats">
          <div className="qa-stat">
            <span className="qa-stat-value">{totalQuestions}</span>
            <span className="qa-stat-label">Questions</span>
          </div>
          <div className="qa-stat">
            <span className="qa-stat-value">{verifiedQuestions ?? 0} / {totalQuestions}</span>
            <span className="qa-stat-label">Verified</span>
          </div>
          <div className="qa-stat">
            <span className="qa-stat-value">{unverifiedCount ?? 0}</span>
            <span className="qa-stat-label">Unchecked</span>
          </div>
          {(flaggedQuestions ?? 0) > 0 && (
            <div className="qa-stat qa-stat--flagged">
              <span className="qa-stat-value">{flaggedQuestions}</span>
              <span className="qa-stat-label">Flagged</span>
            </div>
          )}
          {isAdmin && typed.status === "ready_for_approval" && (
            <div className="qa-stat">
              <form action={approveProject}>
                <input type="hidden" name="project_id" value={typed.id} />
                <button className="button button-sm" type="submit">Approve</button>
              </form>
            </div>
          )}
          {isAdmin && typed.status === "approved" && (
            <div className="qa-stat">
              <ExportButton projectId={typed.id} />
            </div>
          )}
        </div>
      )}

      {hasQuestions && typed.status !== "approved" && (
        <div className="paper-actions">
          <Link className="button" href={`/projects/${id}/review`}>
            Review questions {"\u2192"}
          </Link>
        </div>
      )}

      {isAdmin && !hasQuestions && (
        <ImportQuestionsForm projectId={typed.id} />
      )}

      {hasQuestions && !typed.status.startsWith("approved") && (
        <div className="panel" style={{ background: "#e8f5f0", border: "none" }}>
          <p style={{ margin: 0, fontWeight: 700 }}>
            {"\u2713"} {totalQuestions} question{totalQuestions !== 1 ? "s" : ""} imported &middot; ready for review
          </p>
        </div>
      )}

      {isAdmin && flaggedList.length > 0 && (
        <section className="panel panel--flagged">
          <div className="panel-head">
            <h2>Issues ({flaggedList.length})</h2>
          </div>
          {flaggedList.map((q) => (
            <div className="question-row question-row--flagged" key={q.id}>
              <div className="question-row-info">
                <Link className="question-row-link" href={`/projects/${id}/review?q=${q.order_index + 1}`}>
                  Q{q.order_index + 1}
                </Link>
                <span className="question-row-text">
                  {q.question_text.length > 80 ? q.question_text.slice(0, 80) + "..." : q.question_text}
                </span>
              </div>
              <div className="question-row-meta">
                {q.flag_note && <span className="flag-note">{q.flag_note}</span>}
              </div>
            </div>
          ))}
        </section>
      )}

      {isAdmin && needsAttention.length > 0 && needsAttention.length !== flaggedList.length && (
        <section className="panel">
          <div className="panel-head">
            <h2>Needs attention ({needsAttention.length})</h2>
          </div>
          <p className="project-meta" style={{ margin: 0 }}>
            Unchecked questions or questions with extraction issues
          </p>
        </section>
      )}

      {members.length > 0 && (
        <section className="panel">
          <div className="panel-head">
            <h2>Team</h2>
          </div>
          {members.map((m) => (
            <div className="project-row" key={m.user_id}>
              <div className="project-title">
                {m.profiles?.display_name || "Someone"}
              </div>
              <span className="badge">{m.role}</span>
            </div>
          ))}
        </section>
      )}

      {isAdmin && assignments.length > 0 && (
        <section className="panel">
          <div className="panel-head"><h2>Review assignments</h2></div>
          {assignments.map((assignment) => {
            const progress = assignmentProgress[assignment.id];
            const rangeLabel = assignment.start_order_index === null
              ? "Whole paper"
              : `Questions ${assignment.start_order_index + 1}\u2013${(assignment.end_order_index ?? assignment.start_order_index) + 1}`;
            const statusLabel = assignment.status === "in_progress"
              ? "In progress"
              : assignment.status === "completed"
                ? "Completed"
                : "Assigned";
            return (
              <div className="assignment-row" key={assignment.id}>
                <div className="assignment-info">
                  <div className="project-title">{assignment.profiles?.display_name || "Reviewer"}</div>
                  <div className="project-meta">{rangeLabel}</div>
                  {progress && (
                    <div className="assignment-progress">
                      {progress.verified} / {progress.total} verified
                    </div>
                  )}
                </div>
                <div className="assignment-actions">
                  <span className={`badge badge--${assignment.status === "completed" ? "completed" : assignment.status === "in_progress" ? "active" : "assigned"}`}>
                    {statusLabel}
                  </span>
                  <RevokeButton assignmentId={assignment.id} />
                </div>
              </div>
            );
          })}
        </section>
      )}

      {isAdmin && <InviteForm projectId={typed.id} reviewers={reviewerList} totalQuestions={totalQuestions ?? 0} />}

      {isAdmin && hasQuestions && (
        <section className="panel">
          <div className="panel-head">
            <h2>Questions ({totalQuestions})</h2>
          </div>
          <div className="question-list">
            {allQuestionsForList.map((q) => {
              const statusIcon = q.status === "verified" ? "\u2713" : q.status === "flagged" ? "\u26A0" : "\u25CB";
              const statusClass = q.status === "verified" ? "ql-verified" : q.status === "flagged" ? "ql-flagged" : "ql-unverified";
              return (
                <div className={`question-list-item ${statusClass}`} key={q.id}>
                  <Link className="question-list-link" href={`/projects/${id}/review?q=${q.order_index + 1}`}>
                    <span className="question-list-num">Q{q.order_index + 1}</span>
                    <span className="question-list-status">{statusIcon}</span>
                    <span className="question-list-text">
                      {q.question_text.length > 60 ? q.question_text.slice(0, 60) + "..." : q.question_text}
                    </span>
                  </Link>
                </div>
              );
            })}
          </div>
        </section>
      )}
    </main>
  );
}
