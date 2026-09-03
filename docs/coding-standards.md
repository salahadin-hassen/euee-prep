# EUEE Prep — Coding Standards

Status: v2 — updated for the Service Layer / Local Data Source split (Decision 026). Applies to all Dart/Flutter code from Milestone 0 onward. Python (content pipeline) conventions are covered separately, briefly, at the end.

---

## Language & tooling baseline

* Dart with null safety, no exceptions.
* State management: **Riverpod** (Decision 025).
* Local database: **drift** (Decision 024).
* Formatting: `dart format`, enforced via CI-lite lint config (Milestone 0, task 7). No manual style debates — if `dart format` did it, it's correct.
* Linting: `flutter_lints` as a baseline, extended with a small custom rule set (below) rather than a large bespoke config — the point is consistency, not maximalism.

---

## File size ceiling (Decision 019)

* **~500 lines per file, unless justified.** If a file is approaching that, it's usually a sign a class is doing more than one job — split it before it becomes hard to review, not after.
* Justification for exceeding it must be a one-line comment at the top of the file explaining why (e.g. a generated `drift` schema file, which is exempt by nature — generated code doesn't count against this rule).

## Widget size ceiling (NEW)

* Widgets should ideally stay under ~200 lines — tighter than the general file ceiling, because a widget file growing past this is almost always a sign it should be decomposed into smaller, composed widgets rather than one large `build()` method with conditional branches.
* Compose screens from smaller reusable widgets rather than writing one large screen-widget with inline sub-sections.

---

## Folder structure (UPDATED — Decision 026)

Matches `docs/architecture.md`'s feature-based layout exactly. Within each feature module:

```
feature_name/
├── application/              # use cases — one class per use case (e.g. StartExamUseCase); orchestration only
├── data/
│   ├── local_data_sources/   # ONLY place allowed to touch Drift directly
│   └── repositories/         # coordinate one or more local_data_sources; no SQL here
├── domain/                   # entities/models (plain Dart, no Flutter imports)
└── presentation/             # screens, widgets, Riverpod providers for this feature
```

Cross-feature business logic (e.g. weakness analysis, which reads across `exams`, `learning_resources`, and `progress`) lives in a top-level `lib/services/` directory, not inside any single feature — a Service that's genuinely scoped to one feature (e.g. content pack validation, scoped entirely to `content/`) can live in that feature's `domain/` instead. Use judgment; the test is "does more than one feature need this," not a hard rule.

* `domain/` never imports Flutter. If a domain file needs `import 'package:flutter/...'`, that's a layering violation — move the Flutter-specific part to `presentation/`.
* `data/local_data_sources/` never imports Flutter, contains no business logic, no entitlement logic, no calculations — see Local Data Source Rules below.
* `data/` never imports `presentation/`. Dependencies point one direction: presentation → application → services → repositories → local data sources.
* `core/` holds only things genuinely shared across 3+ features (design tokens, generic utilities, the drift database instance itself, logging). If something's used by one or two features, it belongs in those features, not `core/`.

---

## Naming conventions

* Files: `snake_case.dart`.
* Classes: `PascalCase`.
* Riverpod providers: `camelCaseProvider` suffix, e.g. `preferredStreamProvider`, `topicAccuracyProvider`.
* drift tables: plural `snake_case` matching `docs/database-schema.md` exactly (e.g. `attempts`, `question_topics`, `exam_questions`) — the schema doc is the source of truth for names; don't let Dart-side naming drift from it.
* Repository classes: `XyzRepository` (e.g. `AttemptRepository`, `EntitlementRepository`), one per entity from the schema, matching Milestone 1/2's task breakdown.
* Local Data Source classes: `XyzLocalDataSource`, one per repository that needs Drift access.
* Service classes: `XyzService` (e.g. `WeaknessAnalysisService`, `EntitlementService`, `ContentImportService`).
* Application-layer use case classes: `XyzUseCase` (e.g. `StartExamUseCase`, `SubmitPaymentProofUseCase`), one per use case in `features/<feature>/application/`.
* Test files: mirror the file under test, suffixed `_test.dart`, in a parallel `test/` tree matching `lib/`.

---

## Service Layer rules (NEW — Decision 026)

* Services contain business logic — the "what should happen" that isn't pure data access and isn't UI state.
* Services never import Flutter.
* Services communicate only through repositories — never reach into a Local Data Source or Drift directly.
* Services are stateless wherever possible; if a service genuinely needs to hold state across calls, that's worth a second look before accepting it.

---

## Local Data Source rules (NEW — Decision 026)

* Only layer allowed to access Drift.
* Executes SQL (via drift's generated query builders).
* Returns persistence models — never domain models, never widgets, never anything Flutter-aware.
* No business logic. No entitlement logic. No calculations. If a Local Data Source method is doing an `if`-branch based on anything other than "which query to run," that logic belongs one layer up.

---

## Repository rules (Decision 026, enforcing Decision 015/016/017 in code, not just convention)

* Repositories coordinate one or more Local Data Sources; they never execute SQL directly.
* Repositories convert persistence models (from Local Data Sources) into domain models before returning anything to a Service or the Application layer. Persistence models never leave the data layer.
* **Content repositories (`Subject`, `Chapter`, `Topic`, `Question`, `Resource`) expose no `update` or `delete` methods at all.** Not private, not guarded — absent from the interface. If content needs to change, that's a new content pack import (Milestone 3), never a repository call from app code.
* **`AttemptRepository` exposes exactly one write method: `insert`.** No `update`, no `delete`, ever — this is the literal enforcement of Decision 016.
* **`EntitlementRepository` and `PaymentRequestRepository` treat local rows as a cache of server state.** Any method that writes to these tables should be clearly named to reflect "syncing from server" (e.g. `cacheEntitlement`), not implying the app is the source of truth.
* Access control does **not** live in repositories (Decision 026 moved this to the Service Layer's entitlement-check service) — a repository's job is purely "get me the data," never "decide if you're allowed to have it."

---

## Design System rules (Decision 018)

* Never hardcode colors, typography, spacing, border radius, or animation durations in a screen or widget file.
* Always reference the centralized tokens in `core/design/` (`colors.dart`, `typography.dart`, `spacing.dart`, `radius.dart`, `animations.dart`) plus the shared component library (`buttons.dart`, `cards.dart`, `input_fields.dart`).
* If a design need doesn't fit an existing token, add the token to `core/design/` — don't work around it locally in a screen file. This is the concrete mechanism that keeps AI-generated screens from each inventing slightly different styling (Decision 018's stated reason).

---

## Riverpod conventions (UPDATED)

* Prefer `Provider`/`FutureProvider`/`StreamProvider` for read access to repositories/services; `StateNotifierProvider` (or `NotifierProvider`) only where genuine mutable UI state exists (e.g. current practice-session progress).
* **Providers coordinate state — they do not contain business logic.** A provider calls a Service or Repository and exposes the result/state; it should not itself compute a topic-accuracy percentage or decide entitlement. If a provider's body is doing real computation, that computation belongs in a Service.
* Providers should depend on repository/service interfaces, not concrete drift/Local-Data-Source implementations directly — keeps tests able to substitute fakes without touching real SQLite.
* No provider should reach across features directly into another feature's `data/` layer — go through that feature's `domain/` exports, or a shared Service, instead.

---

## Dependency injection (NEW)

* Everything is injected through Riverpod's provider graph.
* Widgets never manually instantiate repositories, services, or Local Data Sources (`MyRepository()` inside a widget's `build()` is always wrong) — they read a provider instead.
* This keeps every layer swappable for tests without touching call sites.

---

## Domain models (NEW)

* Immutable. Use `const` constructors wherever possible.
* No Flutter imports, no Drift-generated types — plain Dart classes/records representing the app's actual concepts (a `Question`, a `Topic`, an `Entitlement`), independent of how they're persisted.

## Persistence models (NEW)

* Persistence models (what a Local Data Source returns, generated by or adjacent to Drift) never leave the data layer.
* Repositories are responsible for converting persistence models into domain models before returning anything upward.

---

## Testing conventions

* Every repository and Local Data Source gets a test using an in-memory drift database (drift supports this natively) — no test should hit a real file-backed SQLite database.
* Every Service-layer calculation (topic accuracy, entitlement checks) gets unit tests with explicit edge cases: zero attempts, a multi-topic question, zero entitlements. These are exactly the places a silent bug would be hardest to notice in manual testing.
* Widget tests are expected for interactive screens (practice session, payment submission) but not required for pure display/read-only screens at MVP — proportionate effort, not blanket coverage for its own sake.

---

## Error handling

* Repository and Service methods return typed results (e.g. a sealed `Result<T>` / `Either`-style type, or nullable + explicit error types — pick one pattern and use it everywhere, don't mix). Avoid throwing for expected failure cases (e.g. "no entitlement" is an expected state, not an exception).
* Reserve actual `throw` for genuinely unexpected states (e.g. a foreign key that should never be null but is) — these indicate a bug, not a normal branch.

---

## Logging (NEW)

* Never use `print()`.
* Use a centralized logging abstraction (`core/logging/`) so log output is consistent, filterable, and easy to strip or redirect in release builds.

---

## Constants (NEW)

* Never use magic numbers or magic strings inline.
* Shared constants live in `core/constants/`. A constant used by only one feature can live in that feature's own files instead — same "does more than one place need this" judgment call as the Services placement rule above.

---

## Comments (NEW)

* Code explains **how**. Comments explain **why**.
* Avoid comments that restate what the code already says. A comment earns its place by explaining a non-obvious reason, a tradeoff, or a link back to a decision in `docs/decisions.md`.

---

## Performance (NEW — Decision 020)

* Prefer `const` widgets wherever the widget tree allows it.
* Avoid unnecessary rebuilds — scope Riverpod `watch` calls as narrowly as possible rather than watching a large provider from a widget that only needs a small piece of it.
* Use `async`/`await` correctly; never block the UI thread with synchronous heavy work (e.g. large content-pack parsing belongs off the main isolate).

---

## Accessibility (NEW)

* Minimum 48dp touch targets on interactive elements.
* Use semantic labels where appropriate (screen-reader support), even though this is a visually-driven exam-prep app — cost is low, and it's the right default.
* Maintain readable contrast per the design system's color tokens; don't override with a lower-contrast one-off for a single screen.

---

## Commit conventions

Prefixes matching the roadmap's task labels: `feat:`, `fix:`, `chore:`, `test:`, `docs:`, `content:`, `refactor:`. One logical change per commit, consistent with Decision 019's "one feature or refactor at a time."

---

## AI Development Rules (UPDATED)

AI must:

* Generate one feature or refactor at a time (Decision 019).
* Preserve existing architecture — never redesign it as a side effect of an unrelated task.
* Never rewrite unrelated files as part of a requested change — if a change appears to require touching an unrelated file, stop and flag it rather than doing it silently.
* Never introduce a new dependency/package without approval.
* Explain major architectural decisions as they're made, not just what was built.
* Follow the naming conventions in this document.
* Prefer composition over inheritance when structuring widgets and domain models.
* Compile, pass formatting, and stay under the file/widget size ceilings above unless justified.

---

## Python (content pipeline) — brief, expand when Milestone 3 starts

* `snake_case` throughout, type hints on all function signatures, `black` for formatting.
* Content validation scripts should fail loudly and specifically (name the exact pack file and field that's invalid) — these scripts are the last line of defense before bad data reaches a student's phone (Decision 021).