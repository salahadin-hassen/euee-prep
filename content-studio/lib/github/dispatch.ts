/**
 * Server-side GitHub Actions workflow dispatch client.
 *
 * This module is the ONLY place in Content Studio that talks to GitHub.
 * The browser never sees the dispatch token.
 *
 * Required env vars (all server-side, never NEXT_PUBLIC_*):
 *   GITHUB_ACTIONS_DISPATCH_TOKEN  – fine-grained PAT with actions:write on this repo
 *   GITHUB_REPO_OWNER              – repository owner (e.g. "salahadin-hassen")
 *   GITHUB_REPO_NAME               – repository name  (e.g. "euee-prep")
 *   GITHUB_WORKFLOW_FILE           – workflow file name (e.g. "euee-extraction-worker.yml")
 */

export interface DispatchResult {
  ok: boolean;
  error?: string;
}

/**
 * Dispatch the extraction worker GitHub Actions workflow for a specific job.
 *
 * Sends only the job ID as the workflow input — no PDF contents, no signed URLs,
 * no Gemini keys, no Supabase credentials.
 */
export async function dispatchExtractionWorker(jobId: string): Promise<DispatchResult> {
  const token = process.env.GITHUB_ACTIONS_DISPATCH_TOKEN;
  const owner = process.env.GITHUB_REPO_OWNER;
  const repo = process.env.GITHUB_REPO_NAME;
  const workflowFile = process.env.GITHUB_WORKFLOW_FILE;

  if (!token || !owner || !repo || !workflowFile) {
    console.error("[github-dispatch] Missing required env vars: GITHUB_ACTIONS_DISPATCH_TOKEN, GITHUB_REPO_OWNER, GITHUB_REPO_NAME, GITHUB_WORKFLOW_FILE");
    return { ok: false, error: "GitHub dispatch not configured" };
  }

  const url = `https://api.github.com/repos/${owner}/${repo}/actions/workflows/${workflowFile}/dispatches`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/vnd.github.v3+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ref: "master",
        inputs: { job_id: jobId },
      }),
      signal: AbortSignal.timeout(10_000),
    });

    if (response.ok || response.status === 204) {
      console.log(`[github-dispatch] Workflow dispatched for job ${jobId}`);
      return { ok: true };
    }

    const body = await response.text();
    console.error(`[github-dispatch] GitHub API returned ${response.status}: ${body.slice(0, 200)}`);
    return { ok: false, error: `GitHub API ${response.status}` };
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error(`[github-dispatch] Network error: ${msg}`);
    return { ok: false, error: msg };
  }
}
