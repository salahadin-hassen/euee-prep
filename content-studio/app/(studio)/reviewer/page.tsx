import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

function friendlyStatus(status: string): string {
  const map: Record<string, string> = {
    draft: "Getting started",
    processing: "Being prepared",
    in_review: "Being reviewed",
    blocked: "On hold",
    ready_for_approval: "Almost done",
    approved: "All done",
    exported: "Sent out",
    archived: "Archived",
  };
  return map[status] ?? status;
}

export default async function ReviewerDashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: membershipRows } = await supabase
    .from("project_members")
    .select("project_id, role, assigned_at")
    .eq("user_id", user.id);
  const memberships = membershipRows ?? [];
  const projectIds = memberships.map((m) => m.project_id);

  const projectResult = projectIds.length === 0
    ? { data: [] }
    : await supabase
        .from("projects")
        .select("id, title, subject, exam_year, status")
        .in("id", projectIds)
        .order("updated_at", { ascending: false });
  const projects = projectResult.data ?? [];

  let totalUnverified = 0;
  let totalFlagged = 0;
  for (const pid of projectIds) {
    const { count: u } = await supabase
      .from("questions")
      .select("id", { count: "exact", head: true })
      .eq("project_id", pid)
      .eq("status", "unverified");
    const { count: f } = await supabase
      .from("questions")
      .select("id", { count: "exact", head: true })
      .eq("project_id", pid)
      .eq("status", "flagged");
    totalUnverified += u ?? 0;
    totalFlagged += f ?? 0;
  }

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Your workspace</p>
          <h1>Papers you&apos;re helping with</h1>
          <p className="lede">
            Check questions, mark what looks right, flag anything that seems off.
          </p>
        </div>
      </section>
      <div className="grid">
        <div className="stat">
          <div className="stat-label">Papers</div>
          <div className="stat-value">{projects.length}</div>
        </div>
        <div className="stat">
          <div className="stat-label">Waiting to review</div>
          <div className="stat-value">{totalUnverified}</div>
        </div>
        <div className="stat">
          <div className="stat-label">Flagged</div>
          <div className="stat-value">{totalFlagged}</div>
        </div>
      </div>
      <section className="panel">
        <div className="panel-head">
          <h2>Your papers</h2>
        </div>
        {projects.length === 0 ? (
          <p className="empty">No papers to review yet. Someone will invite you when there&apos;s work to do.</p>
        ) : (
          projects.map((project) => (
            <div className="project-row" key={project.id}>
              <div>
                <Link className="project-title" href={`/projects/${project.id}`}>
                  {project.title}
                </Link>
                <div className="project-meta">
                  {project.subject} &middot; EC {project.exam_year}
                </div>
              </div>
              <span className="badge">{friendlyStatus(project.status)}</span>
            </div>
          ))
        )}
      </section>
    </main>
  );
}
