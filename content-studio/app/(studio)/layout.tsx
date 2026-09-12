import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { isAdminRole, type AppRole } from "@/lib/auth/roles";
import { SignOutButton } from "@/components/sign-out-button";
import { NotificationBell } from "@/components/notification-bell";
import { listNotifications, getUnreadCount } from "./_actions/notification";

export default async function StudioLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("display_name, role")
    .eq("id", user.id)
    .single();

  const role = (profile?.role || "uploader") as AppRole;
  const admin = isAdminRole(role);
  const displayName = profile?.display_name || user.email || "You";

  const [notifications, unread] = await Promise.all([
    listNotifications(),
    getUnreadCount(),
  ]);

  return (
    <div className="shell">
      <aside className="sidebar">
        <Link className="brand" href="/projects">
          <span className="brand-mark">E</span>
          <span>Studio</span>
        </Link>
        <nav className="nav" aria-label="Navigation">
          <Link href="/projects">Papers</Link>
        </nav>
        <div className="sidebar-bottom">
          <SignOutButton />
        </div>
      </aside>
      <div className="main">
        <header className="topbar">
          <div />
          <NotificationBell initialNotifications={notifications} initialUnread={unread} />
          <div className="user-chip">
            <span>{displayName}</span>
            <span className="avatar">
              {displayName.slice(0, 1).toUpperCase()}
            </span>
          </div>
        </header>
        {children}
      </div>
    </div>
  );
}
