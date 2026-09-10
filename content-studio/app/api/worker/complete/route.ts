import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";
import { readJson, requireWorkerSecret } from "@/lib/worker/auth";

export async function POST(request: NextRequest) {
  const unauthorized = requireWorkerSecret(request);
  if (unauthorized) return unauthorized;
  try {
    const body = await readJson(request);
    if (typeof body.job_id !== "string" || typeof body.worker_id !== "string") return NextResponse.json({ error: "Invalid completion request" }, { status: 400 });
    const { data, error } = await createServiceClient().rpc("complete_extraction_job", {
      p_job_id: body.job_id, p_worker_id: body.worker_id,
    });
    if (error) return NextResponse.json({ error: "Could not complete job" }, { status: 409 });
    return NextResponse.json({ status: data });
  } catch {
    return NextResponse.json({ error: "Invalid worker request" }, { status: 400 });
  }
}
