import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { canAccessReviewerSurface, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";

export const dynamic = "force-dynamic";

export default async function ReviewerPage() {
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
  if (!profile || !canAccessReviewerSurface(profile.role as AppRole)) {
    redirect("/projects");
  }

  const { data: membershipRows } = await supabase
    .from("project_members")
    .select("project_id")
    .eq("user_id", user.id);
  const memberships = membershipRows ?? [];
  const projectIds = memberships.map((m) => m.project_id);

  const projectResult =
    projectIds.length === 0
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
      <h1>Papers</h1>
      {(totalUnverified > 0 || totalFlagged > 0) && (
        <div className="review-stats">
          {totalUnverified > 0 && (
            <span className="stat-inline">
              {totalUnverified} waiting
            </span>
          )}
          {totalFlagged > 0 && (
            <span className="stat-inline stat-flagged">
              {totalFlagged} flagged
            </span>
          )}
        </div>
      )}

      <section className="panel">
        {projects.length === 0 ? (
          <p className="empty">No papers assigned yet.</p>
        ) : (
          projects.map((project) => (
            <div className="project-row" key={project.id}>
              <div>
                <Link
                  className="project-title"
                  href={`/projects/${project.id}`}
                >
                  {project.title}
                </Link>
                <div className="project-meta">
                  {project.subject} &middot; EC {project.exam_year}
                </div>
              </div>
              <span className="badge">
                {friendlyStatus(project.status)}
              </span>
            </div>
          ))
        )}
      </section>
    </main>
  );
}
