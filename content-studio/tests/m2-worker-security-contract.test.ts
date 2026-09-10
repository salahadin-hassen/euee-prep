import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const migration = readFileSync(resolve(process.cwd(), "supabase/migrations/20260914000000_m2_slice2_worker_staging.sql"), "utf8");
const followup = readFileSync(resolve(process.cwd(), "supabase/migrations/20260914010000_m2_worker_followup.sql"), "utf8");

describe("M2 worker security boundary", () => {
  it("adds leases and staging tables", () => {
    assert.match(migration, /claimed_by/);
    assert.match(migration, /lease_expires_at/);
    assert.match(migration, /worker_attempt_count/);
    assert.match(migration, /create table public\.extraction_questions/);
    assert.match(migration, /create table public\.extraction_visual_assets/);
    assert.match(migration, /unique \(job_page_id, question_number\)/);
  });

  it("restricts worker mutations to service_role", () => {
    for (const name of ["claim_extraction_job", "record_extraction_page_started", "record_extraction_page_failure", "record_extraction_page_result", "complete_extraction_job"]) {
      assert.match(migration, new RegExp(`revoke execute on function public\\.${name}`));
      assert.match(migration, new RegExp(`grant execute on function public\\.${name}.*to service_role`));
    }
    assert.doesNotMatch(migration, /grant execute on function public\.(claim_extraction_job|record_extraction_page_result).*to authenticated/);
  });

  it("supports atomic polling claims and private asset reads", () => {
    assert.match(followup, /for update\s+skip locked/);
    assert.match(followup, /create policy "project members can read extraction assets"/);
    assert.match(followup, /values \('extraction-assets', 'extraction-assets', false\)/);
  });
});

describe("M2 worker control routes", () => {
  it("keeps the service client and worker secret server-side", () => {
    const service = readFileSync(resolve(process.cwd(), "lib/supabase/service.ts"), "utf8");
    const auth = readFileSync(resolve(process.cwd(), "lib/worker/auth.ts"), "utf8");
    assert.match(service, /SUPABASE_SERVICE_ROLE_KEY/);
    assert.match(auth, /WORKER_SHARED_SECRET/);
    assert.doesNotMatch(service, /NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY/);
  });

  it("protects worker routes with the shared secret", () => {
    for (const file of [
      "app/api/worker/claim-next/route.ts",
      "app/api/worker/page-started/route.ts",
      "app/api/worker/page-result/route.ts",
      "app/api/worker/page-failure/route.ts",
      "app/api/worker/complete/route.ts",
    ]) {
      assert.match(readFileSync(resolve(process.cwd(), file), "utf8"), /requireWorkerSecret\(request\)/, file);
    }
  });
});
