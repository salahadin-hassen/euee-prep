import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";
import { readJson, requireWorkerSecret } from "@/lib/worker/auth";

export async function POST(request: NextRequest) {
  const unauthorized = requireWorkerSecret(request);
  if (unauthorized) return unauthorized;
  try {
    const body = await readJson(request);
    if (typeof body.job_id !== "string" || typeof body.worker_id !== "string") return NextResponse.json({ error: "Invalid renewal request" }, { status: 400 });
    const { error } = await createServiceClient().rpc("renew_extraction_job_lease", {
      p_job_id: body.job_id, p_worker_id: body.worker_id, p_lease_seconds: 1800,
    });
    if (error) return NextResponse.json({ error: "Could not renew lease" }, { status: 409 });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "Invalid worker request" }, { status: 400 });
  }
}
