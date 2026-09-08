import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export const dynamic = "force-dynamic";

export default async function AssignmentsPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: membershipRows } = await supabase.from("project_members").select("project_id, role, assigned_at").eq("user_id", user.id);
  const memberships = membershipRows ?? [];
  return <main className="content"><section className="hero"><div><p className="eyebrow">Reviewer queue</p><h1>My assignments.</h1><p className="lede">Assignment details are scoped to your own account. Question-level work arrives in the next review slice.</p></div></section><section className="panel"><div className="panel-head"><h2>Assigned projects</h2></div>{memberships.length === 0 ? <p className="empty">No assignments are available.</p> : memberships.map((membership) => <div className="project-row" key={membership.project_id}><div><div className="project-title">Project assignment</div><div className="project-meta">Role: {membership.role}</div></div><span className="badge">Assigned</span></div>)}</section></main>;
}
