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
  completed: "Done",
  completed_with_errors: "Done (some errors)",
  quota_exhausted: "Quota exhausted",
  failed: "Failed",
  cancelled: "Cancelled",
};

export function friendlyJobStatus(status: string): string {
  return JOB_STATUS_LABELS[status] ?? status;
}
