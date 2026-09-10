# Content Worker

M2 Slice 2 uses GitHub Actions as the first provider adapter. The extraction
engine and result contract do not depend on GitHub and can be hosted elsewhere
later.

## Cost Boundary

The workflow uses one standard Ubuntu runner per scheduled invocation and
processes at most one queued job. GitHub's current GitHub Free allowance is
2,000 private-repository runner minutes per month and 500 MB of artifact
storage. Standard runners in public repositories do not consume paid minutes.
Usage beyond private-plan allowances can be billed, so billing must be
disabled or capped before enabling a private-repository deployment. When the
allowance is exhausted, the workflow must stop or remain queued; it must not
fall back to a paid runner.

The workflow never stores PDFs or extraction output as GitHub Actions
artifacts. PDFs remain in private Supabase Storage.

## Flow

```text
Content Studio job
  -> Supabase queued state
  -> scheduled GitHub worker polls claim-next
  -> server issues a five-minute signed PDF URL
  -> existing Python pipeline processes selected pages
  -> worker submits versioned page contracts
  -> Supabase stages extraction questions/assets
```

The job claim uses a Postgres lease. An expired lease can be reclaimed by a
later worker invocation. Page results are idempotent by deterministic question
and asset identities.

## Server Secrets

Configure these only in the deployment environment or GitHub Actions secrets:

```text
SUPABASE_SERVICE_ROLE_KEY  # Content Studio server only; never GitHub
WORKER_SHARED_SECRET       # Same secret in Content Studio and GitHub Actions
WORKER_CONTROL_URL         # Deployed Content Studio URL
GEMINI_API_KEY             # GitHub Actions secret only
GEMINI_MODEL               # GitHub Actions variable/secret
```

The GitHub worker never receives the Supabase service-role key. It uses the
shared worker secret to call the server-side control routes. Signed source URLs
are short-lived and are not persisted or logged.

## Local Development

The Python adapter can be run independently with the same environment values:

```powershell
$env:WORKER_CONTROL_URL = "http://localhost:3000"
$env:WORKER_SHARED_SECRET = "local-only-secret"
$env:WORKER_ID = "local-worker"
$env:GEMINI_API_KEY = "..."
$env:GEMINI_MODEL = "gemini-2.5-flash"
python tools/content_pipeline/providers/github_actions_worker.py
```

Do not use production credentials or production job IDs during local testing.
