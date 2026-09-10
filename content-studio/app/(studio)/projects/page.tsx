import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { isAdminRole, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";

export const dynamic = "force-dynamic";

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

  let projectsQuery = supabase
    .from("projects")
    .select("id, title, subject, exam_year, status");

  if (!admin) {
    const { data: membershipRows } = await supabase
      .from("project_members")
      .select("project_id")
      .eq("user_id", user.id);
    const projectIds = (membershipRows ?? []).map((m) => m.project_id);
    if (projectIds.length === 0) {
      return (
        <main className="content">
          <h1>Papers</h1>
          <p className="empty">No papers assigned to you yet.</p>
        </main>
      );
    }
    projectsQuery = projectsQuery.in("id", projectIds);
  }

  const { data: projects } = await projectsQuery.order("updated_at", {
    ascending: false,
  });

  return (
    <main className="content">
      <section className="hero">
        <h1>Papers</h1>
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
          projects.map((p) => (
            <div className="project-row" key={p.id}>
              <div>
                <Link className="project-title" href={`/projects/${p.id}`}>
                  {p.title}
                </Link>
                <div className="project-meta">
                  {p.subject} &middot; EC {p.exam_year}
                </div>
              </div>
              <span className="badge">{friendlyStatus(p.status)}</span>
            </div>
          ))
        )}
      </section>
    </main>
  );
}
