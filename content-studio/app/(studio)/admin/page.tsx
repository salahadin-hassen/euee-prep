import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";

export const dynamic = "force-dynamic";

export default async function AdminPage() {
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
  if (!profile || !canAccessAdminSurface(profile.role as AppRole)) {
    redirect("/projects");
  }

  const { data: projects } = await supabase
    .from("projects")
    .select("id, title, subject, exam_year, status")
    .order("updated_at", { ascending: false });

  return (
    <main className="content">
      <section className="hero">
        <div>
          <h1>Admin</h1>
        </div>
        <Link className="button" href="/projects/new">
          New paper
        </Link>
      </section>

      <section className="panel">
        <div className="panel-head">
          <h2>All papers</h2>
        </div>
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
