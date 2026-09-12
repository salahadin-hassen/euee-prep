import { redirect, notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";
import { InviteForm } from "./invite-form";
import { approveProject } from "../../_actions/approval";
import { InlineExtraction } from "./inline-extraction";

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

interface ExtractJob {
  id: string;
  source_document_id: string;
  requested_pages: number[];
  status: string;
  total_pages: number;
  completed_pages: number;
  failed_pages: number;
  created_at: string;
  completed_at: string | null;
}

function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

function ExtractionSummary({ jobs, questionCount }: { jobs: ExtractJob[]; questionCount: number }) {
  const latest = jobs[0];
  if (!latest) return null;

  const isActive = latest.status === "queued" || latest.status === "processing";
  const isComplete = latest.status === "completed";
  const hasIssues = latest.status === "completed_with_errors";
  const isFailed = latest.status === "failed";

  if (isActive) {
    return (
      <div className="extraction-summary extraction-summary--processing">
        <span className="extraction-summary-icon" aria-hidden="true">{"\u25CC"}</span>
        <span>
          Extracting {latest.completed_pages} / {latest.requested_pages.length} pages
        </span>
      </div>
    );
  }

  if (isComplete) {
    return (
      <div className="extraction-summary extraction-summary--ready">
        <span className="extraction-summary-icon" aria-hidden="true">{"\u2713"}</span>
        <span>
          Ready for review &middot; {questionCount} question{questionCount !== 1 ? "s" : ""} ready
        </span>
      </div>
    );
  }

  if (hasIssues) {
    return (
      <div className="extraction-summary extraction-summary--issues">
        <span className="extraction-summary-icon" aria-hidden="true">{"\u26A0"}</span>
        <span>
          Completed with issues ({latest.completed_pages} of {latest.requested_pages.length} pages)
          {questionCount > 0 && <> &middot; {questionCount} question{questionCount !== 1 ? "s" : ""} ready</>}
        </span>
      </div>
    );
  }

  if (isFailed) {
    return (
      <div className="extraction-summary extraction-summary--failed">
        <span className="extraction-summary-icon" aria-hidden="true">{"\u2717"}</span>
        <span>Extraction failed</span>
      </div>
    );
  }

  return null;
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
  const canUploadSource = isAdmin || (role === "uploader" && members.some((m) => m.user_id === user.id));

  const { data: assignmentRows } = isAdmin
    ? await supabase
        .from("review_assignments")
        .select("id, reviewer_id, start_order_index, end_order_index, status")
        .eq("project_id", id)
        .order("assigned_at", { ascending: true })
    : { data: [] };
  const rawAssignments = assignmentRows ?? [];
  const reviewerIds = rawAssignments.map((assignment) => assignment.reviewer_id);
  const { data: reviewerProfiles } = reviewerIds.length > 0
    ? await supabase.from("profiles").select("id, display_name").in("id", reviewerIds)
    : { data: [] };
  const profileById = new Map((reviewerProfiles ?? []).map((profile) => [profile.id, profile]));
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

  const hasQuestions = (totalQuestions ?? 0) > 0;

  const [{ data: extractionJobs }] = await Promise.all([
    supabase
      .from("extraction_jobs")
      .select("id, source_document_id, requested_pages, status, total_pages, completed_pages, failed_pages, created_at, completed_at")
      .eq("project_id", id)
      .order("created_at", { ascending: false }),
  ]);

  const jobs = (extractionJobs ?? []) as ExtractJob[];

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

      {jobs.length > 0 && !typed.status.startsWith("approved") && (
        <ExtractionSummary jobs={jobs} questionCount={totalQuestions ?? 0} />
      )}

      <InlineExtraction
        projectId={typed.id}
        jobs={jobs}
        canUpload={canUploadSource}
      />

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
          {assignments.map((assignment) => (
            <div className="project-row" key={assignment.id}>
              <div>
                <div className="project-title">{assignment.profiles?.display_name || "Reviewer"}</div>
                <div className="project-meta">
                  {assignment.start_order_index === null
                    ? "Whole paper"
                    : `Questions ${assignment.start_order_index + 1}-${(assignment.end_order_index ?? assignment.start_order_index) + 1}`}
                </div>
              </div>
              <span className="badge">{assignment.status}</span>
            </div>
          ))}
        </section>
      )}

      {isAdmin && <InviteForm projectId={typed.id} />}
    </main>
  );
}
