/**
 * Pure published-paper catalog logic for Content Studio.
 *
 * Covers the catalog row built at publish time, the read-model served by
 * `app/api/published-papers/route.ts`, and the query validation that route
 * performs. Everything here is side-effect free so tests can execute the real
 * publish/catalog path; `_actions/publish.ts` only wraps it with
 * authentication, database access, and Storage transport.
 *
 * One row = one published pack version. The ZIP lives in the private
 * `published-papers` Storage bucket; the catalog only references it by
 * `storage_path`, and downloads go through short-lived signed URLs.
 */

import { CONTENT_PACK_STREAMS, normalizeStream, type ContentPackStream } from "./export-pack.ts";

/** Private Storage bucket holding published pack ZIPs. */
export const PUBLISHED_PAPERS_BUCKET = "published-papers";

/** Lifetime of the signed download URLs handed to the student app. */
export const PUBLISHED_PAPER_SIGNED_URL_TTL_SECONDS = 3600;

/** Rows of `public.published_papers` (snake_case mirrors the table exactly). */
export interface PublishedPaperRow {
  id?: string;
  pack_id: string;
  subject_slug: string;
  subject_title: string;
  stream: ContentPackStream;
  year: number;
  title: string;
  question_count: number;
  pack_version: string;
  size_bytes: number;
  storage_path: string;
  published_at: string;
  minimum_app_version: string;
  updated_at: string;
}

/** Object storage key for a published pack ZIP: `{pack_id}/{pack_version}.zip`. */
export function publishedPaperStoragePath(packId: string, packVersion: string): string {
  return `${packId}/${packVersion}.zip`;
}

function requireString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new Error(`Published paper field "${field}" must be a non-empty string.`);
  }
  return value;
}

function requirePositiveInt(value: unknown, field: string): number {
  if (typeof value !== "number" || !Number.isInteger(value) || value <= 0) {
    throw new Error(`Published paper field "${field}" must be a positive integer.`);
  }
  return value;
}

/**
 * Derives the catalog row for a signed v3 pack plus the byte size of its ZIP.
 *
 * Throws (never returns partial data) when the pack is missing metadata the
 * catalog needs — the same fail-fast style as `buildContentPack`.
 * `publishedAt`/`updatedAt` are injectable so tests stay deterministic.
 */
export function buildPublishedPaperRow(
  pack: Record<string, unknown>,
  zipByteLength: number,
  now: string = new Date().toISOString(),
): PublishedPaperRow {
  const subject = (pack.subject ?? {}) as { slug?: unknown; title?: unknown };
  const paper = (pack.paper ?? {}) as { year?: unknown; title?: unknown; question_count?: unknown };

  const stream = normalizeStream(requireString(pack.stream, "stream"));

  return {
    pack_id: requireString(pack.pack_id, "pack_id"),
    subject_slug: requireString(subject.slug, "subject.slug"),
    subject_title: requireString(subject.title, "subject.title"),
    stream,
    year: requirePositiveInt(paper.year, "paper.year"),
    title: requireString(paper.title, "paper.title"),
    question_count: requirePositiveInt(paper.question_count, "paper.question_count"),
    pack_version: requireString(pack.pack_version, "pack_version"),
    size_bytes: requirePositiveInt(zipByteLength, "size_bytes"),
    storage_path: publishedPaperStoragePath(
      requireString(pack.pack_id, "pack_id"),
      requireString(pack.pack_version, "pack_version"),
    ),
    published_at: now,
    minimum_app_version: requireString(pack.minimum_app_version, "minimum_app_version"),
    updated_at: now,
  };
}

/** Validated filters parsed from the catalog endpoint's query string. */
export interface PublishedPaperQuery {
  stream: ContentPackStream | null;
  subjectSlug: string | null;
  year: number | null;
  error: string | null;
}

/**
 * Parses and validates `?stream=&subject=&year=` filters.
 *
 * All parameters are optional; any malformed value fails the whole request
 * with a human-readable error instead of being silently ignored.
 */
export function parsePublishedPaperQuery(params: URLSearchParams): PublishedPaperQuery {
  const streamRaw = params.get("stream");
  const subjectRaw = params.get("subject");
  const yearRaw = params.get("year");

  let stream: ContentPackStream | null = null;
  if (streamRaw != null) {
    if (!(CONTENT_PACK_STREAMS as readonly string[]).includes(streamRaw)) {
      return { stream: null, subjectSlug: null, year: null, error: `Invalid stream: "${streamRaw}".` };
    }
    stream = normalizeStream(streamRaw);
  }

  let subjectSlug: string | null = null;
  if (subjectRaw != null) {
    if (!/^[a-z0-9][a-z0-9-]*$/.test(subjectRaw)) {
      return { stream: null, subjectSlug: null, year: null, error: `Invalid subject: "${subjectRaw}".` };
    }
    subjectSlug = subjectRaw;
  }

  let year: number | null = null;
  if (yearRaw != null) {
    if (!/^\d{4}$/.test(yearRaw)) {
      return { stream: null, subjectSlug: null, year: null, error: `Invalid year: "${yearRaw}".` };
    }
    year = Number(yearRaw);
  }

  return { stream, subjectSlug, year, error: null };
}

/** JSON shape returned by `GET /api/published-papers` (one entry per paper). */
export function serializePublishedPaper(
  row: PublishedPaperRow,
  downloadUrl: string,
): Record<string, unknown> {
  return {
    id: row.id ?? null,
    pack_id: row.pack_id,
    subject_slug: row.subject_slug,
    subject_title: row.subject_title,
    stream: row.stream,
    year: row.year,
    title: row.title,
    question_count: row.question_count,
    pack_version: row.pack_version,
    size_bytes: row.size_bytes,
    storage_path: row.storage_path,
    published_at: row.published_at,
    minimum_app_version: row.minimum_app_version,
    updated_at: row.updated_at,
    download_url: downloadUrl,
  };
}
