import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  buildPublishedPaperRow,
  parsePublishedPaperQuery,
  publishedPaperStoragePath,
  serializePublishedPaper,
} from "../lib/published-papers.ts";
import { buildContentPack } from "../lib/export-pack.ts";
import {
  SAMPLE_GENERATED_AT,
  sampleProject,
  sampleQuestions,
} from "./fixtures/export-sample.ts";

const migrationSource = readFileSync(
  resolve(process.cwd(), "supabase/migrations/20261001000000_published_papers.sql"),
  "utf8",
);
const routeSource = readFileSync(
  resolve(process.cwd(), "app/api/published-papers/route.ts"),
  "utf8",
);
const publishActionSource = readFileSync(
  resolve(process.cwd(), "app/(studio)/projects/[id]/_actions/publish.ts"),
  "utf8",
);
const pageSource = readFileSync(
  resolve(process.cwd(), "app/(studio)/projects/[id]/page.tsx"),
  "utf8",
);

const samplePack = buildContentPack(sampleProject, sampleQuestions, SAMPLE_GENERATED_AT);

describe("published paper catalog row", () => {
  it("derives the catalog row from a signed v3 pack", () => {
    const row = buildPublishedPaperRow(samplePack, 12345, "2026-10-01T00:00:00.000Z");

    assert.equal(row.pack_id, "biology-2018-natural_science");
    assert.equal(row.subject_slug, "biology");
    assert.equal(row.subject_title, "Biology");
    assert.equal(row.stream, "natural_science");
    assert.equal(row.year, 2018);
    assert.equal(row.title, sampleProject.title);
    assert.equal(row.question_count, 4);
    assert.equal(row.pack_version, "1.0.0");
    assert.equal(row.size_bytes, 12345);
    assert.equal(row.storage_path, "biology-2018-natural_science/1.0.0.zip");
    assert.equal(row.minimum_app_version, "1.0.0");
    assert.equal(row.published_at, "2026-10-01T00:00:00.000Z");
    assert.equal(row.updated_at, "2026-10-01T00:00:00.000Z");
  });

  it("uses one storage object per pack version", () => {
    assert.equal(
      publishedPaperStoragePath("biology-2018-natural_science", "1.0.0"),
      "biology-2018-natural_science/1.0.0.zip",
    );
  });

  it("rejects a pack missing catalog metadata", () => {
    const incomplete = { ...samplePack };
    delete (incomplete as Record<string, unknown>).paper;
    assert.throws(() => buildPublishedPaperRow(incomplete, 12345), /paper\.year/);
  });

  it("rejects a non-positive ZIP size", () => {
    assert.throws(() => buildPublishedPaperRow(samplePack, 0), /size_bytes/);
  });
});

describe("published papers query parsing", () => {
  it("accepts an empty query (no filters)", () => {
    const query = parsePublishedPaperQuery(new URLSearchParams());
    assert.deepEqual(query, { stream: null, subjectSlug: null, year: null, error: null });
  });

  it("accepts valid stream, subject, and year filters", () => {
    const query = parsePublishedPaperQuery(
      new URLSearchParams("stream=natural_science&subject=biology&year=2018"),
    );
    assert.equal(query.stream, "natural_science");
    assert.equal(query.subjectSlug, "biology");
    assert.equal(query.year, 2018);
    assert.equal(query.error, null);
  });

  it("rejects an unknown stream", () => {
    const query = parsePublishedPaperQuery(new URLSearchParams("stream=arts"));
    assert.match(query.error ?? "", /Invalid stream/);
  });

  it("rejects a malformed subject slug", () => {
    for (const subject of ["Biology", "bio_1", "../etc", ""]) {
      const query = parsePublishedPaperQuery(new URLSearchParams({ subject }));
      assert.match(query.error ?? "", /Invalid subject/);
    }
  });

  it("rejects a malformed year", () => {
    for (const year of ["abc", "20181", "18"]) {
      const query = parsePublishedPaperQuery(new URLSearchParams({ year }));
      assert.match(query.error ?? "", /Invalid year/);
    }
  });
});

describe("published papers API serialization", () => {
  it("serializes every catalog field plus the signed download URL", () => {
    const row = buildPublishedPaperRow(samplePack, 999, "2026-10-01T00:00:00.000Z");
    const json = serializePublishedPaper(row, "https://storage.example/signed.zip");

    assert.deepEqual(Object.keys(json).sort(), [
      "download_url",
      "id",
      "minimum_app_version",
      "pack_id",
      "pack_version",
      "published_at",
      "question_count",
      "size_bytes",
      "storage_path",
      "stream",
      "subject_slug",
      "subject_title",
      "title",
      "updated_at",
      "year",
    ]);
    assert.equal(json.download_url, "https://storage.example/signed.zip");
    assert.equal(json.pack_id, "biology-2018-natural_science");
    assert.equal(json.year, 2018);
  });
});

describe("published papers migration contract", () => {
  it("creates one catalog table with per-version uniqueness", () => {
    assert.match(migrationSource, /create table public\.published_papers/);
    assert.match(migrationSource, /unique \(pack_id, pack_version\)/);
    assert.match(migrationSource, /storage_path text not null unique/);
  });

  it("indexes stream, subject, year, and pack_id", () => {
    assert.match(migrationSource, /create index published_papers_stream_idx/);
    assert.match(migrationSource, /create index published_papers_subject_idx on public\.published_papers \(stream, subject_slug\)/);
    assert.match(migrationSource, /create index published_papers_year_idx/);
    assert.match(migrationSource, /create index published_papers_pack_id_idx/);
  });

  it("keeps the catalog out of anon reach", () => {
    assert.match(migrationSource, /alter table public\.published_papers enable row level security/);
    assert.doesNotMatch(migrationSource, /create policy[\s\S]{0,200}to anon/);
    assert.match(migrationSource, /revoke all on public\.published_papers from anon/);
    assert.match(migrationSource, /using \(public\.is_admin_or_owner\(\)\)/);
  });

  it("stores ZIPs in a private bucket, never in the database", () => {
    assert.match(migrationSource, /values \('published-papers', 'published-papers', false\)/);
    assert.doesNotMatch(migrationSource, /bytea|zip content|blob/i);
    assert.match(migrationSource, /bucket_id = 'published-papers' and public\.is_admin_or_owner\(\)/);
  });
});

describe("published papers transport contract", () => {
  it("serves the catalog through the service role with signed URLs", () => {
    assert.match(routeSource, /createServiceClient\(\)/);
    assert.match(routeSource, /createSignedUrls\(/);
    assert.match(routeSource, /PUBLISHED_PAPERS_BUCKET/);
    assert.match(routeSource, /PUBLISHED_PAPER_SIGNED_URL_TTL_SECONDS/);
  });

  it("is a read-only endpoint with validated filters", () => {
    assert.match(routeSource, /export async function GET/);
    assert.match(routeSource, /parsePublishedPaperQuery\(/);
    assert.doesNotMatch(routeSource, /\.insert\(|\.update\(|\.delete\(|\.upsert\(/);
  });

  it("publishing stays behind the admin server action", () => {
    assert.match(publishActionSource, /"owner"/);
    assert.match(publishActionSource, /"admin"/);
    assert.match(publishActionSource, /Only admins can publish/);
    assert.match(publishActionSource, /PUBLISHED_PAPERS_BUCKET/);
    assert.match(publishActionSource, /\.upload\(storagePath/);
    assert.match(publishActionSource, /\.upsert\(/);
    assert.match(publishActionSource, /onConflict: "pack_id,pack_version"/);
  });

  it("exposes publishing in the approved-paper admin UI", () => {
    assert.match(pageSource, /PublishButton/);
    assert.ok(
      pageSource.includes('typed.status === "approved"') && pageSource.includes("PublishButton"),
      "publish button must only appear for approved papers",
    );
  });
});
