# EUEE Prep — Architecture

## Architecture Goals

The architecture should optimize for:

* Offline performance
* Low cost
* Maintainability
* Scalability
* Clean separation of concerns
* Easy AI-assisted development

---

# High-Level Architecture (UPDATED — Decision 026)

```
Flutter Application

        ↓

Presentation Layer

        ↓

Application Layer

        ↓

Service Layer          (NEW — business logic: weakness analysis, exam scoring, content import)

        ↓

Repository Layer       (coordinates Local Data Sources; no direct SQL anymore)

        ↓

Local Data Sources     (NEW — only layer allowed to execute Drift queries)

        ↓

Drift (SQLite)

        ↓

Downloaded Content Packs
```

---

# Frontend Architecture

Flutter follows a feature-based structure.

Example:

```
frontend/

lib/

├── core/
│   ├── design/                    (EXPANDED — Decision 018)
│   │   ├── colors.dart
│   │   ├── typography.dart
│   │   ├── spacing.dart
│   │   ├── radius.dart
│   │   ├── animations.dart
│   │   ├── buttons.dart
│   │   ├── cards.dart
│   │   └── input_fields.dart
│   ├── constants/
│   ├── database/                  (Drift instance lives here — only entry point to it)
│   ├── logging/                   (NEW — centralized logging abstraction, no print())
│   └── utilities/
│
├── features/
│
│   ├── streams/          (personalization only — Preferred Stream)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│
│   ├── entitlements/     (Purchased Stream + payment flow)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│
│   ├── exams/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│
│   ├── subjects/
│
│   ├── learning_resources/        (RENAMED/MERGED — was notes/, flashcards/, mindmaps/ as separate features)
│   │   ├── notes/
│   │   ├── flashcards/
│   │   └── mindmaps/
│
│   ├── content/                   (NEW — import, validate, update content packs; Decision 021)
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/          (admin/debug views only — no end-user UI at MVP)
│
│   ├── progress/                  (RENAMED from analytics/)
│
│   └── settings/
│
└── main.dart
```

Each feature also contains an `application/` folder (use cases) alongside `data/`, `domain/`, and `presentation/` — see the Application Layer section below. The design system lives in `core/design/` — the canonical path per Decision 018 (earlier drafts referred to this as `core/theme/`, which is obsolete).

`streams` handles Preferred Stream only — a personalization setting with no access-control responsibility (Decision 012). `entitlements` is a separate module handling Purchased Stream state and the payment-submission flow (Decision 013); it's split out because its lifecycle (submit proof → pending → verified) and its consequences (gates real content access) are fundamentally different from a simple UI preference, even though both concern "stream" conceptually.

`learning_resources` merges what were three separate feature folders (`notes`, `flashcards`, `mindmaps`) into one feature with subfolders — they share a parent concept (Topic-attached study material, Decision 011's one-to-many scope) and were splitting a small amount of logic across three module boundaries for no real benefit.

`content` is new — it owns pack import, validation, and update logic (Decision 021), separate from `subjects`/`exams` which only ever *read* already-imported content. This keeps the read-only content features from needing any awareness of how content gets onto the device in the first place.

`progress` replaces `analytics` — same responsibility (weakness/performance display), renamed because "analytics" implied tracking/telemetry, which this explicitly is not (Decision 017 — nothing here is sent to a server).

---

# Layer Responsibilities

## Presentation Layer

Responsible for:

* Screens
* Widgets
* User interaction
* UI state

Should not contain:

* Database logic
* Business rules

**Update:** the presentation layer must read two distinct pieces of global app state: **Preferred Stream** (personalization, drives default navigation per Decision 014) and **Purchased Stream(s)** (entitlement, drives what's actually openable). These must never be merged into a single "active stream" variable — see Decision 012.

Navigation itself is Subject-first (Decision 014): screens present Subject as the top-level browsing concept, with Grade as an in-page grouping inside a Subject's chapter list. Stream is not a navigation level the user drills through — it only surfaces at onboarding and in Settings.

---

## Application Layer

Responsible for:

* Use cases
* Application logic
* Coordinating features

Examples:

* Set/change Preferred Stream (personalization only, no access effect)
* Submit payment proof (Decision 013)
* Start exam
* Submit answer

Note: "Check entitlement status" and "Calculate performance" moved to the Service Layer below (Decision 026) — they're business logic, not use-case coordination.

Location: use cases live in `features/<feature>/application/` (one class per use case, e.g. `StartExamUseCase`, `SubmitPaymentProofUseCase`). A use case that spans features lives in the feature that owns the workflow and reaches the other feature through its `domain/` exports — it never imports another feature's `data/` layer directly. Use cases call Services (e.g. the entitlement check) and Repositories; they contain orchestration only, never business rules of their own.

---

## Service Layer (NEW — Decision 026)

Responsible for:

* Business logic that doesn't belong to any single screen or use case
* Coordinating one or more repositories to produce a result

Examples:

* Weakness/topic-accuracy analysis (reads Attempt + Question-Topic via repositories, produces Focus Areas — Decision 016)
* Entitlement checking (the shared utility every content-serving use case must call before requesting content from a repository — Decision 012. Services call repositories; repositories never call services or the entitlement check — access decisions are made above the repository layer, never inside it)
* Exam scoring
* Recommendation generation (which resource to surface after a wrong answer)
* Content pack import/validation orchestration (Decision 021) — coordinates the `content` feature's repositories

Rules:

* No Flutter imports — services are plain Dart, testable without a widget tree.
* Stateless where possible.
* Communicate only through repositories — never reach into a Local Data Source or Drift directly.

Why this layer exists: without it, business logic has nowhere principled to live except inside repositories (mixing data access with logic) or inside Riverpod providers (mixing business logic with UI state coordination). Both of those were realistic failure modes once entitlement-checking and weakness calculation were built for real.

---

## Repository Layer (UPDATED — Decision 026)

Responsible for:

* Coordinating one or more Local Data Sources
* Converting persistence models into domain models
* Hiding *which* Local Data Source(s) a piece of data came from

Repositories **no longer execute SQL directly.** That responsibility moved to Local Data Sources (below).

Example:

The UI asks (via a Service or Application-layer use case):

"Give me Physics exams"

The repository decides:

"Ask the Question Local Data Source for raw rows scoped to Physics, convert them into domain-level `Question` objects."

Access control (is this stream entitled) now lives in the Service Layer, not here — the repository's job is purely "get me the data," not "decide if you're allowed to have it."

---

## Local Data Sources (NEW — Decision 026)

Responsible for:

* Executing Drift queries — this is the **only** layer allowed to do so
* Mapping raw query results into persistence models
* Returning those persistence models to the repository that called it

Rules:

* No business logic.
* No entitlement logic.
* No calculations.
* No Flutter imports.

Persistence models returned here never leave the data layer — the calling repository converts them into domain models before passing anything upward. This keeps Drift-generated types from leaking into `domain/` or `presentation/` code.

---

## Database Layer

SQLite (via Drift) stores — see `docs/database-schema.md` (v2) for the canonical table definitions:

* Grades
* Streams
* Subjects *(stream-owned — Decisions 009/031)*
* Chapters
* Topics
* Questions *(explanation is question-owned — Decision 037; reserving nullable media-reference fields — Decision 027, schema-only)*
* Exams *(a real entity: a previous-year paper identified by subject + EC year, with explicit ordered question membership — Decision 038)*
* Learning Resources (notes, flashcards, mind maps — never explanations)
* Attempts *(append-only — Decision 016; reserving mode/duration/subject/chapter/exam fields — Decisions 028/038)*
* User progress (derived, never stored — recalculated from Attempts, Decision 016)
* Entitlements *(install-owned, revocable — Decisions 012/032/033)*
* Payment Requests *(install-owned; exactly `pending | verified | rejected` — Decisions 032/036)*
* Install identity *(persistent anonymous singleton — Decision 032)*
* Preferred Stream setting (separate from Entitlements; personalization only)

Exam years are Ethiopian Calendar years (Decision 039); all `*_at` timestamps are ordinary ISO8601 system timestamps — the two are never interchangeable.

---

# Content Pack Architecture

Content should be separated from the application. The field-level file format is defined in `docs/content-pack-spec.md`.

Example:

```
Content Pack

├── stream
├── pack_version        (Decision 021)
├── schema_version       (Decision 021)
├── generated_at         (Decision 021)
├── checksum             (Decision 021)
├── minimum_app_version  (Decision 021)
├── chapters (topics → questions + resources; explanations live inside questions — Decision 037)
├── exams (previous-year papers with ordered question membership — Decision 038)
└── metadata
```

The app downloads and imports packs. Each pack declares which stream it belongs to as top-level metadata, not inferred from subject name. Packs are immutable once published (Decision 015, 021) — a content fix ships as a new `pack_version`, never as a silent edit to an already-published pack. The import step should verify `checksum` and refuse packs whose `minimum_app_version` exceeds the installed app version.

Pack identity and version coexistence (Decisions 034/035): a pack's identity is its `pack_key` (stream + subject slug) — version-independent. Import is insert-only; multiple versions of the same `pack_key` coexist on the device, and content queries resolve the newest imported version as the active one. Rows from an older version are removed only when nothing references them (specifically, no Attempt references any of that version's questions), and superseded questions stay fully readable while attempts depend on them.

---

# Core Data Relationships (UPDATED — canonical per Decisions 009/031/038)

```
Grade (9, 10, 11, 12) — enters the model at Chapter level

↓

Subject (per-stream, never shared — Decisions 009/031; `subjects.stream_id` is mandatory)

↓

Chapter   (scoped to a specific Grade + Subject — Decision 010)

↓

Topic

↓

Question  (many-to-many with Topic — a question can tag several topics, Decision 011)
```

Exams are papers, parallel to the chapter tree (Decision 038):

```
Exam (subject + Ethiopian Calendar year)

└── ordered Questions (exam_questions join carrying order_index)
```

Resources connect to topics — explanations are NOT here; they are question-owned fields (Decision 037):

```
Topic

├── Questions   (via many-to-many join)
├── Notes
├── Flashcards
└── Mind Map
```

Subject is owned per-stream directly (`subjects.stream_id` is mandatory); Grade attaches at the Chapter level. There is no Grade↔Stream↔Subject join table — Decision 009 simplified it away and Decision 031 confirms it for Grade 9–10 content as well. See Decision 010 for the historical reasoning behind Grade being a first-class entity.

---

# Database Planning Notes — Pre-Schema (HISTORICAL — superseded by `docs/database-schema.md` v2)

These notes predate the formal schema and are kept for architectural rationale only. The canonical schema is `docs/database-schema.md`; where the notes below disagree with it (they do on the Grade↔Stream↔Subject join, which Decisions 009/031 replaced with per-stream subject ownership), the schema document wins.

Canonical model in effect (Decisions 009/031/032/033/036/037/038/039):

* Subject is stream-owned — `subjects.stream_id` is mandatory; there is no Grade↔Stream↔Subject join table.
* Grade enters the model at Chapter (`chapters.grade_id`); the same subject has different chapters per grade.
* Exam is a first-class content entity (subject + EC year) with explicit, ordered question membership.
* Explanations are question-owned fields, not generic resources.
* Install identity is a persistent anonymous `install_id` (singleton local record).
* Entitlement is a separate, revocable record (`active | revoked`); PaymentRequest persists exactly `pending | verified | rejected`.
* Exam years are Ethiopian Calendar years; system timestamps are ordinary ISO8601 and never double as exam years.

**Required entities (not yet a schema — just the list and their relationships):**

* **Grade** — independent entity. Values: 9, 10, 11, 12.
* **Stream** — independent entity. Values: Natural Science, Social Science. Only meaningfully associated with Grade 11-12 pedagogically (Decision 010), though MVP packages Grade 9-10 content per-stream too (Decision 009/013 tradeoff notes below).
* **Subject** — independent entity, owned per-stream (Decision 009). NOT shared across streams.
* **Chapter** — belongs to a specific (Grade, Subject) pair. The same Subject has different Chapters at each Grade.
* **Topic** — belongs to a Chapter.
* **Question** — connects to Topic via a many-to-many join (see below), not a single foreign key.
* **Resource** (Notes, Flashcards, Mind Maps, Explanations) — belongs to a single Topic (one-to-many, kept simple deliberately — see Decision 011).
* **Entitlement** (Decision 012) — associates an install with a purchased Stream. One-to-many (an install can hold multiple entitlements over time, supporting future second-stream purchase without a schema change). Server-authoritative (Decision 017); cached locally so offline content-access checks still work.
* **PaymentRequest** (NEW — Decision 013, 023) — one per payment submission, with a unique request ID as its canonical identifier (Decision 023). Server-authoritative (Decision 017).
* **Preferred Stream** (Decision 012) — a simple local setting on the install, not a relational entity requiring its own table necessarily (could be a single row/key-value setting). Purely for personalization; carries no access-control weight. **Local-only — never sent to or stored by the backend** (Decision 017).

**Local-only vs. server-authoritative boundary (Decision 017):** Grade, Stream, Subject, Chapter, Topic, Question, Resource, Attempt, and Preferred Stream all live entirely on-device. Only Entitlement, PaymentRequest, and published content packs ever touch the backend. This boundary should be treated as a hard constraint when designing repositories — a repository for Attempt, for example, should never have a network dependency at all.

**Key relationship notes:**

* **Grade is a parent entity, and Stream is conditionally relevant beneath it.** Stream only applies within Grade 11 and 12. Grade 9-10 subjects have no stream. This must be modeled as a join/association (e.g. "this Subject is offered in this Grade, optionally under this Stream") rather than forcing Subject to have a mandatory Stream foreign key.
* **Subject is owned per-stream for Grade 11-12 subjects** (Decision 009, resolved) — Physics belongs to the Natural Science pack as its own record, not shared with Social Science. For **Grade 9-10**, a subject like Physics still spans grades within that one stream-owned record (Grade 9 and Grade 10 Physics chapters both live under the Natural Science pack's Physics subject) — Grade 9-10 content isn't a separate top-level pack, it's the earliest chapters within each stream's own subject.
* **Subject is owned per-stream, not shared** (Decision 009). Natural Science and Social Science each have their own independent set of 6 subjects — even English, Mathematics, and SAT/Aptitude exist as two separate records, one per stream, despite overlapping content. This simplifies Stream↔Subject to a plain one-to-many relationship — no join table needed there. The join concept from Decision 010 is only relevant at the Grade 9-10 boundary, where a subject has no stream at all.
* **Chapter must reference Grade explicitly**, not just Subject — this is required, not optional, because the same subject's chapters are entirely different content at each grade level.
* **Question-to-Topic is many-to-many** (Decision 011). A question can be tagged to topics from different chapters, or even different grades, reflecting how real EUEE papers combine concepts. Weakness analysis must attribute a wrong answer to *every* tagged topic, not just one.
* **Access control runs through Entitlement, not through Preferred Stream** (Decision 012, supersedes the old "active stream is permanent" framing). Preferred Stream can change anytime with zero data consequence — it's read-only personalization. Entitlement changes only through the payment/verification flow (Decision 013) and gates real content access.
* **Out of scope for MVP:** topic-to-topic prerequisite/cross-grade linking (e.g. "this Grade 12 topic builds on that Grade 10 topic"). Noted as a possible v2 feature, not built now — avoids overcomplicating the schema before the MVP even ships.
* **Content tables (Question, Topic, Chapter, Resource) are read-only at the app layer** (Decision 015). No update/delete operations should exist in their repositories — only inserts during content pack import.
* **Attempt is insert-only** (Decision 016). No update or delete operation should exist for Attempt at all — not even soft-delete. Weakness/accuracy calculations always derive from a full or filtered read of Attempt, never from a cached/stored statistic.

---

# Entitlement & Payment Architecture (Decision 012, 013, 032, 033, 036)

```
User submits payment proof (screenshot / transaction ID) — tied to the install's persistent anonymous install_id (Decision 032)
        ↓
Payment Request record created (state: pending)  [requires internet]
        ↓
Admin reviews and verifies manually
        ↓
Entitlement record created for (install, stream) — a separate record, never a payment state
        ↓
App checks entitlement on next sync/launch (manual refresh at MVP)
        ↓
Purchased stream's content becomes accessible
```

Design rules:

* PaymentRequest persists exactly three states: `pending`, `verified`, `rejected` (Decision 036). "Submitted" is the event that creates a pending row; `entitled` is **never** a payment state — entitlement is a separate record (Decision 012). Keeping these structurally separate (never a single "is_paid" flag) ensures a submitted-but-unverified payment can never unlock content.
* Entitlements are revocable and never expire on their own (Decision 033). Revocation is server-side and re-locks the stream's content on the device's next entitlement refresh.
* Content-access checks throughout the app go through the Service Layer's entitlement-check utility (Decision 026), which queries **Entitlement** — never "Preferred Stream" and never "Payment Request status" directly.
* This requires a minimal backend surface (Decision 013) — not a full payment gateway, but somewhere payment requests land and an admin can mark them verified. This is the one piece of "backend in MVP" that's no longer optional, given the manual-verification approach.
* Sync mechanism (how the app learns an entitlement now exists) is intentionally left as an implementation detail — a manual "refresh" button is sufficient at MVP; automatic background sync is a later optimization, not a blocker.

---

# Weakness Analysis Architecture

No AI required. Content and attempts follow strict immutability rules (Decision 015, 016):

* **Content (questions, explanations, notes, flashcards, mind maps) is read-only on-device** — never user-editable, only replaced via new content pack versions (Decision 015, 021).
* **Attempts are append-only** — never overwritten or deleted (Decision 016).
* **Derived statistics (topic accuracy, focus areas) are never stored** — always recalculated from Attempt history on read. Attempt history is the only source of truth; everything else is disposable and regenerable.

The app stores:

```
Attempt

- question_id
- selected_answer
- correct
- timestamp
```

Analysis calculates:

```
Topic accuracy

=

Correct answers / Total attempts
```

Results are generated locally, scoped to the topics reachable from the user's entitled (purchased) stream — not their Preferred Stream, since Preferred Stream carries no access guarantee.

---

# Backend Philosophy

Backend is minimal and local-first (revised — Decision 013, 017).

The backend stores **only**:

* Payment requests
* Entitlements
* Published content packs

The backend never stores learning progress, Attempts, weakness data, or Preferred Stream — all of that stays entirely on-device (Decision 017). This is a hard boundary, not a soft default: a future feature request to "sync progress across devices" is a genuine architecture change requiring a new decision, not an incremental addition.

Normal studying should not depend on servers once content is downloaded and an entitlement is active. The backend's job is narrowly "manage payments, entitlements, and content pack distribution" — nothing else.

Known tradeoff: no progress restore after uninstall (Decision 017). Cloud backup is a plausible v2 feature, not built now.

---

# Design System Architecture (NEW — Decision 018)

A centralized design system module (`core/design/` — the canonical path per the frontend structure above; earlier drafts said `core/theme/`, which is obsolete) defines, once:

* Color tokens
* Typography scale
* Spacing scale
* Border radius values
* Button variants
* Card variants
* Animation/transition presets

Screens reference these tokens; they never define one-off colors, spacing, or component styling inline. `docs/design-system.md` documents these tokens and must exist before UI screens are built (see implementation roadmap) — not written retroactively.

---

# Performance Budget (NEW — Decision 020)

* App startup: under 2 seconds
* Navigation between already-downloaded screens: effectively instant, no perceptible delay
* Core loop (practice, review, resource browsing): fully functional offline
* No UI freezes during normal studying

This budget should actively inform technical choices in Milestone 0 of the implementation roadmap (SQLite package, state management) — a technically elegant choice that's slow on a low-end Android device fails this decision.

---

# AI Development Rules (UPDATED — Decision 019)

AI tools must:

* Follow existing architecture
* Implement one feature or one refactor at a time — never multiple unrelated features in one change
* Produce code that compiles and passes formatting/lint checks
* Keep files under approximately 500 lines unless a larger file is intentionally justified and explained
* Explain decisions
* Avoid unnecessary complexity

AI must not:

* Redesign architecture randomly
* Generate entire application at once
* Add features without approval