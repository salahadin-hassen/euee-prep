# EUEE Content Studio M0/M1 Architecture

The Content Studio is a separate Next.js application under `content-studio/`.
It shares the repository with the Flutter application but does not import or
modify Flutter code. The Python content pipeline remains an external worker
boundary; Gemini credentials will never be present in browser code.

## M0 decisions

- Next.js App Router and TypeScript are the web boundary.
- Supabase SSR clients are split between browser, server component, and request
  proxy contexts.
- `proxy.ts` refreshes the Supabase session and provides the first redirect for
  unauthenticated protected routes. Server layouts/pages repeat authorization
  checks so frontend navigation is not a security boundary.
- The publishable Supabase key is the only browser configuration value. A
  service-role key is intentionally absent.

## M1 authorization model

`profiles.role` is the source of truth for `owner`, `admin`, `reviewer`, and
`uploader`. New Auth users receive the least-privileged `uploader` role through
the database trigger. Promotion is an administrative database operation.

Projects are visible through `is_project_member(project_id)`, which allows
owners/admins, project creators, and explicit project members. Reviewers can
read only their own membership rows. Audit events and the complete profile list
are admin/owner-only. These policies are in
`supabase/migrations/20260908000000_initial_content_studio.sql` and are the
actual authorization boundary for direct Supabase calls.

The UI intentionally does not load reviewer analytics, other reviewers'
decisions, private notes, or audit events on reviewer routes. Later slices will
add question-level policy functions rather than broadening a reviewer role.

## Later integration boundary

Processing jobs will invoke `tools/content_pipeline/` through a separately
executable worker. Its page artifacts and resumable state will be ingested into
authoring tables without changing the Flutter content-pack schema. An adapter
will isolate Gemini SDK/API changes from the web application.
