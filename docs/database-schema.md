# EUEE Prep — Database Schema

Status: v2 — **canonical.** Implements the entity and relationship rules from `docs/architecture.md` and Decisions 009, 010, 011, 012, 013, 015, 016, 017, 021, 023, plus the canonical clarification Decisions 030–039. This version supersedes the v1 draft; `docs/architecture.md`'s pre-schema notes are historical rationale only.

This is the schema `drift` table definitions should mirror 1:1. SQL types shown are illustrative (SQLite storage classes); actual `drift` table classes will use Dart-typed columns.

Year/time convention (Decision 039): `*_ec` fields are Ethiopian Calendar years identifying exam papers. `*_at` fields are ordinary ISO8601 system timestamps. The two namespaces are never interchangeable.

### Schema migration dependency

The implementation stages this canonical schema in dependency order:

1. Schema v2: `grades`, `streams`, and `subjects`.
2. The next migration: `content_packs` metadata and identity only.
3. The following migration: `chapters` and `topics`.

The `content_packs` table in step 2 is a persistence prerequisite for
immutable content identity. It does not implement pack downloading,
validation, importing, hosting, synchronization, or UI. Those remain later
content-pipeline work. Chapters and topics must retain their required
`source_pack_id` foreign keys and must not be created with invalid or
transitional pack identities.

---

## Local install identity (Decision 032)

```sql
-- Singleton row (enforced by CHECK on id). install_id is generated on-device at
-- first launch, persists for the install's lifetime, and is the only identity the
-- backend ever sees. Deliberately NOT a `settings` key — it is a trust anchor,
-- not a user preference.
CREATE TABLE install_identity (
  id           INTEGER PRIMARY KEY CHECK (id = 1),
  install_id   TEXT NOT NULL UNIQUE,      -- UUID
  created_at   TEXT NOT NULL              -- ISO8601
);
```

## Content tables (read-only at the app layer — Decision 015; insert-only, populated by content pack import, Milestone 3)

Every imported content row records where it came from: `source_pack_id` (which pack version) and `pack_local_id` (the stable, pack-assigned string ID from `docs/content-pack-spec.md`). `UNIQUE(source_pack_id, pack_local_id)` makes imports idempotent and gives Attempts a stable question identity across pack versions (Decisions 034/035).

`grades` and `streams` are fixed reference data seeded by the importer (not pack-owned); `subjects` rows are created on first import of their pack and shared across versions of the same pack identity (find-or-create by `(stream_id, slug)` — pack validation rejects title changes across versions of the same pack).

```sql
-- Grade: 9, 10, 11, 12
CREATE TABLE grades (
  id     INTEGER PRIMARY KEY,
  level  INTEGER NOT NULL UNIQUE          -- 9, 10, 11, 12
);

-- Stream: Natural Science, Social Science
CREATE TABLE streams (
  id    INTEGER PRIMARY KEY,
  slug  TEXT NOT NULL UNIQUE              -- 'natural_science' | 'social_science'
);

-- Subject: owned per-stream, not shared (Decisions 009/031)
CREATE TABLE subjects (
  id         INTEGER PRIMARY KEY,
  stream_id  INTEGER NOT NULL REFERENCES streams(id),
  slug       TEXT NOT NULL,               -- 'physics', 'english', etc.
  title      TEXT NOT NULL,
  UNIQUE(stream_id, slug)                 -- same subject slug can exist once per stream, never shared
);

-- Chapter: belongs to a specific (Grade, Subject) pair (Decision 010)
CREATE TABLE chapters (
  id             INTEGER PRIMARY KEY,
  subject_id     INTEGER NOT NULL REFERENCES subjects(id),
  grade_id       INTEGER NOT NULL REFERENCES grades(id),
  source_pack_id TEXT NOT NULL REFERENCES content_packs(id),
  pack_local_id  TEXT NOT NULL,           -- stable ID from the pack file
  title          TEXT NOT NULL,
  order_index    INTEGER NOT NULL,        -- display order within (subject, grade)
  UNIQUE(source_pack_id, pack_local_id)
);

-- Topic: belongs to a Chapter
CREATE TABLE topics (
  id             INTEGER PRIMARY KEY,
  chapter_id     INTEGER NOT NULL REFERENCES chapters(id),
  source_pack_id TEXT NOT NULL REFERENCES content_packs(id),
  pack_local_id  TEXT NOT NULL,
  title          TEXT NOT NULL,
  order_index    INTEGER NOT NULL,
  UNIQUE(source_pack_id, pack_local_id)
);

-- Question: content is immutable once imported (Decision 015).
-- `explanation` is question-owned (Decision 037) — never a `resources` row.
-- `exam_year_ec` is provenance only (which paper a question was sourced from);
-- actual exam papers are rows in `exams` (Decision 038).
CREATE TABLE questions (
  id                    INTEGER PRIMARY KEY,
  source_pack_id        TEXT NOT NULL REFERENCES content_packs(id),
  pack_local_id         TEXT NOT NULL,
  prompt                TEXT NOT NULL,
  choices_json          TEXT NOT NULL,    -- JSON array of choice strings
  correct_choice_index  INTEGER NOT NULL,
  explanation           TEXT,             -- question-owned (Decision 037)
  textbook_reference    TEXT,             -- nullable; degrades gracefully per PRD acceptance criteria
  exam_year_ec          INTEGER,          -- nullable; Ethiopian Calendar provenance year (Decision 039)
  -- Reserved for future media support (Decision 027) — schema-only, no UI implemented yet:
  image_reference       TEXT,             -- nullable; pack-relative path or URI
  graph_reference       TEXT,             -- nullable
  diagram_reference    TEXT,             -- nullable
  table_reference       TEXT,             -- nullable; structured table data reference
  UNIQUE(source_pack_id, pack_local_id)
);

-- Question <-> Topic: many-to-many (Decision 011 — a question can test multiple concepts)
CREATE TABLE question_topics (
  question_id  INTEGER NOT NULL REFERENCES questions(id),
  topic_id     INTEGER NOT NULL REFERENCES topics(id),
  PRIMARY KEY (question_id, topic_id)
);

-- Resource: Notes, Flashcards, Mind Maps — one-to-many under Topic (Decision 011 scope discipline).
-- Explanations are NOT resources (Decision 037).
CREATE TABLE resources (
  id             INTEGER PRIMARY KEY,
  topic_id       INTEGER NOT NULL REFERENCES topics(id),
  source_pack_id TEXT NOT NULL REFERENCES content_packs(id),
  pack_local_id  TEXT NOT NULL,
  type           TEXT NOT NULL CHECK (type IN ('note', 'flashcard', 'mindmap')),
  title          TEXT,
  content        TEXT NOT NULL,           -- markdown for notes/mindmaps; JSON (front/back) for flashcards
  order_index    INTEGER NOT NULL,
  UNIQUE(source_pack_id, pack_local_id)
);

-- Exam: a specific previous-year EUEE paper (Decision 038) — identified within a
-- pack by (subject, EC exam year). One paper per (subject, year) per pack.
-- `duration_seconds` is the official paper duration used by simulation mode
-- (Decision 030); nullable, with proportional pacing as the presentation-layer fallback.
CREATE TABLE exams (
  id               INTEGER PRIMARY KEY,
  source_pack_id   TEXT NOT NULL REFERENCES content_packs(id),
  pack_local_id    TEXT NOT NULL,
  subject_id       INTEGER NOT NULL REFERENCES subjects(id),
  exam_year_ec     INTEGER NOT NULL,     -- Ethiopian Calendar year (Decision 039)
  title            TEXT,                 -- nullable; optional display title
  duration_seconds INTEGER,              -- nullable; official duration when known
  UNIQUE(source_pack_id, pack_local_id),
  UNIQUE(source_pack_id, subject_id, exam_year_ec)
);

-- Exam <-> Question: ordered membership (Decision 038) — order is stored data, never inferred
CREATE TABLE exam_questions (
  exam_id      INTEGER NOT NULL REFERENCES exams(id),
  question_id  INTEGER NOT NULL REFERENCES questions(id),
  order_index  INTEGER NOT NULL,
  PRIMARY KEY (exam_id, question_id)
);
```

## Content pack metadata (Decision 021 — versioning; Decisions 034/035 — coexistence)

This metadata table is the prerequisite for `chapters` and `topics`.
Their required `source_pack_id` columns reference `content_packs(id)`, and
their `(source_pack_id, pack_local_id)` uniqueness constraints depend on a
real imported-pack identity. Creating this table ahead of the Chapter/Topic
migration does not implement the later content-pack import system.

```sql
-- A row per *imported version*. pack_key is the version-independent identity
-- (stream + subject slug); id is unique per version, so multiple versions of the
-- same pack_key coexist on one device. Import is insert-only; rows are never
-- updated. Content queries resolve the newest imported_at per pack_key as the
-- active version; older versions' rows are removed only when unreferenced.
CREATE TABLE content_packs (
  id                    TEXT PRIMARY KEY,  -- '{pack_key}#{pack_version}' e.g. 'natural_science-physics#1.2.0'
  pack_key              TEXT NOT NULL,     -- '{stream_slug}-{subject_slug}' — version-independent identity
  subject_id            INTEGER NOT NULL REFERENCES subjects(id),
  pack_version          TEXT NOT NULL,
  schema_version        TEXT NOT NULL,
  generated_at          TEXT NOT NULL,    -- ISO8601 (pack metadata; system timestamp, not an EC year)
  checksum              TEXT NOT NULL,
  minimum_app_version   TEXT NOT NULL,
  imported_at           TEXT NOT NULL,    -- ISO8601, set locally on import
  UNIQUE(pack_key, pack_version)
);
```

## User activity (local-only — Decision 017; append-only — Decision 016)

```sql
-- Attempt: insert-only, no update/delete path exists anywhere in the app (Decision 016)
CREATE TABLE attempts (
  id                     INTEGER PRIMARY KEY AUTOINCREMENT,
  question_id            INTEGER NOT NULL REFERENCES questions(id),
  selected_choice_index  INTEGER NOT NULL,
  is_correct             INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
  attempted_at           TEXT NOT NULL,   -- ISO8601 system timestamp (never an EC year — Decision 039)
  -- Reserved/denormalized for future analytics (Decision 028; mode value set resolved by
  -- Decision 030) — populated going forward, not backfilled for historical rows:
  mode                   TEXT,            -- nullable; 'practice' | 'simulation'; further values need a new decision
  duration_seconds       INTEGER,         -- nullable; time spent on this question
  subject_id             INTEGER REFERENCES subjects(id),   -- nullable; denormalized, derivable via question_topics→topics→chapters
  chapter_id             INTEGER REFERENCES chapters(id),  -- nullable; denormalized, same rationale
  exam_id                INTEGER REFERENCES exams(id)      -- nullable; set for simulation attempts (Decisions 028/038)
);
-- Deliberately no updated_at, no is_deleted. If it needs one, something upstream is wrong (Decision 016).
```

## Local settings (local-only — Decision 017; personalization only — Decision 012)

```sql
-- Simple key-value store for local-only, non-relational settings.
-- (Install identity is NOT here — it lives in install_identity, Decision 032.)
CREATE TABLE settings (
  key    TEXT PRIMARY KEY,
  value  TEXT NOT NULL
);
-- Known keys at MVP: 'preferred_stream_id', 'first_launch_completed'
```

## Access control (server-authoritative, cached locally — Decisions 017, 032, 033, 036)

```sql
-- Entitlement: one-to-many install→stream, built for future second-stream
-- purchase (Decision 012); revocable, never expiring (Decision 033).
-- Sync direction is server → device only.
CREATE TABLE entitlements (
  id                        INTEGER PRIMARY KEY,
  install_id                TEXT NOT NULL REFERENCES install_identity(install_id),
  stream_id                 INTEGER NOT NULL REFERENCES streams(id),
  status                    TEXT NOT NULL CHECK (status IN ('active', 'revoked')),
  granted_at                TEXT NOT NULL,  -- ISO8601
  revoked_at                TEXT,           -- ISO8601, set when status flips to 'revoked' (Decision 033)
  source_payment_request_id TEXT REFERENCES payment_requests(request_id)
);

-- PaymentRequest: request_id is the canonical identifier (Decision 023), not the proof itself.
-- Exactly three persisted states (Decision 036): 'pending' | 'verified' | 'rejected'.
-- 'submitted' is the event that creates a pending row; 'entitled' is NEVER a payment
-- state — entitlement is a separate record (above).
CREATE TABLE payment_requests (
  request_id       TEXT PRIMARY KEY,          -- UUID, generated at submission
  install_id       TEXT NOT NULL REFERENCES install_identity(install_id),
  stream_id        INTEGER NOT NULL REFERENCES streams(id),
  proof_type       TEXT NOT NULL CHECK (proof_type IN ('screenshot', 'transaction_id')),
  proof_value      TEXT NOT NULL,             -- file path or typed transaction ID; evidence only
  status           TEXT NOT NULL CHECK (status IN ('pending', 'verified', 'rejected')),
  rejection_reason TEXT,                      -- nullable; admin may not fill one in — UI degrades gracefully
  submitted_at     TEXT NOT NULL,             -- ISO8601
  verified_at      TEXT                       -- ISO8601, nullable until verified
);
```

---

## Indexes (beyond primary/unique keys already implied above)

```sql
CREATE INDEX idx_chapters_subject_grade   ON chapters(subject_id, grade_id);
CREATE INDEX idx_topics_chapter_id        ON topics(chapter_id);
CREATE INDEX idx_question_topics_topic    ON question_topics(topic_id);
CREATE INDEX idx_resources_topic_id       ON resources(topic_id);
CREATE INDEX idx_questions_source_pack    ON questions(source_pack_id);
CREATE INDEX idx_exams_subject_year       ON exams(subject_id, exam_year_ec);
CREATE INDEX idx_exam_questions_question  ON exam_questions(question_id);
CREATE INDEX idx_attempts_question_id    ON attempts(question_id);
CREATE INDEX idx_attempts_attempted_at   ON attempts(attempted_at);
CREATE INDEX idx_attempts_subject_id     ON attempts(subject_id);   -- supports Decision 028's future analytics
CREATE INDEX idx_attempts_chapter_id     ON attempts(chapter_id);   -- supports Decision 028's future analytics
CREATE INDEX idx_attempts_exam_id        ON attempts(exam_id);      -- supports simulation analytics (Decisions 028/038)
CREATE INDEX idx_entitlements_install    ON entitlements(install_id, stream_id);
CREATE INDEX idx_payment_requests_install ON payment_requests(install_id);
```

---

## Design notes / rejected alternatives

* **`choices_json` as a JSON blob, not a separate `choices` table.** Choices are always read and displayed together, never queried independently (e.g. there's no product need for "find all questions with a choice containing X"). A join table here would be relational purity for no real query benefit — rejected in favor of the simpler JSON column, consistent with "don't overcomplicate the MVP."
* **No `updated_at` on `attempts`, `questions`, `topics`, `chapters`, `exams`, or `resources`.** This is deliberate, not an oversight — Decisions 015/016 mean these rows are never updated in place. If a future migration needs an `updated_at` column on any of these, that's a signal the immutability decision is being violated and worth stopping to re-check, not just adding a column.
* **`entitlements` and `payment_requests` live in the same local SQLite database as everything else, despite being server-authoritative (Decision 017).** They're cached locally so the app can check access offline. The repository layer (Milestone 2) treats them as a local cache of server state, not a local source of truth — sync direction is server → device, never the reverse. Entitlement rows carry `install_id` so the cache is self-describing; on a single-install device the value is constant, which is harmless and makes multi-install restore possible later without a schema change.
* **`install_identity` is a singleton table, not a `settings` key.** It is a persistent anonymous trust anchor (Decision 032), not a user preference — it gets first-class storage, explicit first-launch creation semantics, and must never be casually cleared the way a settings row might be.
* **Explanations are question-owned (Decision 037).** `resources.type` deliberately excludes `'explanation'` — an explanation has exactly one owner (its question) and one render context (answer feedback). The question-level `explanation` column is the canonical home.
* **Exams are a real entity with stored ordering (Decision 038).** `exam_questions.order_index` is stored data, never inferred; a question may belong to multiple exams; `questions.exam_year_ec` is provenance only. Exam identity is (subject, EC year) within a pack — the pack-scoped `UNIQUE(subject_id, exam_year_ec)` enforces one paper per subject-year per pack. `duration_seconds` is nullable; when absent, the presentation layer falls back to proportional pacing — that fallback is a UI default, not schema behavior.
* **`questions` reserves nullable media-reference columns (Decision 027) and `attempts` reserves nullable analytics columns (Decision 028, with `mode` values resolved by Decision 030 and `exam_id` added per Decisions 028/038).** All schema-only additions — no importer, UI, or service currently populates or reads them beyond insertion. Don't treat their presence as a signal that related features are in scope now — check the roadmap, not the schema, for what's actually being built.
* **Grade↔Stream is not a table.** Per Decision 009's resolution, Subject is owned per-stream directly (`subjects.stream_id`), and Decision 031 confirms the same per-stream packaging for Grade 9–10 content. `chapters.grade_id` is where Grade actually enters the model. Decision 010's original join concept is historical — see `docs/decisions.md`.
* **Pack version coexistence (Decisions 034/035).** Import is insert-only; multiple versions of the same `pack_key` coexist. The active version is the newest `imported_at` per `pack_key`. An older version's rows may be removed only when nothing references them (specifically: no Attempt references any of that version's questions — enforced by the Attempt→Question foreign key), and superseded questions remain fully readable while any Attempt depends on them.
* **`rejection_reason` on `payment_requests`** is nullable by design: the admin may not fill one in, and the payment-history UI must degrade gracefully with fallback copy — never show a blank reason.

---

## Open item this schema does NOT resolve

`questions.exam_year_ec` and `textbook_reference` are both nullable with no enforced format — content pipeline validation (Milestone 3, task 2) is responsible for data quality here, not the schema. Worth keeping in mind when writing the pack validation script.
