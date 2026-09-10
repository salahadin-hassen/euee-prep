import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";
import { readJson, requireWorkerSecret } from "@/lib/worker/auth";

export async function POST(request: NextRequest) {
  const unauthorized = requireWorkerSecret(request);
  if (unauthorized) return unauthorized;
  try {
    const body = await readJson(request);
    if (typeof body.job_id !== "string" || typeof body.worker_id !== "string") return NextResponse.json({ error: "Invalid completion request" }, { status: 400 });

    const supabase = createServiceClient();

    // Fetch job info before completing (for notification)
    const { data: jobBefore } = await supabase
      .from("extraction_jobs")
      .select("project_id, created_by, completed_pages, failed_pages, requested_pages")
      .eq("id", body.job_id)
      .single();

    const { data, error } = await supabase.rpc("complete_extraction_job", {
      p_job_id: body.job_id, p_worker_id: body.worker_id,
    });
    if (error) return NextResponse.json({ error: "Could not complete job" }, { status: 409 });

    // Create completion notification for the job creator
    if (jobBefore) {
      const finalStatus = data as string;
      const kind = finalStatus === "completed" ? "extraction_completed"
        : finalStatus === "completed_with_errors" ? "extraction_issues"
        : "extraction_failed";

      const totalPages = Array.isArray(jobBefore.requested_pages) ? jobBefore.requested_pages.length : 0;
      const bodyText = finalStatus === "completed"
        ? `All ${totalPages} page${totalPages !== 1 ? "s" : ""} extracted successfully`
        : `${jobBefore.completed_pages} of ${totalPages} pages completed, ${jobBefore.failed_pages} failed`;

      const { data: projectRow } = await supabase
        .from("projects")
        .select("title")
        .eq("id", jobBefore.project_id)
        .single();

      await supabase.rpc("create_notification", {
        p_user_id: jobBefore.created_by,
        p_project_id: jobBefore.project_id,
        p_job_id: body.job_id,
        p_kind: kind,
        p_title: projectRow?.title ?? "Paper",
        p_body: bodyText,
      });
    }

    return NextResponse.json({ status: data });
  } catch {
    return NextResponse.json({ error: "Invalid worker request" }, { status: 400 });
  }
}
