import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";
import { readJson, requireWorkerSecret } from "@/lib/worker/auth";

export async function POST(request: NextRequest) {
  const unauthorized = requireWorkerSecret(request);
  if (unauthorized) return unauthorized;
  try {
    const body = await readJson(request);
    if (typeof body.job_id !== "string" || typeof body.worker_id !== "string" || typeof body.pdf_page !== "number" || !body.result || typeof body.result !== "object" || typeof body.result_checksum !== "string") {
      return NextResponse.json({ error: "Invalid page-result request" }, { status: 400 });
    }
    const { error } = await createServiceClient().rpc("record_extraction_page_result", {
      p_job_id: body.job_id, p_pdf_page: body.pdf_page, p_worker_id: body.worker_id,
      p_result: body.result, p_result_checksum: body.result_checksum,
      p_result_schema_version: "1",
    });
    if (error) return NextResponse.json({ error: "Could not record page result" }, { status: 409 });
    return NextResponse.json({ ok: true });
  } catch {
    return NextResponse.json({ error: "Invalid worker request" }, { status: 400 });
  }
}
