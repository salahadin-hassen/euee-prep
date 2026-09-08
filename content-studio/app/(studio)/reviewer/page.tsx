import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { canAccessReviewerSurface, type AppRole } from "@/lib/auth/roles";

export const dynamic = "force-dynamic";

export default async function ReviewerDashboardPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  if (!profile || !canAccessReviewerSurface(profile.role as AppRole)) redirect("/login");

  const { data: membershipRows } = await supabase.from("project_members").select("project_id, role, assigned_at").eq("user_id", user.id);
  const memberships = membershipRows ?? [];
  const projectIds = memberships.map((membership) => membership.project_id);
  const projectResult = projectIds.length === 0 ? { data: [] } : await supabase.from("projects").select("id, title, subject, exam_year, status").in("id", projectIds).order("updated_at", { ascending: false });
  const projects = projectResult.data ?? [];

  return <main className="content">
    <section className="hero"><div><p className="eyebrow">Reviewer workspace</p><h1>Your assigned work.</h1><p className="lede">Compare source pages with AI assistance, then record your own decisions. Other reviewers' private decisions stay hidden until an admin resolves a conflict.</p></div></section>
    <div className="grid"><div className="stat"><div className="stat-label">Assigned projects</div><div className="stat-value">{projects.length}</div></div><div className="stat"><div className="stat-label">Pending questions</div><div className="stat-value">—</div></div><div className="stat"><div className="stat-label">My flagged items</div><div className="stat-value">—</div></div></div>
    <section className="panel"><div className="panel-head"><h2>My assignments</h2><span className="badge">Private view</span></div>{projects.length === 0 ? <p className="empty">No assignments are waiting for you.</p> : projects.map((project) => <div className="project-row" key={project.id}><div><div className="project-title">{project.title}</div><div className="project-meta">{project.subject} · EC {project.exam_year}</div></div><span className="badge">{project.status.replaceAll("_", " ")}</span></div>)}</section>
  </main>;
}
