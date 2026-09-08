import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { dashboardPath, isAdminRole, type AppRole } from "@/lib/auth/roles";
import { SignOutButton } from "@/components/sign-out-button";

export default async function StudioLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: profile } = await supabase.from("profiles").select("display_name, role").eq("id", user.id).single();
  const role = (profile?.role || "uploader") as AppRole;
  const displayName = profile?.display_name || user.email || "Workspace user";

  return <div className="shell">
    <aside className="sidebar">
      <Link className="brand" href="/dashboard"><span className="brand-mark">E</span><span>Content Studio</span></Link>
      <nav className="nav" aria-label="Workspace navigation">
        <Link href={dashboardPath(role)}>Overview</Link>
        <Link href="/projects">Projects</Link>
        {!isAdminRole(role) && <Link href="/assignments">My assignments</Link>}
        {isAdminRole(role) && <Link href="/admin/reviewers">Reviewers</Link>}
      </nav>
      <div className="sidebar-note">Source artifacts remain immutable. Working edits and decisions are recorded separately.</div>
      <SignOutButton />
    </aside>
    <div className="main"><header className="topbar"><div><span className="eyebrow">EUEE authoring</span></div><div className="user-chip"><span>{displayName}</span><span className="badge">{role}</span><span className="avatar">{displayName.slice(0, 1).toUpperCase()}</span></div></header>{children}</div>
  </div>;
}
