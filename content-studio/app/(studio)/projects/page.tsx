import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function ProjectsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: projectRows } = await supabase.from("projects").select("id, title, subject, exam_year, status").order("updated_at", { ascending: false });
  const projects = projectRows ?? [];

  return <main className="content"><section className="hero"><div><p className="eyebrow">Source-led work queue</p><h1>Projects.</h1><p className="lede">Only projects allowed by the database policy appear here.</p></div></section><section className="panel"><div className="panel-head"><h2>Visible projects</h2></div>{projects.length === 0 ? <p className="empty">No projects are available for this account.</p> : projects.map((project) => <div className="project-row" key={project.id}><div><Link className="project-title" href={`/projects/${project.id}`}>{project.title}</Link><div className="project-meta">{project.subject} · EC {project.exam_year}</div></div><span className="badge">{project.status.replaceAll("_", " ")}</span></div>)}</section></main>;
}
