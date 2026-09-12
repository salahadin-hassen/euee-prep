import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";
import { readJson, requireWorkerSecret } from "@/lib/worker/auth";

export async function POST(request: NextRequest) {
  const unauthorized = requireWorkerSecret(request);
  if (unauthorized) return unauthorized;
  try {
    const body = await readJson(request);
    const workerId = body.worker_id;
    if (typeof workerId !== "string" || !/^[A-Za-z0-9._:-]{1,128}$/.test(workerId)) {
      return NextResponse.json({ error: "Invalid worker_id" }, { status: 400 });
    }
    const supabase = createServiceClient();
    const jobId = typeof body.job_id === "string" ? body.job_id : null;
    const { data: claim, error: claimError } = jobId
      ? await supabase.rpc("claim_extraction_job", {
          p_job_id: jobId,
          p_worker_id: workerId,
          p_lease_seconds: 1800,
        })
      : await supabase.rpc("claim_next_extraction_job", {
          p_worker_id: workerId,
          p_lease_seconds: 1800,
        });
    if (claimError) return NextResponse.json({ error: "Could not claim job" }, { status: 409 });
    if (!claim) return new NextResponse(null, { status: 204 });

    const job = claim as {
      job_id: string;
      project_id: string;
      source_document_id: string;
      storage_path: string;
      requested_pages: number[];
    };
    const { data: source, error: sourceError } = await supabase
      .from("source_documents")
      .select("sha256")
      .eq("id", job.source_document_id)
      .single();
    if (sourceError || !source) return NextResponse.json({ error: "Source document unavailable" }, { status: 409 });
    const { data: signed, error: signedError } = await supabase.storage
      .from("source-pdfs")
      .createSignedUrl(job.storage_path, 300);
    if (signedError || !signed?.signedUrl) return NextResponse.json({ error: "Could not sign source PDF" }, { status: 409 });

    return NextResponse.json({
      descriptor: {
        protocol_version: "1",
        job_id: job.job_id,
        project_id: job.project_id,
        source_document_id: job.source_document_id,
        requested_pages: job.requested_pages,
        pipeline_version: process.env.PIPELINE_VERSION ?? "ai-extraction-v1",
        result_schema_version: "1",
      },
      source_pdf_sha256: source.sha256,
      source_pdf_url: signed.signedUrl,
    }, { headers: { "Cache-Control": "no-store" } });
  } catch {
    return NextResponse.json({ error: "Invalid worker request" }, { status: 400 });
  }
}
