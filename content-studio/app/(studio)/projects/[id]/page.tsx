import { redirect, notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";
import { InviteForm } from "./invite-form";
import { approveProject } from "../../_actions/approval";

export const dynamic = "force-dynamic";

interface ProjectRow {
  id: string;
  title: string;
  exam_year: number;
  subject: string;
  stream: string;
  status: string;
  created_by: string;
  created_at: string;
  updated_at: string;
}

interface MemberRow {
  user_id: string;
  role: string;
  assigned_at: string;
  profiles: { display_name: string | null } | null;
}

function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

function friendlyStatus(status: string): string {
  const map: Record<string, string> = {
    draft: "Getting started",
    processing: "Being prepared",
    in_review: "Being reviewed",
    blocked: "On hold",
    ready_for_approval: "Almost done",
    approved: "All done",
    exported: "Sent out",
    archived: "Archived",
  };
  return map[status] ?? status;
}

export default async function PaperDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  if (!isValidUuid(id)) notFound();

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  const role = (profile?.role || "uploader") as AppRole;
  const isAdmin = canAccessAdminSurface(role);

  const { data: project } = await supabase
    .from("projects")
    .select("id, title, exam_year, subject, stream, status, created_by, created_at, updated_at")
    .eq("id", id)
    .single();

  if (!project) notFound();

  const typed = project as ProjectRow;

  const { data: memberRows } = await supabase
    .from("project_members")
    .select("user_id, role, assigned_at, profiles(display_name)")
    .eq("project_id", id)
    .order("assigned_at", { ascending: true });

  const members = (memberRows ?? []) as unknown as MemberRow[];
  const canUploadSource = isAdmin || (role === "uploader" && members.some((member) => member.user_id === user.id));

  const { count: totalQuestions } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id);

  const { count: verifiedQuestions } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id)
    .eq("status", "verified");

  const { count: flaggedQuestions } = await supabase
    .from("questions")
    .select("id", { count: "exact", head: true })
    .eq("project_id", id)
    .eq("status", "flagged");

  const hasQuestions = (totalQuestions ?? 0) > 0;

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Paper</p>
          <h1>{typed.title}</h1>
          <p className="lede">
            {typed.subject} &middot; EC {typed.exam_year} &middot;{" "}
            {typed.stream === "natural_science" ? "Natural Science" : "Social Science"}
          </p>
        </div>
        <Link className="button" href="/projects">
          Back to papers
        </Link>
      </section>

      <div className="grid">
        <div className="stat">
          <div className="stat-label">Status</div>
          <div className="stat-value">{friendlyStatus(typed.status)}</div>
        </div>
        {hasQuestions && (
          <>
            <div className="stat">
              <div className="stat-label">Progress</div>
              <div className="stat-value">{verifiedQuestions ?? 0} / {totalQuestions ?? 0}</div>
            </div>
            <div className="stat">
              <div className="stat-label">Flagged</div>
              <div className="stat-value">{flaggedQuestions ?? 0}</div>
            </div>
          </>
        )}
      </div>

      {hasQuestions && typed.status !== "approved" && (
        <section className="panel">
          <div className="panel-head">
            <h2>Review questions</h2>
          </div>
          <p className="empty" style={{ marginBottom: 16 }}>
            {verifiedQuestions === totalQuestions
              ? "All questions verified — this paper is done!"
              : `${verifiedQuestions ?? 0} of ${totalQuestions ?? 0} verified so far.`}
          </p>
          <Link className="button" href={`/projects/${id}/review`}>
            Start reviewing
          </Link>
        </section>
      )}

      {typed.status === "approved" && (
        <section className="panel">
          <div className="panel-head">
            <h2>All done!</h2>
          </div>
          <p className="empty">
            Every question has been verified. This paper is ready.
          </p>
        </section>
      )}

      {isAdmin && typed.status === "ready_for_approval" && (
        <section className="panel">
          <div className="panel-head">
            <h2>Ready for approval</h2>
          </div>
          <p className="empty" style={{ marginBottom: 16 }}>
            Every question is verified. Approval checks the complete paper atomically.
          </p>
          <form action={approveProject}>
            <input type="hidden" name="project_id" value={typed.id} />
            <button className="button" type="submit">Approve paper</button>
          </form>
        </section>
      )}

      <section className="panel">
        <div className="panel-head">
          <h2>Source extraction</h2>
        </div>
        <p className="empty" style={{ marginBottom: 16 }}>
          Upload private exam PDFs and queue selected pages for extraction.
        </p>
        <Link className="button" href={`/projects/${id}/extract`}>
          {canUploadSource ? "Open extraction" : "View extraction jobs"}
        </Link>
      </section>

      <section className="panel">
        <div className="panel-head">
          <h2>People helping out</h2>
          <span className="badge">{members.length}</span>
        </div>
        {members.length === 0 ? (
          <p className="empty">Nobody&apos;s been invited yet.</p>
        ) : (
          members.map((m) => (
            <div className="project-row" key={m.user_id}>
              <div>
                <div className="project-title">
                  {m.profiles?.display_name || "Someone"}
                </div>
                <div className="project-meta">
                  Joined {new Date(m.assigned_at).toLocaleDateString("en-US", {
                    year: "numeric",
                    month: "long",
                    day: "numeric",
                  })}
                </div>
              </div>
            </div>
          ))
        )}
      </section>

      {isAdmin && <InviteForm projectId={typed.id} />}

      <section className="panel">
        <div className="panel-head">
          <h2>Paper details</h2>
        </div>
        <div className="project-row">
          <div>
            <div className="project-title">Created</div>
            <div className="project-meta">
              {new Date(typed.created_at).toLocaleDateString("en-US", {
                year: "numeric",
                month: "long",
                day: "numeric",
              })}
            </div>
          </div>
        </div>
        <div className="project-row">
          <div>
            <div className="project-title">Last updated</div>
            <div className="project-meta">
              {new Date(typed.updated_at).toLocaleDateString("en-US", {
                year: "numeric",
                month: "long",
                day: "numeric",
              })}
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
