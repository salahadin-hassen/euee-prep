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

## `GET /api/content-packs?stream={slug}&subject={slug}`

Fetch the latest published pack metadata (and download URL) for a subject. **Both parameters are required** (Decision 009/031): subject slugs are per-stream — both streams have their own `mathematics`, `english`, and `sat_aptitude` records — so a subject slug alone is ambiguous.

Response `200`:
```json
{
  "pack_version": "string",
  "schema_version": "string",
  "generated_at": "ISO8601 string",
  "checksum": "string",
  "minimum_app_version": "string",
  "download_url": "string"
}
```

---

## Explicitly out of scope

* Admin verification interface (how a payment request gets marked `verified`) — internal/manual per Decision 013, not a contract the app consumes.
* Authentication scheme beyond bearer `install_id` — not yet decided (Decision 032 makes `install_id` the MVP trust anchor); flagging rather than inventing one.
* How screenshot proof files are transported (inline payload vs. separate upload endpoint) — not yet defined; flagged. `proof_value` for `transaction_id` proofs is a plain string; the screenshot transport mechanism needs a decision before Milestone 7, task 3.
* Any endpoint touching Attempts, progress, or Preferred Stream — these never leave the device (Decision 017), so no such endpoint will ever exist in this contract.
