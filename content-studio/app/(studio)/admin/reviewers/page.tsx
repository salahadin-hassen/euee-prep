import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";

export const dynamic = "force-dynamic";

export default async function ReviewersPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  if (!profile || !canAccessAdminSurface(profile.role as AppRole)) redirect("/reviewer");
  const { data: reviewerRows } = await supabase.from("profiles").select("id, display_name, role").in("role", ["reviewer", "uploader"]);
  const reviewers = reviewerRows ?? [];

  return <main className="content"><section className="hero"><div><p className="eyebrow">Admin-only collaboration</p><h1>Reviewers.</h1><p className="lede">Manage who can participate in projects. Reviewer performance and private decisions never appear in reviewer routes.</p></div></section><section className="panel"><div className="panel-head"><h2>Workspace users</h2><span className="badge">Admin only</span></div>{reviewers.length === 0 ? <p className="empty">No reviewers have been provisioned.</p> : reviewers.map((reviewer) => <div className="project-row" key={reviewer.id}><div><div className="project-title">{reviewer.display_name || "Unnamed user"}</div><div className="project-meta">{reviewer.role}</div></div><span className="badge">Active</span></div>)}</section></main>;
}
