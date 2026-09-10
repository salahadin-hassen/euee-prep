import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";
import { requireWorkerSecret } from "@/lib/worker/auth";

export async function POST(request: NextRequest) {
  const unauthorized = requireWorkerSecret(request);
  if (unauthorized) return unauthorized;
  const jobId = request.headers.get("x-job-id") ?? "";
  const workerId = request.headers.get("x-worker-id") ?? "";
  const assetKey = request.headers.get("x-asset-key") ?? "";
  if (!/^[0-9a-fA-F-]{36}$/.test(jobId) || !/^[A-Za-z0-9._:-]{1,128}$/.test(workerId) || !/^[A-Za-z0-9._:-]{1,160}$/.test(assetKey)) {
    return NextResponse.json({ error: "Invalid asset request" }, { status: 400 });
  }
  if (request.headers.get("content-type") !== "image/png") return NextResponse.json({ error: "Only PNG assets are accepted" }, { status: 415 });

  const supabase = createServiceClient();
  const { data: job } = await supabase.from("extraction_jobs").select("claimed_by, status").eq("id", jobId).single();
  if (!job || job.status !== "processing" || job.claimed_by !== workerId) return NextResponse.json({ error: "Job is not owned by this worker" }, { status: 409 });

  const storagePath = `${jobId}/${assetKey.replace(/[^A-Za-z0-9._:-]/g, "_")}.png`;
  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.length === 0 || bytes.length > 5 * 1024 * 1024) return NextResponse.json({ error: "Asset size is invalid" }, { status: 413 });
  const { data: existing } = await supabase.storage.from("extraction-assets").list(jobId, { search: `${assetKey}.png`, limit: 1 });
  if (!existing || existing.length === 0) {
    const { error } = await supabase.storage.from("extraction-assets").upload(storagePath, bytes, { contentType: "image/png", upsert: false });
    if (error) return NextResponse.json({ error: "Could not store visual asset" }, { status: 409 });
  }
  return NextResponse.json({ storage_path: storagePath }, { headers: { "Cache-Control": "no-store" } });
}
