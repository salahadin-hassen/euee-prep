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

export default async function AssignmentsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: membershipRows } = await supabase
    .from("project_members")
    .select("project_id, assigned_at")
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

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Your papers</p>
          <h1>Papers you&apos;re helping with</h1>
          <p className="lede">
            Click into a paper to start reviewing questions.
          </p>
        </div>
      </section>
      <section className="panel">
        <div className="panel-head">
          <h2>Your papers</h2>
        </div>
        {projects.length === 0 ? (
          <p className="empty">No papers to review yet.</p>
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
