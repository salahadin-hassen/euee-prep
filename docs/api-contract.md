# EUEE Prep — API Contract (Payment Backend Only)

Status: v2 — **Contract only.** Covers exactly the surface Decisions 013/017 require — payment requests, entitlements, and content pack distribution. No implementation here; that's Milestone 7 (Payment UI) task 3 for the backend, and Milestone 3 for pack hosting. Nothing outside this scope is defined, per Decision 017's hard local-first boundary — this backend never sees Attempts, progress, or Preferred Stream.

---

## Install identity (Decision 032)

`install_id` is a persistent anonymous identity: a UUID generated on-device at first launch, stored locally, and never reset except by reinstall. It is the only identity the backend ever sees at MVP — no user accounts, no login, no profile. All payment submissions and entitlement lookups are keyed by it.

Trust limitation (accepted at MVP): `install_id` is bearer-only — possession is proof. A stronger authentication scheme remains an explicitly flagged decision; do not invent one.

---

## `POST /api/payment-requests`

Submit a new payment request.

Request:
```json
{
  "install_id": "string",
  "stream": "natural_science | social_science",
  "proof_type": "screenshot | transaction_id",
  "proof_value": "string"
}
```

Response `201`:
```json
{
  "request_id": "string (UUID)",
  "status": "pending",
  "submitted_at": "ISO8601 string"
}
```

`request_id` is the canonical identifier per Decision 023 — the client stores this, not the proof itself, for all subsequent status checks.

---

## `GET /api/payment-requests/{request_id}`

Check status of a previously submitted request.

Response `200`:
```json
{
  "request_id": "string",
  "status": "pending | verified | rejected",
  "submitted_at": "ISO8601 string",
  "verified_at": "ISO8601 string | null",
  "rejection_reason": "string | null"
}
```

Payment requests persist exactly three states (Decision 036): `pending`, `verified`, `rejected`. "Submitted" is the event that creates a pending row; `entitled` is never a payment state — entitlement is a separate record, surfaced by the endpoint below.

---

## `GET /api/entitlements?install_id={install_id}`

Check current entitlements for an install — this is what the app calls on manual refresh (Decision 013's "no real-time push" note).

Response `200`:
```json
{
  "entitlements": [
    {
      "stream": "natural_science",
      "status": "active",
      "granted_at": "ISO8601 string",
      "revoked_at": "ISO8601 string | null"
    }
  ]
}
```

Entitlements are revocable and never expire on their own (Decision 033): `status` is `active` or `revoked`, with `revoked_at` set on revocation (refund, chargeback, fraud). A revoked entitlement re-locks that stream's content on the device's next refresh. The client caches these rows locally (server → device only) for offline access checks.

---

## `GET /api/published-papers?stream={slug}&subject={slug}&year={year}`

Fetch the published v3 exam papers the Past Papers screen offers for download. All three parameters are optional filters (applied when present); malformed values fail the whole request with `400`. The response lists **one entry per published pack version** so students can download individual subject/year papers.

Implemented by the Content Studio route handler `app/api/published-papers/route.ts`, which reads `public.published_papers` with the service-role client (secrets stay server-side; there is deliberately no `to anon` RLS policy) and mints each `download_url` as a short-lived signed URL (TTL 3600 s) for the private `published-papers` bucket. Responses carry `Cache-Control: public, max-age=60`.

Response `200`:
```json
{
  "papers": [
    {
      "id": "uuid",
      "pack_id": "physics-2015-natural-science",
      "subject_slug": "physics",
      "subject_title": "Physics",
      "stream": "natural_science",
      "year": 2015,
      "title": "EUEE Physics 2015",
      "question_count": 30,
      "pack_version": "1.0.0",
      "size_bytes": 123456,
      "storage_path": "physics-2015-natural-science/1.0.0.zip",
      "published_at": "ISO8601 string",
      "minimum_app_version": "1.0.0",
      "updated_at": "ISO8601 string",
      "download_url": "short-lived signed URL"
    }
  ]
}
```

> **Note:** this supersedes the earlier `GET /api/content-packs` sketch below, which returned only the single latest pack for a subject. Packs are immutable per version (Decision 015/021) and students download papers one at a time, so the catalog enumerates every published `pack_id` + `pack_version` instead. The old sketch is kept for reference until the endpoint is removed from history.

---

## Explicitly out of scope

* Admin verification interface (how a payment request gets marked `verified`) — internal/manual per Decision 013, not a contract the app consumes.
* Authentication scheme beyond bearer `install_id` — not yet decided (Decision 032 makes `install_id` the MVP trust anchor); flagging rather than inventing one.
* How screenshot proof files are transported (inline payload vs. separate upload endpoint) — not yet defined; flagged. `proof_value` for `transaction_id` proofs is a plain string; the screenshot transport mechanism needs a decision before Milestone 7, task 3.
* Any endpoint touching Attempts, progress, or Preferred Stream — these never leave the device (Decision 017), so no such endpoint will ever exist in this contract.
