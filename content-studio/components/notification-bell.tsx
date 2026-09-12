"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import type { NotificationRow } from "@/app/(studio)/_actions/notification";
import { markNotificationsRead, markAllRead } from "@/app/(studio)/_actions/notification";

const KIND_LABELS: Record<string, string> = {
  extraction_started: "Extraction started",
  extraction_completed: "Extraction complete",
  extraction_failed: "Extraction failed",
  extraction_issues: "Extraction completed with issues",
  review_assigned: "Review assigned",
  review_ready: "Review ready",
};

function timeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return `${days}d ago`;
}

export function NotificationBell({ initialNotifications, initialUnread }: {
  initialNotifications: NotificationRow[];
  initialUnread: number;
}) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [notifications, setNotifications] = useState(initialNotifications);
  const [unread, setUnread] = useState(initialUnread);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const toggle = useCallback(() => {
    setOpen((prev) => !prev);
  }, []);

  const markRead = useCallback(async (ids: string[]) => {
    await markNotificationsRead(ids);
    setNotifications((prev) => prev.map((n) => ids.includes(n.id) ? { ...n, read: true } : n));
    setUnread((prev) => Math.max(0, prev - ids.length));
  }, []);

  const markAll = useCallback(async () => {
    await markAllRead();
    setNotifications((prev) => prev.map((n) => ({ ...n, read: true })));
    setUnread(0);
  }, []);

  function handleNotificationClick(n: NotificationRow) {
    if (!n.read) markRead([n.id]);
    setOpen(false);
    if (n.assignment_id || n.kind === "extraction_completed" || n.kind === "extraction_issues" || n.kind === "review_assigned" || n.kind === "review_ready") {
      router.push(`/projects/${n.project_id}/review${n.assignment_id ? `?assignment=${n.assignment_id}` : ""}`);
    } else {
      router.push(`/projects/${n.project_id}`);
    }
  }

  return (
    <div className="notification-bell" ref={ref}>
      <button
        className="bell-button"
        type="button"
        onClick={toggle}
        aria-label={`Notifications${unread > 0 ? ` (${unread} unread)` : ""}`}
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
          <path d="M13.73 21a2 2 0 0 1-3.46 0" />
        </svg>
        {unread > 0 && <span className="bell-badge">{unread > 9 ? "9+" : unread}</span>}
      </button>

      {open && (
        <div className="notification-dropdown">
          <div className="dropdown-header">
            <span>Notifications</span>
            {unread > 0 && (
              <button className="signout" type="button" onClick={markAll}>
                Mark all read
              </button>
            )}
          </div>
          {notifications.length === 0 ? (
            <div className="dropdown-empty">No notifications yet.</div>
          ) : (
            <div className="dropdown-list">
              {notifications.map((n) => (
                <button
                  key={n.id}
                  className={`dropdown-item ${n.read ? "" : "unread"}`}
                  type="button"
                  onClick={() => handleNotificationClick(n)}
                >
                  <div className="item-title">{KIND_LABELS[n.kind] ?? n.kind}</div>
                  <div className="item-body">{n.title} &mdash; {n.body}</div>
                  <div className="item-time">{timeAgo(n.created_at)}</div>
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
