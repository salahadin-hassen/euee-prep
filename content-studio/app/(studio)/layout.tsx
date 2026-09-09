import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { dashboardPath } from "@/lib/auth/roles";
import { SignOutButton } from "@/components/sign-out-button";

export default async function StudioLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name, role")
    .eq("id", user.id)
    .single();
  const displayName = profile?.display_name || user.email || "You";

  return (
    <div className="shell">
      <aside className="sidebar">
        <Link className="brand" href="/dashboard">
          <span className="brand-mark">E</span>
          <span>Content Studio</span>
        </Link>
        <nav className="nav" aria-label="Workspace navigation">
          <Link href={dashboardPath(profile?.role as never)}>Overview</Link>
          <Link href="/projects">Papers</Link>
          <Link href="/assignments">My papers</Link>
        </nav>
        <div className="sidebar-note">
          Check questions, mark what looks right, flag anything off.
        </div>
        <SignOutButton />
      </aside>
      <div className="main">
        <header className="topbar">
          <div>
            <span className="eyebrow">EUEE content studio</span>
          </div>
          <div className="user-chip">
            <span>{displayName}</span>
            <span className="avatar">{displayName.slice(0, 1).toUpperCase()}</span>
          </div>
        </header>
        {children}
      </div>
    </div>
  );
}
