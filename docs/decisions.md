# EUEE Prep — Engineering Decisions

This document records important technical and product decisions.

---

# Decision 001

## Offline-first architecture

Status:

Accepted

Decision:

The application will prioritize local storage and offline functionality.

Reason:

Many Ethiopian students have unreliable internet access.

Benefits:

* Lower costs
* Faster experience
* Better accessibility

Tradeoff:

Content updates and protection become more complex.

---

# Decision 002

## SQLite as primary storage

Status:

Accepted

Decision:

Use SQLite for local application data.

Reason:

* Reliable
* Fast
* Supported by Flutter
* Works offline

---

# Decision 003

## Downloadable content packs

Status:

Accepted

Decision:

Users unlock and download exam content packs.

Example:

* Physics pack
* Mathematics pack

Reason:

Avoid constant server costs.

Tradeoff:

Need content version management.

**Strengthened by Decision 021:** packs are immutable after publication and carry explicit versioning metadata (`pack_version`, `schema_version`, `generated_at`, `checksum`, `minimum_app_version`) — this is the concrete answer to the version-management need flagged here.

---

# Decision 004

## No AI tutor in MVP

Status:

Accepted

Decision:

Do not include an AI chatbot/tutor.

Reason:

* High operating cost
* Possible hallucinations
* Not necessary for core value

The app provides structured learning resources instead.

---

# Decision 005

## Weakness analysis without AI

Status:

Accepted

Decision:

Performance analysis will be calculated locally.

Reason:

The required information already exists:

* Question metadata
* User answers
* Correct answers

No AI is needed.

**Strengthened by Decision 016:** weakness metrics are never stored — every metric is recalculated dynamically from Attempt history, which is the single source of truth.

---

# Decision 006

## Exam engine is the core product

Status:

Accepted

Decision:

The exam experience is the central feature.

Other resources connect to exam performance.

Learning loop:

Exam → Mistake → Explanation → Study → Retry

**Strengthened by Decision 022:** every feature considered for MVP must clearly improve exam performance, concept understanding, or study efficiency — this is the concrete filter that keeps "exam engine as core product" from eroding as new feature ideas come up.

---

# Decision 007

## Avoid unnecessary engagement features

Status:

Accepted

Not including initially:

* Streaks
* Leaderboards
* Social features

Reason:

Focus on learning effectiveness.

---

# Decision 008 (NEW)

## Stream is the top-level academic classification

Status:

**Partially superseded by Decision 012.** The *exclusivity/lock-in* portion of this decision (no in-app change, ever) has been replaced by the Preferred vs. Purchased Stream model. The core idea — stream is the top-level academic classification, selected during onboarding — still stands. Read this decision alongside Decision 012, not in isolation.

Decision:

The content hierarchy is rooted in academic stream, above subject:

```
Stream → Subject → Chapter → Topic → Questions + Resources
```

Two streams at launch: **Natural Science** and **Social Science**.

Reason:

This mirrors the real EUEE structure — a student's stream determines which subjects they are even examined on. Treating stream as a filter bolted onto a flat subject list would misrepresent how students actually think about their own preparation, and would complicate content packaging (a pack needs to declare its stream, not have it inferred).

UX approach (SUPERSEDED — see Decision 012 for the current model):

* ~~Stream is selected once, on first launch, and permanently locked with no in-app change option.~~ This is no longer accurate. Decision 012 splits stream into a freely-changeable **Preferred Stream** (personalization) and a payment-gated **Purchased Stream** (access). The confirmation-dialog / irreversibility reasoning below is kept for historical record only.

Reason for lock-in over switchable (HISTORICAL — no longer the operating model):

* Removes an entire class of edge cases (mixed-stream state, "does old content stay visible," repository queries that need to handle a stream change mid-session).
* Matches how the real exam system works — a student doesn't switch their entrance-exam stream casually either.

This reasoning turned out to be solving the wrong problem: the actual risk wasn't "the user might want different content," it was "the user might want to *pay for* different content later." Decision 012 addresses that directly instead of locking personalization to prevent it.

Tradeoff / open questions (HISTORICAL):

* Subjects that exist in both streams (English, Mathematics) are modeled as **fully separate, independent subject records per stream** — resolved in Decision 009.
* ~~New risk from lock-in: a student who mis-taps during onboarding...~~ No longer a risk — see Decision 012. Preferred stream is freely changeable, so a mis-tap costs nothing.
* ~~Onboarding must not feel like a wall...~~ Still true as general UX advice, but the stakes are much lower now that the choice isn't permanent.
* **Update (see Decision 010):** stream only meaningfully applies to Grade 11-12 content in the *pedagogical* sense. Note Decision 013 additionally packages Grade 9-10 content per-stream for MVP regardless — see Decision 013 for the current subject/grade packaging model.

---

# Decision 010 (NEW)

## Grade is a first-class entity above Subject; Stream applies only to Grade 11-12

Status:

Accepted — **partially superseded by Decisions 009/031 for MVP packaging** (subjects are stream-owned with no Grade↔Stream↔Subject join table; see the product-implication note below). Grade remains a first-class entity, entering the model at Chapter level.

Decision:

The content model adds Grade (9, 10, 11, 12) as an independent entity. Grade, Stream, and Subject relate through a join concept rather than a strict parent chain — because in the real Ethiopian curriculum, streaming does not apply to Grade 9-10 (common curriculum for all students), and only splits into Natural Science / Social Science starting Grade 11.

Corrected relationships:

```
Grade 9   → Subjects (no stream)
Grade 10  → Subjects (no stream)
Grade 11  → Stream → Subjects (stream-specific)
Grade 12  → Stream → Subjects (stream-specific)
```

Reason:

A rigid `Grade → Stream → Subject` hierarchy is factually wrong for two of the four grades the app covers. Forcing Grade 9-10 subjects to nest under a stream they don't have would either duplicate data or misrepresent the curriculum.

Subject is modeled as an independent entity, connected to (Grade, Stream-or-none) through a join, not owned by Stream. This means a subject like Physics is one record, referenced by multiple grade/stream combinations, rather than duplicated per combination.

Product implication:

The first-launch stream selection (Decision 008/012) determines which subjects a student's Preferred Stream shows by default. **Note:** this bullet originally said Grade 9-10 content is "common to everyone regardless of stream" — that was the pedagogically correct framing, but Decision 009/013 later overrode it for MVP: Grade 9-10 content ships bundled per-stream (fully separate, no sharing), not as shared content. Treat Decision 009/013 as the current source of truth for what actually ships; this line is kept for historical context on why Grade is a first-class entity at all.

Chapter is linked to a specific Grade (and Subject) — the same subject has entirely different chapters across grades, so Chapter cannot be scoped to Subject alone.

Tradeoff:

Slightly more relational modeling than a flat tree (a join table instead of direct foreign keys down the chain), but this is necessary correctness, not gold-plating — the alternative actively misrepresents how the curriculum works.

---

# Decision 011 (NEW)

## Question-to-Topic is many-to-many

Status:

Accepted

Decision:

A single EUEE question can test concepts from multiple topics, chapters, or even grades (e.g. a Physics question combining a Grade 11 mechanics concept with a Grade 12 concept). Question and Topic are modeled as a many-to-many relationship, not one question belonging to a single topic.

Reason:

This directly serves weakness analysis, which is a core MVP feature (Decision 005/006). If a multi-concept question is forced under a single topic parent, a wrong answer gets attributed to only one of the tested concepts, silently corrupting the accuracy of "which topics is this student weak in" — the app's central value proposition.

Scope discipline:

This is the one piece of added relational complexity being accepted at MVP. Everything else in the curriculum model stays as simple as the real structure allows:

* Topic-to-topic relationships across grades (e.g. "this builds on that") are explicitly **out of scope for MVP** — noted as a possible v2 feature for smarter recommendations, not built now.
* Resources (notes, flashcards, mind maps) remain one-to-many under Topic. No need for a resource to belong to multiple topics at MVP.

Tradeoff:

Slightly more query complexity when calculating topic-level accuracy (a wrong answer now needs to be counted against every tagged topic, not just one), but this is a small, well-understood pattern (a join table + a join query) — not architecturally risky.

---

# Decision 009 (RESOLVED)

## Cross-stream subject ownership model: fully separate

Status:

Accepted

Decision:

Subjects are **not shared** across streams, even when the subject name and much of the underlying content overlap. Each stream owns its own independent set of Subject records:

```
Natural Science Pack
├── English
├── Mathematics
├── SAT (Aptitude)
├── Physics
├── Chemistry
└── Biology

Social Science Pack
├── English
├── Mathematics
├── SAT (Aptitude)
├── Geography
├── History
└── Economics
```

This resolves the earlier open question (originally posed as a-vs-b: one shared record vs. two independent records). The answer is (b) — two independent records.

This also simplifies Decision 010's Grade↔Stream↔Subject join concept: with subjects owned per-stream rather than shared, the Grade 11-12 relationship becomes a straightforward one-to-many (Stream → Subject) instead of a many-to-many join. The join concept is only still needed at the Grade 9-10 boundary (see tradeoff below).

Reason:

Every content pack (Decision 003) becomes fully self-contained and independently downloadable — no pack ever needs to reach into another pack's data or share a subject record across an install boundary. This is simpler to implement, simpler to version, and simpler to reason about than shared ownership, at MVP stage.

Tradeoff (accepted knowingly):

* **English, Mathematics, and SAT/Aptitude content is duplicated between the two packs.** Grade 9-10 material for these subjects is common curriculum in reality — a student's Grade 9 English content is identical regardless of eventual stream — but under this model it's stored and shipped twice, once per pack. For text-based content (questions, notes, explanations) this is a real but small storage cost, not a correctness problem, since both copies represent the same true content.
* If this duplication becomes a real content-pipeline maintenance burden later (e.g. correcting one English question means editing it in two places), a shared-source-of-truth authoring step in the content pipeline (not the app's runtime database) can deduplicate at content-creation time while still shipping two separate packs. That's a pipeline-tooling decision, not an app architecture one, and is deferred until it's an actual pain point.

* **Real-world flag, not a blocker:** in the actual Ethiopian Grade 9-10 curriculum, Physics/Chemistry/Biology and Geography/History are taught to *all* students regardless of eventual stream — not just the stream they'll later choose. Packaging them exclusively into one stream's pack (per your "everything separate, only these 6" instruction) means a Social Science student's install won't include Grade 9-10 Physics/Chemistry/Biology content, and vice versa for a Natural Science student and Geography/History. If EUEE questions draw on that shared Grade 9-10 material regardless of a student's chosen stream, this is worth a deliberate look later — but I'm implementing it as instructed for now rather than second-guessing the scope call.

MVP subject scope (locked):

**12 subjects total** — the 6 listed per stream above, and no others, for v1.

---

# Decision 012 (NEW)

## Preferred Stream vs. Purchased Stream — decoupled personalization and access

Status:

Accepted — supersedes the lock-in/exclusivity portion of Decision 008.

Decision:

Stream is split into two distinct concepts that must not be conflated in the data model or the UI:

* **Preferred Stream** — a local personalization setting. Chosen at onboarding, freely changeable later in Settings. Controls default browsing experience and which subject list is shown first. Does **not** control what content the user can actually open.
* **Purchased Stream** — an entitlement. Created only through the payment/verification flow (Decision 013). Controls actual content access. A user can hold zero, one, or (in the future) two purchased-stream entitlements.

Reason:

Conflating these (as Decision 008 originally did) created a false choice: "permanent stream lock" was really trying to prevent a *purchasing* problem, not a *personalization* problem. Splitting them removes that tension entirely — personalization can be freely changeable (good UX, no mis-tap risk) while access stays strictly gated by what's actually been paid for (correct business logic).

Architecture implication:

* A new **Entitlement** entity is required: associates an install/user with a purchased stream (and, structurally, could later extend to individual subject-level entitlements if pricing ever changes — not needed at MVP, but the entity shape should not actively prevent it).
* Every content-access check (can this user open this Subject/Chapter/Question) must check **Entitlement**, not Preferred Stream.
* Preferred Stream only affects UI defaults (e.g., "which subject list do I land on"), never gates a repository query.
* This decouples cleanly from Decision 010's Grade↔Stream↔Subject model — Entitlement sits at the Stream level, above Subject, and every Subject under a Stream inherits access from that Stream's entitlement (no per-subject entitlement needed at MVP, given Decision 009's per-stream subject packs).

Future-proofing (explicitly required by this decision, not just a nice-to-have):

* The Entitlement model must support a user later purchasing the second stream without a schema redesign — i.e., Entitlement is a **one-to-many** relationship (install → entitlements), not baked in as a single "which stream do you own" field on the user/install record.

**Updated by Decision 033:** entitlements are revocable (refund, chargeback, fraud). Revocation happens server-side and re-locks the stream's content on the device's next entitlement refresh. No expiration — adding time-based validity would be a new decision.

Tradeoff:

Slightly more schema surface (a real Entitlement table instead of a boolean flag), but this is load-bearing for the business model, not incidental complexity — a boolean "has_purchased" field would need to be redesigned the moment a second-stream purchase is offered.

---

# Decision 013 (NEW)

## Manual payment verification, decoupled from entitlement creation

Status:

Accepted

Decision:

MVP payment flow is manual, not an integrated payment gateway:

```
Payment Request (user submits proof)
  ↓
Verification (admin reviews)
  ↓
Entitlement (created only after verification)
  ↓
Content Access (app checks entitlement)
```

Concretely: user pays through an external channel (e.g. mobile money), submits a screenshot or transaction ID inside the app, an admin manually verifies it, and only then is an Entitlement (Decision 012) created for that stream.

Reason:

Avoids integrating a payment gateway (cost, complexity, and — for a solo developer — real operational overhead) at MVP, while still supporting the one-time-payment-unlock model from the original project brief. This is a deliberate, temporary manual process, not a permanent architectural choice.

Architecture implication:

* **Payment approval must never be directly coupled to content access.** The four stages above are separate states, not one flag — a "payment submitted" state is not the same as "payment verified," which is not the same as "entitlement active." Collapsing these would create a window where unverified payments unlock content.
* This requires *some* backend/server component — even a minimal one — to receive payment submissions and let an admin (you) mark them verified and issue entitlements. This resolves the earlier open PRD question about backend timing: **yes, a lightweight backend is needed at MVP**, but it's an admin-verification surface, not a full payment gateway integration.
* Submitting a payment proof requires internet (consistent with Decision 001's exception list: pack downloads, payment submission, and updates are the only things that require connectivity).
* Once an entitlement is created server-side, the app needs a way to learn about it — likely a manual "check my entitlement" refresh action or a check on next launch with connectivity, rather than real-time push. Exact sync mechanism is an implementation detail for later, not a blocker now.

**See Decision 036 for the normalized state model:** PaymentRequest persists exactly `pending | verified | rejected`. "Submitted" is the event that creates a pending row, and `entitled` is never a payment state — entitlement is a separate record.

Tradeoff:

Manual admin verification doesn't scale past a small number of users without becoming a bottleneck — acceptable, explicit tradeoff for MVP given near-zero operating cost is a stated priority (original project brief), and can be replaced with automated payment gateway integration later without changing the Entitlement model itself (Decision 012 was designed to not require a redesign here).

---

# Decision 014 (NEW)

## Navigation is Subject-first; Grade and Stream are hidden organizational layers, not top-level nav

Status:

Accepted

Decision:

Main app navigation:

```
Home → Subjects → Subject → Grade Sections → Chapter → Study Resources → Practice
```

Stream and Grade are never presented as primary navigation choices during normal use. Stream selection appears only at onboarding and in Settings (as Preferred Stream, per Decision 012). Grade appears only as an organizational layer *inside* a subject (e.g. "Physics" contains Grade 9/10/11/12 sections), not as something a user picks before choosing a subject.

Reason:

Students think "I want to study Physics," not "I want to study Grade 11 content." Exposing the underlying data hierarchy (Grade → Stream → Subject → Chapter, per Decision 010's entity relationships) directly in navigation would put engineering structure in front of the user instead of their actual mental model.

Architecture implication:

* This is a **UI/UX decision, not a data model change.** Decision 010's entity relationships (Grade, Stream, Subject as related entities) remain exactly as documented — this decision only governs how they're surfaced in navigation, not how they're stored or queried.
* The Subject list screen a user lands on is filtered by (a) their Preferred Stream for default ordering, and (b) their Purchased Stream(s) for what's actually openable vs. shown-locked (Decision 012).
* Within a Subject, Grade sections are presented as a simple in-page grouping (e.g. tabs or collapsible sections), not a separate navigational drill-down level.

Tradeoff:

None significant — this aligns the UI with the mental model at no real engineering cost, since the underlying entities already support this query shape (Decision 010's Chapter→Grade+Subject relationship makes "give me all chapters for Physics, grouped by grade" a natural query).

---

# Decision 015

## Content is immutable

Status:

Accepted

Decision:

Questions, explanations, notes, flashcards, and mind maps are read-only once installed. Users never edit educational content. Content changes only through updated content packs.

Reason:

Educational content is curated and versioned. Allowing user edits would complicate synchronization, validation, and future updates.

Tradeoff:

Students cannot annotate or edit built-in content — a plausible future feature, explicitly deferred, not built now.

---

# Decision 016

## Attempts are append-only; derived statistics are never stored

Status:

Accepted

Decision:

Every submitted answer creates a new Attempt record. Attempt history is never overwritten or deleted. Weakness metrics and other performance statistics are never stored — they are recalculated dynamically from Attempt history on every read.

Reason:

Weakness analysis depends on historical performance; deleting or updating attempts would make progress calculations unreliable. Keeping derived statistics disposable (recalculated, not cached) means there's only one source of truth — Attempt history — and no risk of a stored statistic drifting out of sync with the attempts that produced it.

Tradeoff:

Database grows over time (unbounded Attempt table). Storage impact is negligible for text-sized records at this scale — not worth optimizing against at MVP.

---

# Decision 017

## Local-first synchronization — backend never stores learning progress

Status:

Accepted

Decision:

The backend stores only:

* Payment requests
* Entitlements
* Published content packs

Everything else — Attempts, progress, weakness analysis inputs/outputs, Preferred Stream — stays entirely on-device.

Reason:

Keeps infrastructure inexpensive (directly serves the near-zero-operating-cost goal from the original project brief), improves privacy (a Staff-level default worth having even though not explicitly requested), and allows the app to function completely offline for its core loop, consistent with Decision 001.

Tradeoff:

Users cannot restore progress after uninstalling the app — there is no server copy to restore from. This is an accepted MVP limitation. Cloud sync/backup is a plausible future version, not built now.

---

# Decision 018

## Centralized design system

Status:

Accepted

Decision:

Every screen uses a shared, centrally-defined design system: colors, typography, spacing, border radius, buttons, cards, and animations are defined once and referenced everywhere, never redefined per-screen.

Reason:

Maintains UI consistency, makes redesigns significantly easier (change a token once, not every screen), and — specifically relevant given the AI-assisted development workflow — prevents AI-generated screens from each inventing slightly different styling.

Implementation implication:

`docs/design-system.md` must exist and be populated **before** UI screens are built, not written retroactively to document what screens happened to end up looking like. See the implementation roadmap for sequencing.

---

# Decision 019

## AI implementation constraints

Status:

Accepted

Decision:

AI-assisted development (this workflow) generates one feature or one refactor at a time. Large, unrelated features are never generated together in a single change. Every generated code change must:

* Follow existing architecture (no unrequested redesigns — consistent with the original project brief's AI rules)
* Compile
* Pass formatting/lint checks
* Remain under approximately 500 lines per file, unless a larger file is intentionally justified and explained

Reason:

Small, single-purpose changes are easier to review, debug, and maintain — directly serves the "small pull-request sized changes" engineering rule already in effect for this project.

---

# Decision 020

## Performance budget

Status:

Accepted

Decision:

The application targets:

* App startup under 2 seconds
* Instant navigation (no perceptible delay between screens for local, already-downloaded content)
* Full offline operation for the core loop
* No UI freezes during normal studying (practice sessions, review, resource browsing)

Reason:

Most users are on mid-range or low-end Android phones with limited resources (consistent with the original project brief's stated constraints). Performance is treated as a feature, not a later optimization pass.

Implementation implication:

This should inform technical choices made in the implementation roadmap's Milestone 0 (e.g. SQLite package choice, state management choice) — a choice that's elegant but slow on low-end hardware fails this decision, not just a style preference.

---

# Decision 021

## Content pack versioning and immutability

Status:

Accepted

Decision:

Content packs (Decision 003/009) are immutable after publication. Content updates are published as **new pack versions**, never as modifications to an already-published pack. Each content pack includes:

* `pack_version`
* `schema_version`
* `generated_at`
* `checksum`
* `minimum_app_version`

Reason:

Extends Decision 015 (content immutability) to the pack level — a pack that could be silently modified in place would undermine the same guarantees that make on-device content trustworthy and offline-safe. Versioning fields let the app detect stale packs, verify integrity (checksum), and refuse to import a pack the current app version can't safely handle (`minimum_app_version`).

Tradeoff:

Requires actual version-management discipline in the content pipeline (Milestone: Content Pipeline) — can't just overwrite a pack file and re-upload it. This is necessary rigor, not gold-plating, given content is downloaded onto devices that may stay offline for extended periods.

---

# Decision 022

## MVP feature inclusion criterion

Status:

Accepted

Decision:

Every feature considered for MVP must clearly improve at least one of: exam performance, concept understanding, or study efficiency. If a proposed feature doesn't map to one of these, it does not belong in MVP.

Reason:

Gives scope discussions (including future ones, not just this document) a concrete, non-subjective test — directly serves the "keep MVP realistic" instruction from the original project brief, and gives a standing answer to "should we add X" that doesn't require re-litigating the whole roadmap each time.

---

# Decision 023

## Payment request canonical identification

Status:

Accepted

Decision:

Every payment request receives a unique request ID at submission time. The uploaded screenshot or transaction ID text is supporting evidence only — it is never itself the identifier used through the verification workflow. The request ID is canonical for admin verification, entitlement creation, and any user-facing payment-status display.

Reason:

A screenshot can be blurry or a transaction ID mistyped; neither should be load-bearing for tracking a payment through the pipeline. A generated request ID is unambiguous and always present, regardless of evidence quality — extends Decision 013's payment/entitlement pipeline with a concrete identification detail.

---

# Decision 024

## SQLite package: drift

Status:

Accepted

Decision:

Use `drift` (not `sqflite`) as the local database layer.

Reason:

The schema has real relational shape — multiple foreign keys, a many-to-many join table (Question↔Topic, Decision 011), and hard read-only/insert-only constraints (Decision 015/016) that are far easier to enforce at compile time than by convention alone with hand-written SQL strings. `drift` also provides structured migration tooling, which matters given Decision 021's content-pack-versioning approach will likely require schema evolution over time.

Tradeoff:

Slightly more project setup (code generation step in the build) than `sqflite`'s simpler, more direct API. Accepted given the schema's complexity and the performance budget (Decision 020) — `drift` is not meaningfully slower on-device.

---

# Decision 025

## State management: Riverpod

Status:

Accepted

Decision:

Use Riverpod for state management across the Flutter app.

Reason:

Fits cleanly with the repository-pattern architecture already documented (`docs/architecture.md`), has straightforward testability (providers are mockable in isolation), and keeps per-feature ceremony low — relevant given Decision 019's one-feature-at-a-time, reviewable-commit constraint. Bloc is an equally valid alternative but carries more boilerplate per feature than this project's scope justifies.

Tradeoff:

None significant at this project's scale — this is a low-risk, well-precedented choice for a Flutter app of this size.

---

# Decision 026

## Service Layer introduced between Application and Repository

Status:

Accepted

Decision:

The architecture gains an explicit layer split that didn't exist before:

```
Presentation
  ↓
Application
  ↓
Services
  ↓
Repositories
  ↓
Local Data Sources
  ↓
Drift
```

Two new layers, each with a narrow job:

* **Services** hold business logic — weakness analysis, exam scoring, recommendation generation, content import. Stateless where possible, no Flutter imports, communicate only through repositories (never touch a Local Data Source or Drift directly).
* **Local Data Sources** are the *only* layer allowed to execute Drift queries. They map persistence models and return raw database models — no business logic, no entitlement logic, no calculations. Repositories coordinate one or more Local Data Sources; repositories themselves never execute SQL directly anymore.

Reason:

Milestone 1/2 of the implementation roadmap had repositories doing double duty — direct SQL access *and* being the place business logic like entitlement-checking or accuracy calculation would naturally accrete. Splitting this now, before real code exists, avoids repositories slowly turning into god-objects as features are added one at a time (Decision 019) without ever pausing for a layer refactor.

Architecture implication:

* Every repository built in Milestone 1 (Grade, Subject, Chapter, Topic, Question, Resource, Attempt) and Milestone 2 (Entitlement, PaymentRequest) now composes one or more Local Data Sources instead of talking to Drift directly.
* The entitlement-check utility from Milestone 2, task 3 belongs in the **Service** layer, not the repository layer as originally scoped — it's business logic (deciding access), not data retrieval. *(Editorial note: renumbered to Milestone 2, task 4 in the v3 roadmap, after Decision 032 inserted the install-identity task ahead of it.)*
* Weakness/topic-accuracy calculation (Milestone 5, task 7) is a **Service**, not something computed inline in a provider or repository.
* Persistence models (what a Local Data Source returns) never leave the data layer — repositories convert them into domain models before anything above sees them. This keeps Drift-specific types from leaking into `domain/` or `presentation/`.

Tradeoff:

More files and more indirection for what's still a moderately small app — a two-layer split (repository directly on Drift) would have been simpler for MVP. Accepted because the relational complexity already documented (Decision 011's many-to-many, Decision 016's insert-only enforcement, Decision 021's pack-versioning) means business logic was always going to need a home separate from raw data access; better to give it one now than mid-refactor later.

---

# Decision 027

## Question entity reserves fields for future media references

Status:

Accepted — schema-only, no UI implementation

Decision:

The `questions` table gains nullable fields for future media references (image, graph, diagram, table), added now so a future content pack with visual questions doesn't require a schema migration to introduce the concept — only to populate it.

Architecture implication:

No UI work is implied or scheduled by this decision. The roadmap's Milestone 5/6 scope (text-only questions) is unchanged. This is purely "don't paint the schema into a corner" — see `docs/database-schema.md` for the actual column additions.

Reason:

EUEE questions (especially Physics, Chemistry diagrams, and Geography maps) will eventually need visual content. Adding the columns now, unused, is near-zero cost; discovering the need mid-way through a content pipeline build and retrofitting the schema would not be.

---

# Decision 028

## Attempt entity reserves fields for future analytics

Status:

Accepted — schema-only, no analytics feature implementation

Decision:

The `attempts` table gains fields for `mode` (practice vs. simulation, anticipating the still-open simulation-mode PRD question), `duration`, `subject`, and `chapter` — denormalized convenience fields for future analytics queries, populated going forward but not backfilled or required by any MVP feature yet.

Reason:

Decision 016 makes Attempt the permanent, append-only source of truth for everything downstream. Future analytics (time-per-question trends, practice-vs-simulation performance comparison) will want to query Attempt directly without joining back through Question→Topic→Chapter→Subject every time. Reserving the fields now costs nothing at insert time; not reserving them means a future migration has to backfill historical attempts that may have incomplete derivable data.

**Updated by Decision 030:** the simulation-mode question this decision anticipated is resolved — full timed, single-sitting exam simulation is v1 scope. `mode` uses `'practice' | 'simulation'`; adding further values (e.g. a distinct untimed learn-mode value) is a new decision, not a silent enum extension.

Tradeoff:

Minor denormalization (subject/chapter are technically derivable via Question→Topic→Chapter) accepted deliberately for future query convenience — consistent with Decision 016's framing that Attempt storage growth is an acceptable cost.

---

# Decision 029

## Subject list shows only the user's Preferred Stream — the other stream is never shown

Status:

Accepted — closes the open item first raised after Decision 012.

Decision:

The Subject list screen shows **only** the 6 subjects belonging to the user's current Preferred Stream. The other stream's subjects are not shown at all — not locked, not as an upsell preview, not reachable through normal browsing.

Within the shown stream, subjects render in a **locked/preview state** if the user hasn't purchased that stream's entitlement yet (Decision 012) — that's a separate concern from cross-stream visibility, and still applies exactly as before. Entitlement unlocks all 6 subjects in a stream together, since purchasing is per-stream, not per-subject (Decision 003/009).

Reason:

Simpler, more focused UI — a Natural Science-track student never has a reason to browse Social Science subjects day-to-day, and showing them as a permanent upsell banner would clutter the primary "study my subjects" experience for no real benefit, given Decision 014's subject-first navigation is meant to feel purpose-built for the student's track.

Architecture implication:

* Second-stream purchase (anticipated by Decision 012's one-to-many Entitlement design) needs its own entry point — **Settings**, not the main Subject list — since the other stream is never visible there. This is a small addition to the Settings screen scope, not a new architectural concept.
* The Subject-list repository query filters by Preferred Stream only; it does not need to know about or query the other stream's subjects at all for this screen.

---

# Decision 030 (NEW)

## Full timed, single-sitting previous-year exam simulation is v1 scope

Status: Accepted — resolves the last open PRD scope question (exam simulation mode).

Decision:

v1 includes full exam simulation: a previous-year EUEE paper taken as a real exam — timed on the official paper duration, single-sitting, free navigation between questions, no per-question feedback, with answers and explanations revealed only after the whole exam is submitted.

Reason:

The exam experience is the core product (Decision 006). Shipping v1 as practice-only would reduce the primary paid value proposition — previous EUEE examinations practiced under real conditions — to a generic quiz experience.

Architecture implication:

* A real Exam entity with explicit exam→question membership and ordering is required (Decision 038).
* `attempts.mode` records `simulation` for exam-session answers — Decision 028's reserved field now has a resolved value set.
* The PRD's open item on simulation mode is closed; the roadmap's Milestone 6 blocker is lifted.

---

# Decision 031 (NEW)

## Grade 9–10 content is packaged per stream; runtime Subject records remain stream-owned

Status: Accepted — confirms Decisions 009/013 for MVP and closes the real-world flag raised in Decision 009's tradeoff notes.

Decision:

For MVP, Grade 9–10 chapters ship inside each stream's subject packs. Runtime Subject records carry a mandatory `stream_id`; there is no Grade↔Stream↔Subject join table and no cross-stream subject sharing. The pedagogical commonality of Grade 9–10 content is a content-pipeline concern (deduplication at authoring time, if ever), never a runtime data-model concern.

Reason:

Pack self-containment (Decision 009) and simpler queries outweigh modeling the real-world common curriculum. A Social Science student's install deliberately does not include Grade 9–10 Physics/Chemistry/Biology content at MVP, and vice versa — consciously accepted as a product scope call, not an oversight.

Tradeoff:

If EUEE papers later prove to draw heavily on the other stream's Grade 9–10 material, expanding pack contents is a content-pipeline change, not a schema change — `subjects.stream_id` and per-stream packs remain valid either way.

---

# Decision 032 (NEW)

## Persistent anonymous install identity

Status: Accepted

Decision:

Each install holds a persistent, anonymous `install_id` — a UUID generated on-device at first launch, stored locally, never reset except by reinstall. It is the sole identity/trust anchor for backend calls at MVP: payment submission and entitlement sync. No user accounts, no login, no profile — nothing beyond what backend trust requires.

Reason:

Manual payment verification (Decision 013) needs a stable way to associate a payment request and its resulting entitlement with the install that submitted it, without inventing account behavior the product does not need.

Tradeoff:

`install_id` is bearer-only — possession is proof, so a copied install_id could impersonate an install. Accepted at MVP's manual-verification scale; any stronger scheme is a new decision, not an extension of this one.

---

# Decision 033 (NEW)

## Entitlements are revocable; no expiration

Status: Accepted

Decision:

An Entitlement record carries a status: `active` or `revoked`. Revocation is server-side (refund, chargeback, fraud) and reaches the device on the next entitlement refresh, at which point that stream's content re-locks. Entitlements never expire on their own — no time-based validity is modeled, and adding one later is a new decision.

Reason:

Refunds and disputed payments are real for a manual-verification flow; without revocation the local cache can drift from server truth permanently. Expiration is deliberately absent because a one-time-payment unlock has no natural expiry semantics.

---

# Decision 034 (NEW)

## Old content-pack versions remain while referenced; removal only when safe

Status: Accepted

Decision:

Importing a new pack version is insert-only — existing rows are never updated or deleted. Multiple versions of the same pack identity (stream + subject) coexist on the device; content queries resolve the newest imported version as the active one. An older version's rows may be removed only when nothing references them — specifically, when no Attempt references any of that version's questions.

Reason:

Extends Decision 015/021 to the device itself: silently deleting content that an append-only history depends on would corrupt the only source of truth for progress (Decision 016).

---

# Decision 035 (NEW)

## Old questions remain referenceable while attempts depend on them

Status: Accepted

Decision:

Attempt rows reference questions by stable identity. A question from an older pack version stays fully readable — prompt, choices, correct answer, explanation — as long as any Attempt references it, even when a newer pack version has superseded it for new sessions.

Reason:

Attempt history is the source of truth (Decision 016). A stored attempt whose question can no longer be rendered or scored makes historical accuracy calculations silently wrong.

---

# Decision 036 (NEW)

## PaymentRequest lifecycle is separate from Entitlement; `entitled` is not a payment state

Status: Accepted — normalizes the payment state model across PRD, architecture, and UI.

Decision:

PaymentRequest persists exactly three states: `pending`, `verified`, `rejected`. "Submitted" is the submission event that creates a `pending` row — not a fourth state. `entitled` is never a PaymentRequest status; entitlement is a separate record (Decision 012) created after verification. Access checks read Entitlement only — never Preferred Stream, never PaymentRequest status.

Reason:

The four-stage pipeline (Decision 013) spans two different records. Collapsing entitlement into payment status recreates the exact coupling Decision 013 forbids: a verified-but-not-yet-entitled request must never unlock content, and a display state named "entitled" on a payment row would imply it does.

---

# Decision 037 (NEW)

## Explanations are question-owned content

Status: Accepted

Decision:

An explanation is a field of the Question it explains. It is not a generic learning Resource — `resources.type` remains exactly `note`, `flashcard`, `mindmap`. Explanations render with the question's answer feedback and are never browsed standalone.

Reason:

An explanation has exactly one meaningful owner (its question) and one render context (answer feedback). Modeling it as a Topic-attached resource (one-to-many under Topic, per Decision 011's scope discipline) would break that 1:1 ownership and complicate the review screen for no product gain.

---

# Decision 038 (NEW)

## Real Exam entity with explicit membership and ordering

Status: Accepted

Decision:

An Exam is a first-class content entity: a specific previous-year EUEE paper — identified within a pack by (subject, EC exam year) — with explicit, ordered membership of questions (a join table carrying `order_index`). Question order within an exam is stored data, never inferred. A question may belong to multiple exams; a question's `exam_year_ec` field is provenance only, not membership.

Reason:

The primary paid product is previous-year exams organized by year. A nullable year integer on Question cannot represent a paper — identity, subject membership, duration, question ordering. Without a real Exam entity, the exam experience would be reconstructed by convention, which is exactly the implicit structure this project's schema discipline exists to avoid.

---

# Decision 039 (NEW)

## Exam year is Ethiopian Calendar; system timestamps are separate

Status: Accepted

Decision:

Previous-year exam years are represented as Ethiopian Calendar (EC) years everywhere they surface — schema, content packs, API, UI (e.g. `exam_year_ec: 2015`). System timestamps (`generated_at`, `submitted_at`, `granted_at`, `attempted_at`, `imported_at`) remain ordinary ISO8601 timestamps and are never displayed as, converted into, or compared against exam years. EC↔Gregorian conversion, if ever needed, happens at the content-pipeline or presentation edge only — never by mixing the two in one field.

Reason:

Students identify EUEE papers by EC year. Storing Gregorian years and converting ad hoc invites off-by-seven/eight-year errors and label drift across schema, packs, API, and UI. Keeping event timestamps in a separate, clearly-named namespace prevents the two concepts from being conflated (e.g. "attempted_at's year == exam year").