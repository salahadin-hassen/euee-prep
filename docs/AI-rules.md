# EUEE Prep — AI Development Rules

This document is the working ruleset for AI-assisted implementation from this point forward. It sits alongside `docs/coding-standards.md` (which covers code-level conventions) and Decision 019/026 in `docs/decisions.md` (which cover the architectural reasoning behind these rules) — this file is the short, operational version meant to be checked before every task.

## Documentation authority

* The canonical specifications live in `docs/` under their current filenames (`project-context.md`, `project-requirements.md`, `architecture.md`, `decisions.md`, `database-schema.md`, `content-pack-spec.md`, `api-contract.md`, `coding-standards.md`, `design-system.md`, `implementation-roadmap.md`, `user-flow.md`, `AI-rules.md`). Numbered filenames referenced in older text (`04_ARCHITECTURE.md`, `05_DATABASE_SCHEMA.md`, `06_DESIGN_SYSTEM.md`, `07_CODING_STANDARDS.md`, `09_DECISIONS.md`, `10_IMPLEMENTATION_ROADMAP.md`, `CONTENT_PACK_SPEC.md`, `API_CONTRACT.md`) are historical names for the same documents.
* Later accepted decisions in `docs/decisions.md` supersede earlier statements — in this document set and in code comments. Never resurrect superseded text as authority; the decision log's supersession markers are binding.
* `docs/database-schema.md` is the single source of truth for table and column names; `docs/content-pack-spec.md` for the pack file format; `docs/api-contract.md` for the backend surface.
* When a task reveals a contradiction between documents (or between a document and the code), stop and flag it — do not resolve it silently in code.

* Never redesign architecture without approval.
* Never rename database tables or columns without updating schema docs.
* Never add packages without approval.
* Never modify folder structure without approval.
* One feature per commit.
* One logical task at a time.
* Maximum ~500 lines per handwritten file.
* Always explain architectural decisions.
* Always write tests for repositories and business logic.
* Never generate large portions of the app at once.