import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { canAccessAdminSurface, canAccessReviewerSurface, dashboardPath, isAdminRole } from "../lib/auth/roles.ts";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

describe("role boundaries", () => {
  it("limits the admin surface to owner and admin", () => {
    assert.equal(isAdminRole("owner"), true);
    assert.equal(isAdminRole("admin"), true);
    assert.equal(canAccessAdminSurface("reviewer"), false);
    assert.equal(canAccessAdminSurface("uploader"), false);
  });

  it("routes operational roles to the appropriate workspace", () => {
    assert.equal(dashboardPath("owner"), "/admin");
    assert.equal(dashboardPath("admin"), "/admin");
    assert.equal(dashboardPath("reviewer"), "/reviewer");
    assert.equal(dashboardPath("uploader"), "/reviewer");
    assert.equal(canAccessReviewerSurface("reviewer"), true);
  });
});

describe("database authorization contract", () => {
  const migration = readFileSync(resolve(process.cwd(), "supabase/migrations/20260908000000_initial_content_studio.sql"), "utf8");

  it("enables RLS on every M1 table", () => {
    for (const table of ["profiles", "projects", "project_members", "audit_events"]) {
      assert.match(migration, new RegExp(`alter table public\\.${table} enable row level security;`));
    }
  });

  it("keeps collaboration data admin-only while scoping memberships", () => {
    assert.match(migration, /create policy "admins can read all memberships"/);
    assert.match(migration, /create policy "reviewers can read their own membership"/);
    assert.match(migration, /create policy "admins can read audit events"/);
    assert.doesNotMatch(migration, /on public\.audit_events for select to authenticated\n  using \(true\)/);
  });
});
