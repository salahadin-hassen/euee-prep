# EUEE Prep — User Flows

## Main Journey (UPDATED)

Old flow:

```
Open App
  ↓
Choose Subject
  ↓
Choose Exam
```

Current flow:

```
Open App
  ↓
Select Preferred Stream   (first launch; freely changeable later in Settings)
  ↓
Select Subject            (default-sorted by Preferred Stream; open subjects gated by Purchased/entitled stream)
  ↓
Either path within the subject:
  · Chapter → Study Resources → Practice (untimed / optional timer)
  · Previous-Year Exams → Select EC year → Full timed exam simulation (Decision 030)
  ↓
Review
  ↓
Analyze Weak Areas
  ↓
Study Related Resources
```

Note the navigation itself is Subject-first (Decision 014) — the diagram above shows logical steps, not literal screen order. In the actual UI, a student taps "Physics" and sees Grade sections inside it; they never pick "Grade 11" as a standalone step.

---

## First Launch Flow (UPDATED — Preferred Stream, not a permanent lock)

```
App opens for the first time
  ↓
Preferred Stream selection screen shown
  (Natural Science / Social Science)
  ↓
User taps a stream
  ↓
Selection saved locally as a personalization setting
  ↓
User lands on subject list, default-sorted by chosen stream
  ↓
Subjects display as locked/preview until an entitlement exists (see Payment Flow; free-sample content stays reachable regardless of entitlement state)
```

Notes:

* This screen only appears on first launch. Returning users skip straight to their subject list.
* No account/login is required to make this selection — it's a local preference, consistent with the offline-first principle.
* **This choice is not permanent and needs no confirmation step** (revised — see Decision 012). It only affects which subject list the user sees by default; it has no bearing on what content they can actually open.
* A "not sure yet" path is low-priority now — since the choice is freely changeable in Settings, the cost of an uncertain first pick is close to zero.

---

## Changing Preferred Stream (UPDATED — now supported)

```
User opens Settings
  ↓
Taps "Preferred Stream"
  ↓
Selects a different stream
  ↓
Subject list default view updates immediately
```

Notes:

* This is purely cosmetic/personalization — no confirmation needed, no data implications.
* It does **not** grant access to the other stream's content. A user can set their Preferred Stream to Social Science while only holding a Natural Science entitlement; in that case Social Science subjects still show locked/preview state.

---

## Payment & Entitlement Flow (NEW — Decision 013)

```
User taps a locked subject/stream
  ↓
Payment instructions shown (external payment channel)
  ↓
User pays externally (e.g. mobile money)
  ↓
User submits proof in-app (screenshot or transaction ID)
  ↓
Payment Request created (state: pending)
  ↓
   [admin reviews outside the app]
  ↓
Admin marks payment verified
  ↓
Entitlement created for (install, stream)
  ↓
User returns to app and refreshes / re-launches
  ↓
App detects new entitlement
  ↓
That stream's 6 subjects unlock fully
```

Notes:

* Submitting payment proof requires internet; everything before and after that step can happen offline.
* There is no real-time push notification of verification at MVP — the user needs to manually refresh or relaunch to see the unlock. This is an accepted MVP limitation (Decision 013), not an oversight.
* This flow is designed to repeat for a second stream purchase later without any structural change (Decision 012's entitlement model is one-to-many by design).
* Payment requests carry exactly three states: pending, verified, rejected (Decision 036). "Entitled" is never a payment state — the entitlement is a separate record created only after verification.
* Entitlements can be revoked (Decision 033 — refund, chargeback, fraud). A refresh after revocation re-locks that stream's content; entitlements never expire on their own.

---

## Exam Simulation Flow (NEW — Decisions 030, 038, 039)

```
Within an entitled subject, student opens Previous-Year Exams
  ↓
List of available exam papers, grouped by Ethiopian Calendar year (planned range 2013–2018 EC)
  ↓
Student starts a paper
  ↓
Full timed, single-sitting simulation:
  official-duration countdown, free navigation between questions,
  question order as stored exam data, no per-question feedback
  ↓
Submit (or time expires)
  ↓
Review every question: own answer, correct answer, explanation
  ↓
Attempts recorded (mode 'simulation', exam reference set) —
feeding the same append-only Attempt history and weakness analysis as practice
```

Notes:

* The simulation is deliberately single-sitting: there is no resume-later mid-exam at MVP. Leaving finalizes or discards per the exam-session UX; the timed flow itself never continues across app restarts.
* Shuffling/retry is a practice-session behavior only — exam order is fixed stored data (Decision 038).

---

## Practice → Review → Analyze Loop (existing, unchanged in structure)

```
Select Chapter (practice) or Previous-Year Exam (simulation)
  ↓
Practice session (untimed or optional timer) — or full Exam Simulation
(timed on the official paper duration, single-sitting — Decision 030)
  ↓
Submit (or, in simulation, time expires)
  ↓
Review Answers (in simulation: answers + explanations revealed only after submit)
  ↓
Weakness Analysis (per topic, within entitled/purchased stream)
  ↓
Jump to related Notes / Flashcards / Mind Map for weak topics
  ↓
Retry
```

This loop is unaffected by the stream model change at the mechanical level — it now simply operates within whatever subject/topic set the user's **entitled** stream exposes, not their Preferred Stream.