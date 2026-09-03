# EUEE Prep — Product Requirements Document

Status: **Locked.** Stream/access model, subject scope, backend requirement, curriculum structure, and exam simulation scope (v1 — Decision 030) are all resolved. No open scope questions remain.

---

# Requirement: Preferred Stream vs. Purchased Stream (UPDATED — Decision 012)

* On first launch, before any content is shown, the user selects a **Preferred Stream**: Natural Science or Social Science. This is personalization only — freely changeable later in Settings, no confirmation step needed.
* Content access is controlled separately by **Purchased Stream** (an entitlement), created only through the payment/verification flow. A user can hold zero, one, or eventually two stream entitlements.
* The Subject list shows **only** the 6 subjects belonging to the user's Preferred Stream — the other stream is never shown, not even as a locked upsell (Decision 029). Purchasing a second stream is a Settings-initiated action, not something discoverable from the main Subject list.
* Within the shown stream, subjects render **locked/preview** if that stream hasn't been purchased yet — this is a separate concern from cross-stream visibility above.

Acceptance criteria:

* A new install can browse its Preferred Stream's subject list (locked previews) without completing any payment step.
* The Subject list never renders the non-Preferred stream's subjects, in any state.
* Changing Preferred Stream in Settings updates which 6 subjects are shown — it never grants or revokes access to content.
* Opening a subject the user is not entitled to routes to the payment flow instead of showing full content.
* Free-sample content (per the original "free sample experience" principle) remains reachable regardless of entitlement state.

---

# Requirement: Payment & Entitlement Flow (NEW — Decision 013)

* Payment is manual for MVP: user pays externally, submits proof (screenshot or transaction ID) in-app, admin verifies, entitlement is created.
* Payment submission, verification, and entitlement creation are tracked as distinct states — never collapsed into a single flag.
* Requires a minimal backend surface to receive payment submissions and let an admin mark them verified. This is now a confirmed MVP requirement, not optional (resolves the earlier open "backend timing" question).

Acceptance criteria:

* A submitted payment request is visible to the admin in a pending state before any entitlement exists.
* Content unlock only occurs after an entitlement record is created — never directly from a "payment submitted" state.
* The app can detect a newly created entitlement via a manual refresh action (real-time sync explicitly out of scope for MVP).
* Payment requests carry exactly three states — pending, verified, rejected (Decision 036). "Entitled" is never a payment state; entitlement is a separate record created only after verification.
* A revoked entitlement re-locks that stream's content on the next refresh (Decision 033 — refund, chargeback, fraud). Entitlements never expire on their own.

---

# Requirement: Grade-Aware Learning Resources (UPDATED — EUEE-scoped, not general curriculum)

* **This is not a general Grade 9–12 school curriculum app.** It is an EUEE preparation app. The app never includes a Grade 9 or 10 school subject just because it exists in the Ethiopian curriculum — only subjects actually tested on the EUEE are included, and each of those subjects carries **Grade 9–10 curriculum content relevant to EUEE subjects**, not a general Grade 9-10 syllabus.
* The app organizes learning by **EUEE subject** (Physics, Mathematics, English, etc. — the 12 subjects locked in Decision 009), and each subject internally contains the Grade 9–12 chapters and topics required for entrance exam preparation. Grade is a structural detail inside a subject, not a separate content domain.
* Content spans Grade 9 through Grade 12 *within each EUEE subject*, matching real EUEE exam coverage — not a claim that the app teaches every Grade 9/10 school subject.
* Grade is a distinct browsing/organizing dimension, not just a tag — a subject like Physics has a different chapter set at each grade level, and the app must present them as such rather than merging them into one flat chapter list.
* A student is not asked to declare their current grade at onboarding. EUEE prep is cumulative across all four grades, so all grade levels within a purchased subject are available from the start. Grade functions as a navigation/filter axis within a subject, not a gate.
* Navigation does not expose Grade as a top-level choice — it's a grouping inside each Subject screen (Decision 014).

Acceptance criteria:

* The app never surfaces a subject that isn't one of the 12 locked EUEE subjects (Decision 009) — no Civics, ICT, PE, or other non-tested school subjects, even though they exist in the real Grade 9-10 curriculum.
* Within a subject, a user can see which grade level each chapter belongs to.
* Grade 9-12 content for a subject is fully bundled within that subject's stream pack (Decision 009/013) — e.g. Grade 9 Physics ships as part of the Natural Science pack, not as separate shared content.
* A Subject screen groups chapters by grade without requiring a separate "pick a grade" navigation step.

---

# Requirement: Textbook-Based References (NEW)

* Questions and explanations should reference the specific textbook and page/section where the underlying concept is taught, where that data is available in the content pipeline.
* This is a content/data requirement more than a UI requirement at MVP — the schema and content pack format need a field for it, but a rich in-app textbook viewer is explicitly out of scope for v1 (would pull in licensing, file size, and rendering complexity disproportionate to the value at this stage).

Acceptance criteria:

* Question explanation screens display a textbook reference (grade, subject, chapter, page range) when the content pack provides one.
* Missing references degrade gracefully — the explanation still displays without a reference, no broken UI state.

---

# Requirement: Multi-Concept Question Mapping (NEW)

* A single EUEE question may test more than one topic, chapter, or grade-level concept (Decision 011).
* The content pipeline and app must support tagging one question to multiple topics.
* Weakness analysis must count a wrong answer against every topic a question is tagged to, not just one.

Acceptance criteria:

* The content import pipeline accepts a list of topic tags per question, not a single tag.
* Topic-accuracy calculations correctly reflect multi-tagged questions (verified by at least one test case with a question tagged to topics from two different chapters).

---

# MVP Content Scope (LOCKED)

12 subjects total, fully separate per stream (Decision 009):

```
Natural Science Pack: English, Mathematics, SAT (Aptitude), Physics, Chemistry, Biology
Social Science Pack: English, Mathematics, SAT (Aptitude), Geography, History, Economics
```

No subject is shared between packs, even where content overlaps (e.g. English). Each pack is fully self-contained and independently downloadable.

Note: "SAT" refers to an aptitude/reasoning component, confirmed as "SAT (Aptitude)" — not the US SAT.

---

# Requirement: Subject-First Navigation (Decision 014)

* Main navigation: Home → Subjects → Subject → either Grade Sections → Chapter → Study Resources → Practice, or Previous-Year Exams (grouped by EC year) → Exam Simulation.
* Stream and Grade are never presented as top-level navigation choices during normal browsing.
* Stream only appears at onboarding and in Settings (as Preferred Stream).

Acceptance criteria:

* A user can reach any chapter within 3 taps from the subject list, without ever explicitly selecting a "stream" or "grade" screen.
* A user can start a previous-year exam simulation within 3 taps from the subject list (Subject → Exams → year).
* The subject list is the first screen after onboarding, not a stream or grade picker.

---

# Requirement: Previous-Year Exam Simulation (Decision 030, 038, 039)

* Previous EUEE exam papers are a first-class product surface: within a subject, students browse available exam papers by Ethiopian Calendar year (initial planned content range: 2013–2018 EC) and take any of them as a full simulation.
* v1 includes full timed, single-sitting exam simulation: the countdown uses the official paper duration, the student can navigate freely between questions, there is no per-question feedback, and answers/explanations are revealed only after the whole exam is submitted.
* Question order within an exam is stored exam data (Decision 038), never inferred or shuffled — shuffling/retry is a practice-session concern, never a simulation concern.
* Exam attempts feed the same append-only Attempt history as practice (Decisions 016/028), recorded with mode `simulation` and a reference to the exam paper.

Acceptance criteria:

* A subject's exam list shows each available paper's EC year clearly, with year context visible throughout the session.
* A simulation session enforces a single-sitting timed flow: the timer runs on the official duration, submitting (or time running out) finalizes the exam, and no per-question feedback appears before then.
* After submission, the student can review every question with their answer, the correct answer, and the explanation.
* Every answered question in a simulation produces an append-only Attempt record (mode `simulation`, exam reference set).

---

# Requirement: Payment Request Identification (NEW — Decision 023)

* Every payment request receives a unique request ID at submission time.
* The uploaded screenshot/transaction ID is supporting evidence only — it is not itself the identifier used through the verification workflow.
* The request ID is the canonical reference for admin verification, entitlement creation, and any user-facing "status of my payment" display.

Acceptance criteria:

* A submitted payment request always has a request ID visible to the user (e.g. in a "my payment status" screen), independent of whether the screenshot is legible or the transaction ID was typed correctly.
* Admin verification and entitlement creation reference the request ID, not the screenshot file itself.

---

# MVP Feature Inclusion Criterion (NEW)

Every feature considered for MVP must clearly improve at least one of:

* Exam performance
* Concept understanding
* Study efficiency

If a proposed feature doesn't map to one of these, it does not belong in MVP — this is a standing filter for scope discussions going forward, not a one-time check.

---

# Open Items

None — all previously open items are resolved:

1. ~~Exam simulation mode~~ — **Resolved (Decision 030): full timed, single-sitting previous-year exam simulation is v1 scope.**

Resolved, no longer flagged:

2. ~~Grade 9-10 cross-stream overlap~~ — **Resolved by explicit product scoping.** The app was never meant to mirror the general Grade 9-10 school curriculum; it organizes content by EUEE subject, and each EUEE subject (Physics, Geography, etc.) owns its own Grade 9-12 curriculum slice within its stream pack. Physics existing only in the Natural Science pack is intentional, not an oversight — a Social Science student isn't tested on Physics, so the app correctly has no reason to include it for them, real-world classroom overlap notwithstanding.