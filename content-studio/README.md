# EUEE Content Studio

Internal authoring and review web application for EUEE exam content. Separate
from the Flutter student app in the repository root.

## Architecture

```text
Browser → Next.js (Vercel) → Supabase (PostgreSQL + Storage + Auth)
                                    ↑
Worker (GitHub Actions) ←── API Routes (shared-secret auth)
```

### User journey

```text
Login → Papers → Create paper → Upload PDF → Extract
  → Worker claims job → Gemini extracts questions → Staging
  → Auto-promotion to review → Assign ranges → Review/Edit/Flag/Verify
  → Admin approves
```

### Worker

GitHub Actions workflow runs `tools/content_pipeline/providers/github_actions_worker.py`.
Claims jobs via API, downloads PDF from Supabase Storage, runs Gemini extraction,
uploads results page-by-page, completes and promotes questions.

## Development

```powershell
Copy-Item .env.example .env.local
npm install
npm run dev
```

Required environment variables (by name):

- `NEXT_PUBLIC_SUPABASE_URL` — Supabase project URL
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` — Supabase anon key
- `SUPABASE_SERVICE_ROLE_KEY` — Service role key (server only)
- `WORKER_SHARED_SECRET` — Bearer token for worker API auth
- `GITHUB_ACTIONS_DISPATCH_TOKEN` — Fine-grained GitHub PAT
- `GITHUB_REPO_OWNER`, `GITHUB_REPO_NAME`, `GITHUB_WORKFLOW_FILE`
- `GEMINI_API_KEY`, `GEMINI_MODEL` — Worker environment
- `PIPELINE_VERSION` — Version label for extraction pipeline

## Commands

```powershell
npm run typecheck    # TypeScript check
npm run lint         # ESLint
npm test             # Node.js test runner (83 tests)
npm run build        # Production build
python -m unittest discover tools/content_pipeline/tests -v  # Python tests (80 tests)
```

## Security model

- RLS enabled on all tables; anon access revoked everywhere
- All mutations go through security-definer PostgreSQL RPCs
- Worker uses service-role key + shared-secret HTTP auth
- Source PDFs and extraction assets are private storage
- Audit events are append-only (no direct client writes)
- `promote_extraction_questions` is service_role only
- Promoted questions retain source page, source region, and AI answer evidence
- Reviewer access is scoped by paper/range assignments in PostgreSQL

## Cost

$0 operating cost under intended free tiers:

- Supabase free tier (500MB database, 1GB storage, 50K MAU)
- Vercel free tier (hobby plan)
- GitHub Actions free tier (2000 min/month)
- Gemini free tier (rate-limited, quota-aware extraction)

## Recovery

- Expired worker leases automatically requeue processing pages
- `claim_next_extraction_job` finds stale processing jobs
- Daily cron catches any missed jobs
- Failed extraction has a retry button in the UI
- Notifications are idempotent (no duplicates)

## Known limitations

- Export is not implemented (status transitions to `approved` only)
- No email/SMS/push notifications (in-app only)
- Reviewer assignment uses a unique display-name lookup (email invitations are not implemented)
- Automatic AI explanation generation is not implemented; reviewers can save drafts and final explanations after answer verification
- Gemini free tier has rate limits; large papers may hit quota

## Deployment

- Content Studio: Vercel (auto-deploys from `master`)
- Worker: GitHub Actions (daily cron + manual dispatch)
- Database: Supabase (migrations in `supabase/migrations/`)
