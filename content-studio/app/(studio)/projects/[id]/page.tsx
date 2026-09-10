import { redirect, notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";
import { friendlyStatus } from "@/lib/status";
import { InviteForm } from "./invite-form";
import { approveProject } from "../../_actions/approval";
import { InlineExtraction } from "./inline-extraction";

export const dynamic = "force-dynamic";

interface ProjectRow {
  id: string;
  title: string;
  exam_year: number;
  subject: string;
  stream: string;
  status: string;
  created_by: string;
}

interface MemberRow {
  user_id: string;
  role: string;
  profiles: { display_name: string | null } | null;
}

interface ExtractJob {
  id: string;
  source_document_id: string;
  requested_pages: number[];
  status: string;
  total_pages: number;
  completed_pages: number;
  failed_pages: number;
  created_at: string;
  completed_at: string | null;
}

function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
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
    .select("id, title, exam_year, subject, stream, status, created_by")
    .eq("id", id)
    .single();

  if (!project) notFound();
  const typed = project as ProjectRow;

  const { data: memberRows } = await supabase
    .from("project_members")
    .select("user_id, role, profiles(display_name)")
    .eq("project_id", id)
    .order("assigned_at", { ascending: true });

  const members = (memberRows ?? []) as unknown as MemberRow[];
  const canUploadSource = isAdmin || (role === "uploader" && members.some((m) => m.user_id === user.id));

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

  const [{ data: extractionJobs }] = await Promise.all([
    supabase
      .from("extraction_jobs")
      .select("id, source_document_id, requested_pages, status, total_pages, completed_pages, failed_pages, created_at, completed_at")
      .eq("project_id", id)
      .order("created_at", { ascending: false }),
  ]);

  return (
    <main className="content">
      <div className="paper-header">
        <Link className="back-link" href="/projects">Papers</Link>
        <h1>{typed.title}</h1>
        <div className="paper-meta">
          {typed.subject} &middot; EC {typed.exam_year} &middot;{" "}
          {typed.stream === "natural_science" ? "Natural Science" : "Social Science"}
          <span className="badge" style={{ marginLeft: 12 }}>
            {friendlyStatus(typed.status)}
          </span>
        </div>
      </div>

      {hasQuestions && (
        <div className="paper-stats">
          <span className="stat-inline">
            {verifiedQuestions ?? 0}/{totalQuestions ?? 0} verified
          </span>
          {(flaggedQuestions ?? 0) > 0 && (
            <span className="stat-inline stat-flagged">
              {flaggedQuestions} flagged
            </span>
          )}
          {isAdmin && typed.status === "ready_for_approval" && (
            <form action={approveProject} style={{ display: "inline" }}>
              <input type="hidden" name="project_id" value={typed.id} />
              <button className="button button-sm" type="submit">
                Approve
              </button>
            </form>
          )}
        </div>
      )}

      {hasQuestions && typed.status !== "approved" && (
        <div className="paper-actions">
          <Link className="button" href={`/projects/${id}/review`}>
            Review questions
          </Link>
        </div>
      )}

      <InlineExtraction
        projectId={typed.id}
        jobs={(extractionJobs ?? []) as ExtractJob[]}
        canUpload={canUploadSource}
      />

      {members.length > 0 && (
        <section className="panel">
          <div className="panel-head">
            <h2>Team</h2>
          </div>
          {members.map((m) => (
            <div className="project-row" key={m.user_id}>
              <div className="project-title">
                {m.profiles?.display_name || "Someone"}
              </div>
              <span className="badge">{m.role}</span>
            </div>
          ))}
        </section>
      )}

      {isAdmin && <InviteForm projectId={typed.id} />}
    </main>
  );
}
