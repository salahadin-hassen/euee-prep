import { redirect, notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";
import { InviteForm } from "./invite-form";
import { RevokeButton } from "./revoke-button";
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

  const assignmentProgress: Record<string, { verified: number; total: number }> = {};
  if (assignments.length > 0 && (totalQuestions ?? 0) > 0) {
    const { data: allQuestions } = await supabase
      .from("questions")
      .select("order_index, status")
      .eq("project_id", id);

    for (const assignment of assignments) {
      const start = assignment.start_order_index;
      const end = assignment.end_order_index;
      const scoped = (allQuestions ?? []).filter((q) => {
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
        <div className="paper-stats">
          <span className="stat-inline">
            {verifiedQuestions ?? 0}/{totalQuestions ?? 0} verified
          </span>
          {(flaggedQuestions ?? 0) > 0 && (
            <span className="stat-inline stat-flagged">
              {flaggedQuestions} flagged
            </span>
          )}
          {isAdmin && typed.status === "ready_for_approval" && (
            <form action={approveProject} style={{ display: "inline" }}>
              <input type="hidden" name="project_id" value={typed.id} />
              <button className="button button-sm" type="submit">
                Approve
              </button>
            </form>
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
    </main>
  );
}
