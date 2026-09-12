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

    // Promote staged extraction questions into reviewable questions
    const { data: promoted } = await supabase.rpc("promote_extraction_questions", {
      p_job_id: body.job_id,
    });
    const promotedCount = (promoted as number) ?? 0;

    // Create completion notification (idempotent: check existing)
    if (jobBefore) {
      const finalStatus = data as string;
      const kind = finalStatus === "completed" ? "extraction_completed"
        : finalStatus === "completed_with_errors" ? "extraction_issues"
        : "extraction_failed";
      const totalPages = Array.isArray(jobBefore.requested_pages) ? jobBefore.requested_pages.length : 0;
      const { data: projectRow } = await supabase
        .from("projects")
        .select("title")
        .eq("id", jobBefore.project_id)
        .single();
      const titleText = projectRow?.title ?? "Paper";
      let bodyText: string;
      if (finalStatus === "completed") {
        bodyText = promotedCount > 0
          ? `${promotedCount} question${promotedCount !== 1 ? "s" : ""} ready for review`
          : `All ${totalPages} page${totalPages !== 1 ? "s" : ""} extracted successfully`;
      } else if (finalStatus === "completed_with_errors") {
        bodyText = promotedCount > 0
          ? `${promotedCount} question${promotedCount !== 1 ? "s" : ""} ready; ${jobBefore.failed_pages} page${jobBefore.failed_pages !== 1 ? "s" : ""} failed`
          : `${jobBefore.completed_pages} of ${totalPages} pages completed, ${jobBefore.failed_pages} failed`;
      } else {
        bodyText = `${titleText} could not be processed`;
      }

      const { data: existingNotification } = await supabase
        .from("notifications")
        .select("id")
        .eq("job_id", body.job_id)
        .eq("user_id", jobBefore.created_by)
        .in("kind", ["extraction_completed", "extraction_issues", "extraction_failed"])
        .limit(1)
        .maybeSingle();

      if (!existingNotification) {
        await supabase.rpc("create_notification", {
          p_user_id: jobBefore.created_by,
          p_project_id: jobBefore.project_id,
          p_job_id: body.job_id,
          p_kind: kind,
          p_title: titleText,
          p_body: bodyText,
        });

      }

      const { data: assignments } = await supabase
        .from("review_assignments")
        .select("id, reviewer_id")
        .eq("project_id", jobBefore.project_id)
        .neq("status", "completed");
      for (const assignment of assignments ?? []) {
        const { data: reviewerNotification } = await supabase
          .from("notifications")
          .select("id")
          .eq("job_id", body.job_id)
          .eq("user_id", assignment.reviewer_id)
          .in("kind", ["extraction_completed", "extraction_issues", "extraction_failed"])
          .limit(1)
          .maybeSingle();
        if (!reviewerNotification) {
          await supabase.rpc("create_notification", {
            p_user_id: assignment.reviewer_id,
            p_project_id: jobBefore.project_id,
            p_job_id: body.job_id,
            p_kind: kind,
            p_title: titleText,
            p_body: bodyText,
            p_assignment_id: assignment.id,
          });
        }
      }
    }

    return NextResponse.json({ status: data, promoted: promotedCount });
  } catch {
    return NextResponse.json({ error: "Invalid worker request" }, { status: 400 });
  }
}
