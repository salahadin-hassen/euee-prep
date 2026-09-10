const STATUS_LABELS: Record<string, string> = {
  draft: "Draft",
  processing: "Processing",
  in_review: "In review",
  blocked: "Blocked",
  ready_for_approval: "Ready to approve",
  approved: "Approved",
  exported: "Exported",
  archived: "Archived",
};

export function friendlyStatus(status: string): string {
  return STATUS_LABELS[status] ?? status;
}

const JOB_STATUS_LABELS: Record<string, string> = {
  queued: "Queued",
  processing: "Processing",
  completed: "Ready for review",
  completed_with_errors: "Completed with issues",
  quota_exhausted: "Quota exhausted",
  failed: "Extraction failed",
  cancelled: "Cancelled",
};

export function friendlyJobStatus(status: string): string {
  return JOB_STATUS_LABELS[status] ?? status;
}

export function jobStatusIcon(status: string): string {
  switch (status) {
    case "queued": return "\u25CB";
    case "processing": return "\u25CC";
    case "completed": return "\u2713";
    case "completed_with_errors": return "\u26A0";
    case "failed": return "\u2717";
    case "cancelled": return "\u2716";
    default: return "\u25CB";
  }
}
