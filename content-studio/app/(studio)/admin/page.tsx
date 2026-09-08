import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";

export const dynamic = "force-dynamic";

export default async function AdminDashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  if (!profile || !canAccessAdminSurface(profile.role as AppRole)) redirect("/reviewer");

  const { data: projectRows } = await supabase.from("projects").select("id, title, subject, exam_year, status").order("updated_at", { ascending: false });
  const projects = projectRows ?? [];

  return <main className="content">
    <section className="hero"><div><p className="eyebrow">Admin overview</p><h1>Keep the source chain intact.</h1><p className="lede">Manage projects, assignments, and approval readiness. Collaboration details are visible here, not in reviewer workspaces.</p></div><button className="button">New project</button></section>
    <div className="grid"><div className="stat"><div className="stat-label">Projects</div><div className="stat-value">{projects.length}</div></div><div className="stat"><div className="stat-label">Questions verified</div><div className="stat-value">—</div></div><div className="stat"><div className="stat-label">Conflicts</div><div className="stat-value">—</div></div></div>
    <section className="panel"><div className="panel-head"><h2>Authoring projects</h2><span className="badge">Admin only</span></div>{projects.length === 0 ? <p className="empty">No projects yet. Upload an authentic source to begin the authoring chain.</p> : projects.map((project) => <div className="project-row" key={project.id}><div><div className="project-title">{project.title}</div><div className="project-meta">{project.subject} · EC {project.exam_year}</div></div><span className="badge">{project.status.replaceAll("_", " ")}</span></div>)}</section>
  </main>;
}
