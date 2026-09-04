# EUEE Prep — Implementation Roadmap

Status: v3 — reflects actual repository state. Milestone 0 is mostly complete (contracts written, Flutter skeleton and empty drift database scaffold committed; routing/state-management scaffolding and the custom lint configuration still pending). Mock-only presentation screens (subjects, payment, plus an uncommitted practice prototype) exist ahead of plan — they are presentation-layer stand-ins, not the data-driven screens later milestones build.

This roadmap sequences the MVP into milestones. Each milestone is a coherent, demoable slice. Each task inside a milestone is sized for one Git commit — small, reviewable, revertible independently. Every generated change should follow Decision 019's constraints (one feature/refactor at a time, compiles, formatted, ~500 lines/file ceiling).

**What changed from v1, and why:**

1. Content Pipeline moved to immediately after the Database milestone — real content is needed early to validate the data model and UI, not bolted on at the end where a schema mistake would be expensive to discover.
2. A Design System milestone now precedes all UI work (Decision 018) — tokens defined once, referenced everywhere, instead of screens each inventing their own styling that gets retrofitted later.
3. The roadmap now builds **one complete vertical slice** (one subject → one grade → one chapter → one topic → questions → explanation → weakness update → related resources) before expanding to all 12 subjects — this validates the whole architecture end-to-end while the blast radius of a wrong assumption is still small.
4. Entitlement architecture (data layer + access-control checks) moves much earlier — built into the foundation, not bolted onto the UI in Milestone 7 as before. Every repository from Milestone 1 onward is expected to respect entitlement checks from day one, not retrofitted later.

---

## Milestone 0 — Foundation

Nothing after this should start before it's done.

1. ~~Resolve the open subject-list visibility question~~ — **Resolved (Decision 029): the Subject list shows only the user's Preferred Stream; the other stream is never shown, locked or otherwise.**
2. ~~Write the database schema~~ — **Done:** `docs/database-schema.md` (v2, canonical — includes Entitlement, PaymentRequest, Exam, and install-identity tables).
3. ~~Write the coding standards~~ — **Done:** `docs/coding-standards.md` (v2 — Riverpod per Decision 025, drift per Decision 024).
4. `chore: initialize Flutter project skeleton` — **Done:** folder structure matching `docs/architecture.md`, no business logic.
5. ~~Write the Design System contract~~ — **Done:** `docs/design-system.md` — token names/shapes only, not implementation.
6. ~~Write the Content Pack Specification contract~~ — **Done:** `docs/content-pack-spec.md` (v2, with stable pack-local IDs and exam objects).
7. ~~Write the minimal API Contract~~ — **Done:** `docs/api-contract.md` (v2 — install identity, revocation, stream-scoped pack lookup).
8. `chore: add local database layer scaffold` — **Done:** empty drift schema v1 applied and generated (commit `8c2a1c6`).
9. `chore: add routing and state management scaffolding` — **Pending.**
10. `chore: add lint/format configuration` — **Pending** (a minimal baseline exists; the custom layering rule set described in `docs/coding-standards.md` is not configured yet).

---

## Milestone 1 — Core Data Layer

Goal: the curriculum model (Grade → Subject → Chapter → Topic → Question, Decision 010/011) exists in the database, correctly, before anything else touches it.

1. `feat: add Grade, Stream, Subject Local Data Sources and repositories` — content Local Data Sources enforce read-only access at this layer (Decision 015): no update/delete query methods exist, only insert (used by content import, Milestone 3). Repositories compose these Local Data Sources rather than executing SQL directly (Decision 026).
2. `chore: add ContentPack metadata prerequisite schema` — add only the `content_packs` persistence table and its version/identity constraints. This is required before Chapter/Topic because their `source_pack_id` foreign keys are non-nullable. This task does not implement pack import, validation, downloading, hosting, synchronization, or UI.
3. `feat: add Chapter and Topic entities and repositories` — Chapter→(Grade, Subject), Topic→Chapter, same read-only constraint. Their required `source_pack_id` foreign keys now reference the schema-only ContentPack metadata table.
4. `feat: add Question entity with many-to-many Topic mapping` — Decision 011; its own commit and dedicated tests given the relational complexity.
5. `feat: add Exam entity with ordered question membership` (Decision 038) — the `exams` and `exam_questions` tables plus their Local Data Source/repository; ordering is stored data, never inferred.
6. `feat: add Resource entity (notes, flashcards, mind maps) linked to Topic` — explanations are question-owned fields (Decision 037), never resources.
7. `feat: add Attempt entity as insert-only` — no update/delete operations exist for Attempt at all (Decision 016) — enforce this at the repository interface, not just by convention.
8. `test: add repository test suite with seed fixture data` — one subject's worth of fixture data (recommend Physics), including one full exam paper, used to prove the schema.

---

## Milestone 2 — Entitlement Foundation (moved earlier — was Milestone 7)

Goal: access control exists as a first-class concept before any content-serving code is written, so nothing downstream has to be retrofitted to respect it.

1. `feat: add persistent anonymous install identity` (Decision 032) — the singleton `install_identity` table, its Local Data Source/repository, and first-launch generation. Everything below keys off it.
2. `feat: add Entitlement entity and repository` (Decisions 012, 033) — one-to-many install→stream, `active | revoked`, revocable server-side, cached locally server→device only.
3. `feat: add PaymentRequest entity and repository` (Decisions 013, 023, 036) — unique request ID as canonical identifier; exactly `pending | verified | rejected` from the start.
4. `feat: add entitlement-check service` (Decision 026 — this lives in the Service Layer, not the repository layer) — a single, shared "is this install entitled to stream X" check that everything built on Milestone 1's repositories, going forward, calls through the Application layer before requesting content. This is the actual point of moving entitlement earlier: it becomes a foundational dependency, not a UI-layer bolt-on.
5. `test: add entitlement-check test suite` — covers zero-entitlement, single-entitlement, revoked, and (future-proofing) multi-entitlement states.

No payment UI yet — this milestone is data-layer and access-control logic only.

---

## Milestone 3 — Content Pipeline (moved earlier — was Milestone 8)

Goal: real content exists to validate the data model and UI against, before more UI gets built on synthetic fixtures alone. The schema-only `content_packs` metadata prerequisite is already provided by Milestone 1; this milestone implements the separate content-pack import system.

1. `feat: define content pack file format` — schema for a downloadable pack, including the versioning fields from Decision 021 (`pack_version`, `schema_version`, `generated_at`, `checksum`, `minimum_app_version`).
2. `feat: build content validation script` (Python) — catches malformed packs and missing versioning metadata before they ship.
3. `feat: build in-app pack import` — parses a downloaded pack into SQLite, verifies checksum, refuses packs below `minimum_app_version`, enforces immutability (Decision 015/021 — import is insert-only, never update-in-place).
4. `content: produce one real content pack` — one subject (Physics, matching Milestone 1's fixture choice), Grade 9-12, at least one multi-topic question, and at least one full exam paper (one EC year) with ordered questions — this is real content, not fixtures, and it's what the vertical slice (Milestone 5) will actually run against.

---

## Milestone 4 — Design System (NEW milestone, before any UI work)

Goal: `docs/design-system.md` exists and is implemented as reusable tokens/components before a single product screen is built.

1. ~~Write the Design System contract~~ — **Done:** `docs/design-system.md` — colors, typography, spacing, border radius, button variants, card variants, animation presets (Decision 018).
2. `feat: implement design tokens in core/design/` — a placeholder `core/design/tokens.dart` already exists from prototype screens; this task replaces it with the real, split token files (`colors.dart`, `typography.dart`, `spacing.dart`, `radius.dart`, `animations.dart`) without call-site changes.
3. `feat: build base component library` — buttons, cards, input fields, navigation shell — generic, reusable, not tied to any specific screen yet.

Nothing in Milestone 5+ should hand-roll styling that belongs in this layer.

---

## Milestone 5 — Vertical Slice (NEW — replaces the old breadth-first Milestones 3-6)

Goal: prove the entire architecture works end-to-end through exactly one path, before scaling to all 12 subjects. Scope is deliberately narrow:

**One subject (Physics) → one grade (e.g. Grade 11) → one chapter → one topic → questions → explanation → weakness update → related resources — plus one full exam paper (one EC year) taken as a timed simulation.**

1. `feat: build onboarding — Preferred Stream selection` (Decision 012 — freely changeable, no confirmation dialog needed)
2. `feat: build Subject list screen (single subject only)` — renders only the Preferred Stream's subjects; locked/preview state reflects entitlement for that stream (Decision 029).
3. `feat: build Subject detail screen (single chapter, single topic)` — Grade-grouped per Decision 014, but only one grade populated at this stage.
4. `feat: build question display and practice session flow (single topic's questions)`
5. `feat: record Attempt on answer submission` — exercises Milestone 1 task 6's insert-only constraint for real.
6. `feat: build answer review screen`
7. `feat: build topic-accuracy calculation for the one slice` — proves Decision 011's multi-topic attribution and Decision 016's recalculate-don't-store approach actually work against real data, not just unit-test fixtures.
8. `feat: build minimal weakness/focus-area display for the one topic`
9. `feat: link the one topic's weak result to its related note/flashcard/mind map`
10. `feat: wire entitlement check into the slice` — confirm Milestone 2's entitlement-check service actually gates this slice's content correctly (locked state if not entitled, full access if entitled).
11. `feat: build full timed single-sitting exam simulation for one exam paper` (Decision 030) — official-duration countdown, free question navigation, no per-question feedback, submit/time-up → review with answers and explanations; attempts recorded with mode `simulation` and the exam reference.

**Checkpoint after this milestone:** stop and review before scaling. This is the point where a wrong assumption is cheapest to fix — a schema problem discovered here costs one subject's worth of rework, not twelve.

---

## Milestone 6 — Horizontal Expansion

Goal: scale the proven vertical slice to full MVP breadth. Nothing here should require new architecture — if it does, that's a signal Milestone 5 didn't actually validate what it needed to.

1. `content: produce remaining 11 content packs` (parallelizable with engineering work)
2. `feat: expand Subject list to all 12 subjects`
3. `feat: expand Subject detail to full Grade 9-12 chapter range`
4. `feat: expand practice/review flow to all chapters/topics per subject`
5. `feat: expand weakness dashboard to cross-subject view`
6. `feat: expand resource viewers (notes, flashcards, mind maps) to full content`
7. `feat: expand full timed exam simulation to all published exam years per subject` (Decision 030 — simulation is v1 scope; this task scales it from the vertical slice's one paper to the full planned 2013–2018 EC range).

---

## Milestone 7 — Payment UI (was part of old Milestone 7; entitlement logic itself already done in Milestone 2)

Goal: the actual purchase flow, now sitting on top of an entitlement system that's already proven correct.

1. `feat: build locked/preview subject state UI` (full 12-subject version)
2. `feat: build payment instructions + proof submission screen` — surfaces the request ID from Decision 023 to the user.
3. `feat: add minimal backend endpoint(s) for payment request + admin verification` — first FastAPI work; narrow scope (Decision 013 — admin-verification surface, not a payment gateway). Backend only ever touches PaymentRequest, Entitlement, and content packs (Decision 017) — never Attempts or progress.
4. `feat: add entitlement refresh/check call and unlock wiring` — connects UI to Milestone 2's already-built entitlement-check service.

---

## Milestone 8 — Polish & Hardening

1. `feat: add empty/error states across all screens`
2. `test: offline-mode integration pass` (airplane-mode walkthrough of the full loop)
3. `test: performance budget verification` — startup time, navigation responsiveness, no-freeze check against Decision 020's targets, on a representative mid/low-end device if possible.
4. `chore: design system audit` — confirm no screen drifted from Milestone 4's tokens during Milestone 6's expansion.

---

## Open questions blocking specific tasks

None. All previously open questions are resolved:

* Exam simulation mode — full timed, single-sitting simulation is v1 (Decision 030).
* State management — Riverpod (Decision 025).
* SQLite package — drift (Decision 024).

---

## Suggested sequencing

Milestones 0 → 1 are strictly sequential. Milestone 2 (Entitlement) and Milestone 3 (Content Pipeline) can run in parallel once Milestone 1 is done — neither depends on the other. Milestone 4 (Design System) can also start in parallel with 2/3, since it doesn't depend on data-layer work at all. Milestone 5 (Vertical Slice) requires all of 1, 2, 3, and 4 to be done — it's the first point where everything comes together, which is exactly why it's the checkpoint. Milestone 6 only starts after Milestone 5's checkpoint review. Milestone 7 (Payment UI) can start as soon as Milestone 2 exists underneath it, so it's a reasonable candidate to run alongside Milestone 6 if you want revenue-path UI progressing in parallel with content-breadth work. Milestone 8 is last, always.
