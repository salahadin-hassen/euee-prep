# EUEE Prep — Content Pack Specification (Contract)

Status: v2 — **Contract only.** Defines the field-level shape of a content pack file so Milestone 3 (Content Pipeline) and the app's importer agree on format before either is built. No parser/validator implementation here — that's Milestone 3, tasks 2-3.

This contract implements Decision 003 (downloadable packs), Decision 009/031 (one pack per subject, fully separate, including Grade 9–10 content), Decision 021 (versioning/immutability), Decisions 034/035 (version coexistence on device), Decision 037 (explanations live inside questions), Decision 038 (real Exam objects with ordered membership), and Decision 027 (reserved media-reference fields).

Year convention (Decision 039): `year_ec` / `exam_year_ec` values are Ethiopian Calendar years. All `*_at` metadata (`generated_at`) is an ordinary ISO8601 system timestamp — never an EC year.

---

## Stable pack-local IDs (required)

Every content object carries an `id`: a stable, pack-scoped string (e.g. `"ch-physics-11-02"`, `"q-2015-ec-phys-014"`). Rules:

* IDs must be unique within a pack.
* Reusing the same ID across versions of the same pack asserts logical continuity — "this is the same question/chapter/topic/resource/exam, corrected." A materially changed question must get a **new** ID (content is immutable per Decision 015; a materially changed entity is a new entity).
* IDs are the only cross-reference mechanism inside a pack: `topic_refs` and exam `question_ids` reference these IDs, never titles.
* The importer maps `(source_pack_id, pack_local_id)` to local integer primary keys idempotently — a re-imported version with the same IDs is a no-op, which is what makes Decision 034's insert-only coexistence safe.

---

## Top-level pack structure

```json
{
  "pack_version": "string",
  "schema_version": "string",
  "generated_at": "ISO8601 string",
  "checksum": "string",
  "minimum_app_version": "string",
  "stream": "natural_science | social_science",
  "subject": {
    "slug": "string",
    "title": "string"
  },
  "chapters": [ /* Chapter objects, see below */ ],
  "exams": [ /* Exam objects, see below */ ]
}
```

Pack identity is `(stream, subject.slug)` — the version-independent `pack_key`; `pack_version` distinguishes published versions of that identity.

## Chapter object

```json
{
  "id": "string",
  "grade": 9,
  "title": "string",
  "order_index": 0,
  "topics": [ /* Topic objects, see below */ ]
}
```

`grade` must be one of `9, 10, 11, 12` (matches the `grades` table in `docs/database-schema.md`).

## Topic object

```json
{
  "id": "string",
  "title": "string",
  "order_index": 0,
  "questions": [ /* Question objects, see below */ ],
  "resources": [ /* Resource objects, see below */ ]
}
```

## Question object

```json
{
  "id": "string",
  "prompt": "string",
  "choices": ["string", "string", "string", "string"],
  "correct_choice_index": 0,
  "explanation": "string | null",
  "textbook_reference": "string | null",
  "exam_year_ec": 2015,
  "topic_refs": ["string"],
  "image_reference": "string | null",
  "graph_reference": "string | null",
  "diagram_reference": "string | null",
  "table_reference": "string | null"
}
```

* `explanation` is question-owned content (Decision 037) — it travels inside the question and is never a Resource.
* `exam_year_ec` is **provenance only** (which paper the question was sourced from), an Ethiopian Calendar year. Actual exam papers are explicit `exams` objects; membership in a paper is expressed there, never by this field.
* `topic_refs` is how Decision 011's many-to-many Question↔Topic mapping is expressed at the file level — a question listing more than one topic **ID** here is exactly the multi-concept-question case the schema supports. Titles are never valid references.
* The four `*_reference` fields correspond to Decision 027's reserved schema columns — populating them is optional and not expected at MVP content volume, but the fields exist now so a future pack doesn't need a format change to start using them.

## Resource object

```json
{
  "id": "string",
  "type": "note | flashcard | mindmap",
  "title": "string | null",
  "content": "string",
  "order_index": 0
}
```

`content` is markdown for `note`/`mindmap`; for `flashcard` it's a JSON string of `{"front": "...", "back": "..."}` — this asymmetry is intentional and mirrors the `resources.content` column in `docs/database-schema.md`, which has the same type-dependent shape. `type` never includes `explanation` (Decision 037).

## Exam object (NEW — Decision 038)

```json
{
  "id": "string",
  "year_ec": 2015,
  "title": "string | null",
  "duration_seconds": 12600,
  "question_ids": ["string", "string"]
}
```

* An Exam object is a specific previous-year EUEE paper: `year_ec` is its Ethiopian Calendar year (Decision 039); one paper per (subject, year) per pack.
* `question_ids` lists the member questions **in exam order** — the array order is the stored `order_index` (Decision 038); ordering is never inferred or sorted. Every listed ID must exist in this pack (a question's provenance `exam_year_ec` alone does not make it a member).
* `duration_seconds` is optional — the official paper duration used by simulation mode (Decision 030). When absent, the app falls back to proportional pacing as a presentation-layer default.
* Questions may appear in multiple exams, and questions not in any exam (chapter practice questions) are valid.

---

## Versioning & integrity rules (Decisions 021, 034, 035)

* A published pack is immutable. A content fix ships as a new `pack_version` value, never as an edit to an already-published file.
* `checksum` must be verifiable by the importer before any data is written to the local database.
* `minimum_app_version` — the importer must refuse to import a pack whose value here exceeds the running app's version.
* Import is **insert-only** — the importer never updates or deletes existing rows. Multiple versions of the same `pack_key` coexist on the device; the newest imported version is the active one for content queries. Rows from an older version are removed only when nothing references them (specifically, no Attempt references any of that version's questions), and superseded questions remain fully readable while attempts depend on them.

## Out of scope for this contract

Where pack files are hosted, how they're downloaded, and how the importer parses/validates them are Milestone 3 concerns, not defined here.
