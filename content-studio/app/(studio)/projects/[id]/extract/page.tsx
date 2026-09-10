import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { isAdminRole, type AppRole } from "@/lib/auth/roles";
import { ExtractionForm } from "./extraction-form";
import { JobStatus } from "./job-status";

export const dynamic = "force-dynamic";

function isValidUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

interface SourceDocument {
  id: string;
  original_filename: string;
}

interface ExtractionJob {
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

export default async function ExtractionPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  if (!isValidUuid(id)) notFound();

  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");

  const { data: project } = await supabase.from("projects").select("id, title").eq("id", id).single();
  if (!project) notFound();

  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  const role = profile?.role as AppRole | undefined;
  const { data: membership } = await supabase
    .from("project_members")
    .select("role")
    .eq("project_id", id)
    .eq("user_id", user.id)
    .maybeSingle();
  const canUpload = !!role && (isAdminRole(role) || membership?.role === "uploader");

  const [{ data: documents }, { data: jobs }] = await Promise.all([
    supabase.from("source_documents").select("id, original_filename").eq("project_id", id).order("created_at", { ascending: false }),
    supabase.from("extraction_jobs").select("id, source_document_id, requested_pages, status, total_pages, completed_pages, failed_pages, created_at, completed_at").eq("project_id", id).order("created_at", { ascending: false }),
  ]);
  const sourceDocuments = (documents ?? []) as SourceDocument[];
  const extractionJobs = (jobs ?? []) as ExtractionJob[];
  const sourceNameById = new Map(sourceDocuments.map((document) => [document.id, document.original_filename]));

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Extraction · {project.title}</p>
          <h1>Source papers</h1>
          <p className="lede">Store an immutable private PDF and queue selected pages for later processing.</p>
        </div>
        <Link className="button" href={`/projects/${id}`}>Back to paper</Link>
      </section>

      {canUpload && <ExtractionForm projectId={id} />}

      {!canUpload && (
        <section className="panel">
          <p className="empty">You can view extraction jobs for this paper, but only assigned uploaders and administrators can add source PDFs.</p>
        </section>
      )}

      <section className="panel">
        <div className="panel-head">
          <h2>Extraction jobs</h2>
          <Link className="signout" href={`/projects/${id}/extract`}>Refresh the page to update</Link>
        </div>
        {extractionJobs.length === 0 ? (
          <p className="empty">No extraction jobs have been queued.</p>
        ) : (
          extractionJobs.map((job) => (
            <JobStatus
              key={job.id}
              projectId={id}
              job={job}
              sourceName={sourceNameById.get(job.source_document_id) ?? "Source PDF"}
            />
          ))
        )}
      </section>
    </main>
  );
}
