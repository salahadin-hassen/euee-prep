# EUEE Content Studio

The internal authoring and review web application for EUEE source content. It
is intentionally separate from the Flutter application in the repository root.

## Development

```powershell
Copy-Item .env.example .env.local
npm install
npm run dev
```

Set the Supabase URL and publishable key in `.env.local`. The migration in
`supabase/migrations/` is the source of truth for the initial M1 schema and
RLS policies.

## Commands

```powershell
npm run typecheck
npm run lint
npm test
npm run build
```

The application does not contain Gemini credentials or a service-role key.
Python processing remains a later worker integration with
`tools/content_pipeline/`.

## M1.5 Security Model

The database is the security boundary. Authenticated clients do not receive
direct mutation privileges for projects, memberships, questions, workflow
metadata, or audit events. Server actions call narrow PostgreSQL RPC functions;
the RPCs derive the acting user from `auth.uid()`, acquire the parent project
lock, enforce authorization and state transitions, and write the audit event in
the same transaction.

### Role permissions

| Role | Project administration | Question review | Question content edits | Image management | Audit visibility |
| --- | --- | --- | --- | --- | --- |
| owner | All projects and assignments | Yes | Yes | Yes | All audit history |
| admin | All projects and assignments | Yes | Yes | Yes | All audit history |
| reviewer | Assigned papers | Yes | Yes while reviewable | Assigned papers | No audit history |
| uploader | Assigned papers | No verification workflow | No | Assigned papers while reviewable | No audit history |

### Project state machine

```text
draft -> in_review
in_review -> blocked
in_review -> ready_for_approval
blocked -> in_review
ready_for_approval -> approved
approved -> exported
approved -> in_review (admin/owner explicit question reopen only)
archived -> terminal
```

The database RPCs reject edits, flags, verification, image changes, and new
questions in `approved`, `exported`, and `archived` states. Approval requires a
locked project, locked questions, verified status and verification metadata on
every question, and valid attached image objects.

### Question mutation rules

- `edit_question` changes only question content fields and requires a reviewer,
  admin, or owner on a reviewable project.
- `flag_question` records a flag and moves the project to `blocked` when needed.
- `verify_question` sets `verified_by` from `auth.uid()` and `verified_at` from
  the database clock; clients cannot supply either value.
- `reopen_question` is an explicit admin/owner operation from `approved` back to
  `in_review`.
- `project_id`, `status`, `verified_by`, and `verified_at` are not directly
  writable by authenticated clients.
- `correct_answer` must be empty for unresolved content or match one of the four
  stored choices. AI-derived answers remain non-authoritative.

### Images

Question images are stored in the private `question-images` bucket. Paths use
`{project_id}/{question_id}/{server-generated-file}` and are checked against
the actual question/project relationship. Uploads happen before database
attachment; the old object is removed only after the new reference commits.
Attached objects cannot be directly renamed or deleted through storage policy;
the detach RPC makes an old object unreferenced before cleanup. Unreferenced
objects are safe cleanup candidates for a scheduled garbage-collection job.

### Audit events

`audit_events` is append-only for normal authenticated clients. Project
creation, assignments, question creation and edits, flags, verification,
reopens, image changes, status changes, and approval are written by the
canonical security-definer RPCs. Reviewers cannot insert or read administrative
audit history.
