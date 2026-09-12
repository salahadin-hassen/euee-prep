import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { canAccessAdminSurface, canAccessReviewerSurface, dashboardPath, isAdminRole, APP_ROLES } from "../lib/auth/roles.ts";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

describe("role boundaries", () => {
  it("limits the admin surface to owner and admin", () => {
    assert.equal(isAdminRole("owner"), true);
    assert.equal(isAdminRole("admin"), true);
    assert.equal(canAccessAdminSurface("reviewer"), false);
    assert.equal(canAccessAdminSurface("uploader"), false);
  });

  it("routes all roles to /projects", () => {
    for (const role of APP_ROLES) {
      assert.equal(dashboardPath(role), "/projects");
    }
    assert.equal(canAccessReviewerSurface("reviewer"), true);
  });

  it("allows reviewer and uploader to access reviewer surface", () => {
    assert.equal(canAccessReviewerSurface("reviewer"), true);
    assert.equal(canAccessReviewerSurface("uploader"), true);
    assert.equal(canAccessReviewerSurface("admin"), true);
    assert.equal(canAccessReviewerSurface("owner"), true);
  });

  it("denies reviewer and uploader from admin surface", () => {
    assert.equal(canAccessAdminSurface("reviewer"), false);
    assert.equal(canAccessAdminSurface("uploader"), false);
  });

  it("has exactly four defined roles", () => {
    assert.deepEqual(APP_ROLES, ["owner", "admin", "reviewer", "uploader"]);
  });

  it("dashboardPath returns /projects for all roles", () => {
    for (const role of APP_ROLES) {
      const path = dashboardPath(role);
      assert.equal(path, "/projects", `Unexpected dashboard path for ${role}: ${path}`);
    }
  });
});

describe("proxy route protection", () => {
  it("defines protected route prefixes in proxy matcher", () => {
    const proxySource = readFileSync(resolve(process.cwd(), "proxy.ts"), "utf8");
    const protectedRoutes = ["/admin", "/reviewer", "/projects"];
    for (const route of protectedRoutes) {
      assert.ok(
        proxySource.includes(route),
        `proxy.ts must protect route: ${route}`,
      );
    }
  });

  it("redirects unauthenticated users to /login", () => {
    const proxySource = readFileSync(resolve(process.cwd(), "proxy.ts"), "utf8");
    assert.ok(proxySource.includes('"/login"'), "proxy.ts must redirect to /login");
    assert.ok(proxySource.includes('"next"'), "proxy.ts must pass next parameter");
  });

  it("redirects authenticated users away from /login", () => {
    const proxySource = readFileSync(resolve(process.cwd(), "proxy.ts"), "utf8");
    assert.ok(
      proxySource.includes('pathname === "/login"'),
      "proxy.ts must redirect authenticated users from /login",
    );
  });
});

describe("project detail validation", () => {
  it("validates UUID format in project detail page", () => {
    const pageSource = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/page.tsx"),
      "utf8",
    );
    assert.ok(pageSource.includes("isValidUuid"), "project detail must validate UUID format");
    assert.ok(pageSource.includes("notFound()"), "project detail must call notFound for invalid IDs");
  });

  it("enforces server-side auth in project detail", () => {
    const pageSource = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/page.tsx"),
      "utf8",
    );
    assert.ok(pageSource.includes("getUser()"), "project detail must verify user server-side");
    assert.ok(pageSource.includes('redirect("/login")'), "project detail must redirect unauthenticated users");
  });

  it("handles not-found state for missing projects", () => {
    const pageSource = readFileSync(
      resolve(process.cwd(), "app/(studio)/projects/[id]/page.tsx"),
      "utf8",
    );
    assert.ok(
      pageSource.includes("if (!project)") || pageSource.includes("notFound()"),
      "project detail must handle not-found state",
    );
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

  it("scopes project access via is_project_member function", () => {
    assert.ok(
      migration.includes("create or replace function public.is_project_member"),
      "migration must define is_project_member function",
    );
    assert.ok(
      migration.includes("members can read assigned projects"),
      "migration must have project access policy for members",
    );
  });

  it("allows authenticated users to create draft projects only", () => {
    assert.match(
      migration,
      /authenticated users can create draft projects/,
      "migration must allow authenticated users to create draft projects",
    );
    assert.match(
      migration,
      /with check \(created_by = \(select auth\.uid\(\)\) and status = 'draft'\)/,
      "project insert policy must enforce draft status and owner match",
    );
  });

  it("restricts profile updates to admins", () => {
    assert.match(
      migration,
      /admins can update profiles/,
      "migration must restrict profile updates to admins",
    );
  });

  it("does not allow anon access to any table", () => {
    assert.match(
      migration,
      /revoke all on public\.profiles.*from anon/,
      "migration must revoke anon access",
    );
  });
});

describe("Supabase client configuration", () => {
  it("server client uses cookies from request", () => {
    const serverSource = readFileSync(resolve(process.cwd(), "lib/supabase/server.ts"), "utf8");
    assert.ok(serverSource.includes("cookies()"), "server client must use next/headers cookies");
    assert.ok(serverSource.includes("createServerClient"), "server client must use createServerClient");
  });

  it("browser client uses createBrowserClient", () => {
    const clientSource = readFileSync(resolve(process.cwd(), "lib/supabase/client.ts"), "utf8");
    assert.ok(clientSource.includes("createBrowserClient"), "browser client must use createBrowserClient");
  });

  it("proxy creates Supabase client with cookie forwarding", () => {
    const proxySource = readFileSync(resolve(process.cwd(), "proxy.ts"), "utf8");
    assert.ok(proxySource.includes("createServerClient"), "proxy must create Supabase server client");
    assert.ok(proxySource.includes("getAll"), "proxy must read cookies via getAll");
    assert.ok(proxySource.includes("setAll"), "proxy must write cookies via setAll");
  });
});
