"use server";

import { createClient } from "@/lib/supabase/server";

export interface NotificationRow {
  id: string;
  kind: string;
  title: string;
  body: string | null;
  read: boolean;
  created_at: string;
  project_id: string;
  job_id: string | null;
}

export async function listNotifications(): Promise<NotificationRow[]> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return [];

  const { data } = await supabase
    .from("notifications")
    .select("id, kind, title, body, read, created_at, project_id, job_id")
    .eq("user_id", user.id)
    .order("created_at", { ascending: false })
    .limit(50);

  return (data ?? []) as NotificationRow[];
}

export async function getUnreadCount(): Promise<number> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return 0;

  const { count } = await supabase
    .from("notifications")
    .select("id", { count: "exact", head: true })
    .eq("user_id", user.id)
    .eq("read", false);

  return count ?? 0;
}

export async function markNotificationsRead(ids: string[]): Promise<void> {
  if (ids.length === 0) return;
  const supabase = await createClient();
  await supabase.rpc("mark_notifications_read", { p_ids: ids });
}

export async function markAllRead(): Promise<void> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;

  const { data } = await supabase
    .from("notifications")
    .select("id")
    .eq("user_id", user.id)
    .eq("read", false);

  if (data && data.length > 0) {
    await supabase.rpc("mark_notifications_read", {
      p_ids: data.map((n) => n.id),
    });
  }
}
