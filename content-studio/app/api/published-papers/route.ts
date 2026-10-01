import { NextResponse, type NextRequest } from "next/server";
import { createServiceClient } from "@/lib/supabase/service";
import {
  PUBLISHED_PAPERS_BUCKET,
  PUBLISHED_PAPER_SIGNED_URL_TTL_SECONDS,
  parsePublishedPaperQuery,
  serializePublishedPaper,
  type PublishedPaperRow,
} from "@/lib/published-papers";

/**
 * Student-facing catalog: `GET /api/published-papers?stream=&subject=&year=`.
 *
 * Public read of *published* rows only (the table itself stays RLS-protected;
 * the service role reads on the student app's behalf) plus short-lived signed
 * download URLs for the private ZIP bucket. Publishing/mutations never happen
 * here — they stay behind the admin-gated studio server action.
 */
export async function GET(request: NextRequest) {
  try {
    const query = parsePublishedPaperQuery(request.nextUrl.searchParams);
    if (query.error) return NextResponse.json({ error: query.error }, { status: 400 });

    const supabase = createServiceClient();

    let builder = supabase
      .from("published_papers")
      .select("*")
      .order("year", { ascending: false })
      .order("subject_slug", { ascending: true });
    if (query.stream) builder = builder.eq("stream", query.stream);
    if (query.subjectSlug) builder = builder.eq("subject_slug", query.subjectSlug);
    if (query.year) builder = builder.eq("year", query.year);

    const { data, error } = await builder;
    if (error) {
      return NextResponse.json({ error: "Could not load published papers" }, { status: 502 });
    }

    const rows = (data ?? []) as unknown as PublishedPaperRow[];
    if (rows.length === 0) {
      return NextResponse.json(
        { papers: [] },
        { headers: { "Cache-Control": "public, max-age=60" } },
      );
    }

    const { data: signed, error: signError } = await supabase.storage
      .from(PUBLISHED_PAPERS_BUCKET)
      .createSignedUrls(
        rows.map((row) => row.storage_path),
        PUBLISHED_PAPER_SIGNED_URL_TTL_SECONDS,
      );
    if (signError || !signed) {
      return NextResponse.json({ error: "Could not sign download URLs" }, { status: 502 });
    }

    const urlByPath = new Map<string, string>();
    for (const entry of signed) {
      if (entry.error || !entry.path || !entry.signedUrl) {
        return NextResponse.json({ error: "Could not sign download URLs" }, { status: 502 });
      }
      urlByPath.set(entry.path, entry.signedUrl);
    }

    return NextResponse.json(
      {
        papers: rows.map((row) => {
          const downloadUrl = urlByPath.get(row.storage_path);
          if (!downloadUrl) {
            throw new Error(`Missing signed URL for ${row.storage_path}`);
          }
          return serializePublishedPaper(row, downloadUrl);
        }),
      },
      { headers: { "Cache-Control": "public, max-age=60" } },
    );
  } catch {
    return NextResponse.json({ error: "Could not load published papers" }, { status: 500 });
  }
}
