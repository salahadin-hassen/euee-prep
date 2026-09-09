import Link from "next/link";
import { redirect } from "next/navigation";
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

export default async function PapersPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: projectRows } = await supabase
    .from("projects")
    .select("id, title, subject, exam_year, status")
    .order("updated_at", { ascending: false });
  const projects = projectRows ?? [];

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Your papers</p>
          <h1>Papers</h1>
          <p className="lede">
            Exam papers that need checking. Click into one to review questions.
          </p>
        </div>
      </section>
      <section className="panel">
        <div className="panel-head">
          <h2>All papers</h2>
        </div>
        {projects.length === 0 ? (
          <p className="empty">No papers yet. Create one to get started.</p>
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
