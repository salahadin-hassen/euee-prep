# EUEE Prep — Project Context

## Project Name

EUEE Prep (working name)

---

# Project Summary

EUEE Prep is an offline-first mobile application designed to help Ethiopian Grade 12 students prepare for the Ethiopian University Entrance Examination.

The application organizes previous exam questions, study materials, and learning resources into a structured system that helps students practice, understand mistakes, and improve.

The goal is to replace scattered PDFs, Telegram files, and unorganized studying with one reliable preparation platform.

---

# Vision

Build the most useful and accessible EUEE preparation platform for Ethiopian students.

The app should be:

* Fast
* Offline-first
* Affordable
* Simple to use
* Educationally effective
* Reliable

---

# Target Users

Primary users:

* Grade 12 Ethiopian students preparing for EUEE
* Students retaking the entrance exam

User environment:

* Mostly Android devices
* Limited internet connectivity
* Limited device storage
* Need efficient study methods

**Update:** Students self-identify into one of two academic streams before the exam — **Natural Science** or **Social Science**. This is a Ministry of Education-defined split that determines which subjects a student is even tested on. It is not optional context — it is the first fact the app needs about a user.

---

# Core Product Principles

## 1. Curriculum Coverage: Grade 9-12, Scoped to EUEE Subjects Only (UPDATED)

**This is not a general Grade 9–12 school learning app. It is an EUEE preparation app.** That distinction governs what content ever gets built: the app never includes a Grade 9 or 10 school subject just because it exists in the Ethiopian curriculum — only the subjects actually tested on the EUEE are included (the 12 subjects locked in Decision 009).

Each EUEE subject internally carries the Grade 9–12 curriculum content relevant to that subject, not a general syllabus:

* **Grade 9-10** — the app includes Grade 9-10 chapters/topics only for subjects that are tested on the EUEE (e.g. Physics, Mathematics), not every Grade 9-10 school subject (e.g. no Civics, ICT, PE).
* **Grade 11-12** — streamed curriculum. Subjects and depth differ between Natural Science and Social Science.

This means **Grade is a first-class organizing concept *inside* a Subject**, not a separate content domain — see Decision 010. A single EUEE subject (e.g. Physics) spans all four grades with different chapters at each level; the app needs to represent that correctly rather than flattening it, but it never expands into subjects the EUEE doesn't test.

## 2. Stream-Based Content Organization

The Ethiopian university entrance system separates students into two streams, and each stream has a distinct subject list. The app's entire content hierarchy is rooted in this split:

```
Stream
  ↓
Subject
  ↓
Chapter
  ↓
Topic
  ↓
Questions + Learning Resources
```

A student in the Natural Science stream should never be shown Social Science subjects (or vice versa) as part of their normal browsing — the app should feel like it was built for their track specifically, not like a generic app with a filter switch.

**Why this matters enough to be a core principle (not just a data field):** stream is not a preference like dark mode — it changes *which subjects exist at all* for that user. Every downstream feature (content packs, exam simulation, weakness analysis) is scoped by stream. Getting this right at the foundation avoids a painful retrofit later.

---

## 3. Offline First

The main learning experience should work without internet.

Users should be able to:

* Take exams
* Review answers
* Study notes
* Use flashcards
* View mind maps
* Analyze performance

offline.

---

## 4. Low Operating Cost

The product should avoid expensive recurring infrastructure.

Prefer:

* Local processing
* SQLite database
* Downloadable content packs
* Minimal backend usage

Avoid:

* Expensive AI APIs
* Heavy cloud computation
* Video streaming

---

## 5. Exam-Centered Learning

The main learning loop:

Practice Exam

↓

Identify Mistakes

↓

Understand Concepts

↓

Review Resources

↓

Practice Again

---

# Core Features

## Stream Selection (UPDATED — Preferred vs. Purchased)

Stream is now two distinct concepts (Decision 012):

* **Preferred Stream** — chosen on first launch, freely changeable later in Settings. Purely personalization: decides which subject list the user lands on by default. Changing it has no destructive consequence and requires no confirmation step.
* **Purchased Stream** — an entitlement, created only after payment verification (see Payment Model below). Actually controls which subjects/exams/resources the user can open. A user can hold zero, one, or eventually both stream entitlements.

The onboarding screen sets Preferred Stream; it is not a payment gate and not a permanent choice.

## Exam System

* Previous EUEE exams
* Preferred Stream selection (personalization, at onboarding and in Settings)
* Subject selection (default-sorted by Preferred Stream; access gated by Purchased/entitled stream)
* Year selection
* Chapter organization
* Real exam timer
* Optional timer removal
* Question navigation
* Submit exam
* Review answers

---

## Learning Resources

Resources are connected to chapters/topics:

* Short notes
* Flashcards
* Mind maps
* Explanations
* Textbook references

---

## Weakness Analysis

The app tracks:

* Questions attempted
* Correct answers
* Wrong answers
* Topic performance
* Improvement over time

The system calculates focus areas locally without requiring AI. Analysis is scoped to the user's entitled (purchased) stream's subjects, not their Preferred Stream.

---

## Content Structure (UPDATED)

Everything follows:

Grade *(Stream, for Grade 11-12 only, pedagogically)*

↓

Subject *(owned per-stream — see Decision 009)*

↓

Chapter

↓

Topic

↓

Resources + Questions

Note: a single question can be tagged to more than one Topic — see Decision 011. This matters because EUEE papers routinely combine multiple concepts (sometimes from different grades) into one question.

Navigation, however, does not expose this hierarchy directly to the user — see Decision 014. Students browse Subject-first; Grade appears as a grouping inside a subject, and Stream never appears as a navigation level outside onboarding/Settings.

---

# Payment Model

Free sample experience.

Paid users unlock complete content through a manual verification flow (Decision 013):

```
User pays externally → submits proof in-app → admin verifies → entitlement created → content unlocked
```

Content is delivered through downloadable packs, one per subject, organized per-stream (Decision 009 — fully separate, no sharing):

```
Natural Science Pack: English, Mathematics, SAT (Aptitude), Physics, Chemistry, Biology
Social Science Pack: English, Mathematics, SAT (Aptitude), Geography, History, Economics
```

12 subject packs total at MVP. Purchasing a stream (Natural Science or Social Science) unlocks all 6 subjects within it. The Entitlement model is built to support purchasing the second stream later without a redesign (Decision 012).

---

# Out of Scope

Not building initially:

* AI tutor
* Chatbot
* Social features
* Leaderboards
* Video courses
* Cloud synchronization
* Streak systems
* General Grade 9-10 school subjects not tested on the EUEE (e.g. Civics, ICT, PE) — this app is EUEE-scoped, not a general curriculum app

---

# Technology Direction

Frontend:

Flutter

Database:

SQLite

Future backend:

FastAPI (only if required)

Content pipeline:

Python scripts + AI-assisted processing

---

# Current Development Phase

Phase:

Product planning and architecture

Current goal:

Create a production-quality foundation before implementation. Stream selection has just been added as a required first-class concept and is being propagated through architecture, user flows, and decisions log before implementation begins.