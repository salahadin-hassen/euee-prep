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
