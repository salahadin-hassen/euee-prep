import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { isAdminRole, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";

export const dynamic = "force-dynamic";

interface ReviewAssignment {
  id: string;
  project_id: string;
  start_order_index: number | null;
  end_order_index: number | null;
  status: string;
}

export default async function PapersPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  const role = (profile?.role || "uploader") as AppRole;
  const admin = isAdminRole(role);

  let projectsQuery = supabase.from("projects").select("id, title, subject, exam_year, status");
  let assignments: ReviewAssignment[] = [];

  if (!admin && role === "reviewer") {
    const { data: assignmentRows } = await supabase
      .from("review_assignments")
      .select("id, project_id, start_order_index, end_order_index, status")
      .eq("reviewer_id", user.id)
      .neq("status", "completed")
      .order("assigned_at", { ascending: false });
    assignments = (assignmentRows ?? []) as ReviewAssignment[];
    const projectIds = assignments.map((assignment) => assignment.project_id);
    if (projectIds.length === 0) {
      return (
        <main className="content">
          <h1>My review work</h1>
          <p className="empty">Nothing is assigned to you yet.</p>
        </main>
      );
    }
    projectsQuery = projectsQuery.in("id", projectIds);
  } else if (!admin) {
    return (
      <main className="content">
        <h1>My review work</h1>
        <p className="empty">Nothing is assigned to you yet.</p>
      </main>
    );
  }

  const { data: projects } = await projectsQuery.order("updated_at", {
    ascending: false,
  });
  const workItems = admin
    ? (projects ?? []).map((paper) => ({ paper, assignment: null as ReviewAssignment | null }))
    : (projects ?? []).flatMap((paper) => assignments
      .filter((assignment) => assignment.project_id === paper.id)
      .map((assignment) => ({ paper, assignment })));

  return (
    <main className="content">
      <section className="hero">
        <h1>{admin ? "Papers" : "My review work"}</h1>
        {admin && (
          <Link className="button" href="/projects/new">
            New paper
          </Link>
        )}
      </section>

      <section className="panel">
        {!(projects?.length) ? (
          <p className="empty">No papers yet.</p>
        ) : (
          workItems.map(({ paper: p, assignment }) => {
            const rangeLabel = assignment?.start_order_index === null || !assignment
              ? "Whole paper"
              : `Questions ${assignment.start_order_index + 1}-${(assignment.end_order_index ?? assignment.start_order_index) + 1}`;
            const reviewHref = assignment
              ? `/projects/${p.id}/review?assignment=${assignment.id}`
              : `/projects/${p.id}`;
            return (
            <div className="project-row" key={p.id}>
              <div>
                <Link className="project-title" href={`/projects/${p.id}`}>
                  {p.title}
                </Link>
                <div className="project-meta">
                  {p.subject} &middot; EC {p.exam_year}
                  {!admin && <> &middot; {rangeLabel}</>}
                </div>
              </div>
              {admin ? (
                <span className="badge">{friendlyStatus(p.status)}</span>
              ) : (
                <Link className="button button-sm" href={reviewHref}>Continue review</Link>
              )}
            </div>
            );
          })
        )}
      </section>
    </main>
  );
}
