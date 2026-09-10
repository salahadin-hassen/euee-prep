import assert from "node:assert/strict";
import { describe, it, before, after } from "node:test";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const SUPABASE_URL = process.env.TEST_SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.TEST_SUPABASE_SERVICE_KEY;
const SUPABASE_PUBLISHABLE_KEY = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

function hasEnv(): boolean {
  return !!(SUPABASE_URL && SUPABASE_SERVICE_KEY && SUPABASE_PUBLISHABLE_KEY);
}

describe("create-project integration", { skip: !hasEnv() ? "Missing TEST_SUPABASE_URL or TEST_SUPABASE_SERVICE_KEY env vars" : false }, () => {
  let adminClient: SupabaseClient;
  let regularClient: SupabaseClient;
  let serviceClient: SupabaseClient;
  let adminUserId: string;
  let regularUserId: string;
  const createdProjectIds: string[] = [];

  before(async () => {
    serviceClient = createClient(SUPABASE_URL!, SUPABASE_SERVICE_KEY!);

    const adminEmail = `test-admin-${Date.now()}@integration.test`;
    const regularEmail = `test-regular-${Date.now()}@integration.test`;
    const testPassword = "TestPassword123!";

    const { data: adminAuth, error: adminErr } = await serviceClient.auth.admin.createUser({
      email: adminEmail,
      password: testPassword,
      email_confirm: true,
    });
    assert.equal(adminErr, null, `Admin user creation failed: ${adminErr?.message}`);
    adminUserId = adminAuth!.user.id;

    await serviceClient.from("profiles").upsert({
      id: adminUserId,
      role: "admin",
      display_name: "Test Admin",
    });

    const { data: regularAuth, error: regularErr } = await serviceClient.auth.admin.createUser({
      email: regularEmail,
      password: testPassword,
      email_confirm: true,
    });
    assert.equal(regularErr, null, `Regular user creation failed: ${regularErr?.message}`);
    regularUserId = regularAuth!.user.id;

    await serviceClient.from("profiles").upsert({
      id: regularUserId,
      role: "reviewer",
      display_name: "Test Reviewer",
    });

    adminClient = createClient(SUPABASE_URL!, SUPABASE_PUBLISHABLE_KEY!);
    await adminClient.auth.signInWithPassword({ email: adminEmail, password: testPassword });

    regularClient = createClient(SUPABASE_URL!, SUPABASE_PUBLISHABLE_KEY!);
    await regularClient.auth.signInWithPassword({ email: regularEmail, password: testPassword });
  });

  after(async () => {
    for (const pid of createdProjectIds) {
      await serviceClient.from("audit_events").delete().eq("entity_id", pid);
      await serviceClient.from("project_members").delete().eq("project_id", pid);
      await serviceClient.from("projects").delete().eq("id", pid);
    }
    if (adminUserId) await serviceClient.auth.admin.deleteUser(adminUserId);
    if (regularUserId) await serviceClient.auth.admin.deleteUser(regularUserId);
  });

  it("admin can create a draft project through the RPC", async () => {
    const { data, error } = await adminClient.rpc("create_project", {
      p_title: "Integration Test Project",
      p_exam_year: 2025,
      p_subject: "Mathematics",
      p_stream: "natural_science",
    });

    assert.equal(error, null, `Insert failed: ${error?.message}`);
    assert.ok(data, "Project should have an id");
    createdProjectIds.push(data);

    const { data: fetched } = await serviceClient
      .from("projects")
      .select("id, title, status, created_by")
      .eq("id", data)
      .single();

    assert.equal(fetched?.title, "Integration Test Project");
    assert.equal(fetched?.status, "draft");
    assert.equal(fetched?.created_by, adminUserId);
  });

  it("project creation atomically adds the creator as an admin member", async () => {
    const projectId = createdProjectIds[0];

    const { data: member } = await serviceClient
      .from("project_members")
      .select("project_id, user_id, role")
      .eq("project_id", projectId)
      .eq("user_id", adminUserId)
      .single();

    assert.equal(member?.role, "admin");
  });

  it("project creation writes the canonical audit event", async () => {
    const projectId = createdProjectIds[0];

    const { data: auditRow, error } = await serviceClient
      .from("audit_events")
      .select("action, entity_type, entity_id")
      .eq("entity_id", projectId)
      .eq("action", "project.created")
      .single();

    assert.equal(error, null, `Audit read failed: ${error?.message}`);
    assert.equal(auditRow?.action, "project.created");
    assert.equal(auditRow?.entity_type, "project");
  });

  it("even admins cannot insert audit events directly", async () => {
    const projectId = createdProjectIds[0];

    const { error } = await adminClient
      .from("audit_events")
      .insert({
        actor_id: adminUserId,
        action: "project.created",
        entity_type: "project",
        entity_id: projectId,
        metadata: { title: "Integration Test Project" },
      });

    assert.ok(error, "Direct audit insert should fail");
  });

  it("non-admin cannot insert into audit_events (RLS enforced)", async () => {
    const projectId = createdProjectIds[0];

    const { error } = await regularClient
      .from("audit_events")
      .insert({
        actor_id: regularUserId,
        action: "project.created",
        entity_type: "project",
        entity_id: projectId,
        metadata: { title: "Should fail" },
      });

    assert.ok(error, "Non-admin audit insert should fail");
    assert.ok(
      error!.message.includes("row-level security") || error!.code === "42501",
      `Expected RLS rejection, got: ${error!.message} (code: ${error!.code})`,
    );
  });

  it("non-admin cannot manage project_members (RLS enforced)", async () => {
    const projectId = createdProjectIds[0];

    const { error } = await regularClient
      .from("project_members")
      .insert({
        project_id: projectId,
        user_id: regularUserId,
        role: "reviewer",
      });

    assert.ok(error, "Non-admin member insert should fail");
    assert.ok(
      error!.message.includes("row-level security") || error!.code === "42501",
      `Expected RLS rejection, got: ${error!.message} (code: ${error!.code})`,
    );
  });

  it("admin can assign a reviewer through the RPC", async () => {
    const projectId = createdProjectIds[0];

    const { error } = await adminClient.rpc("assign_project_member", {
      p_project_id: projectId,
      p_user_id: regularUserId,
      p_role: "reviewer",
    });

    assert.equal(error, null, `Reviewer assign failed: ${error?.message}`);

    const { data: member } = await serviceClient
      .from("project_members")
      .select("role")
      .eq("project_id", projectId)
      .eq("user_id", regularUserId)
      .single();

    assert.equal(member?.role, "reviewer");
  });

  it("assigned reviewer can see the project (RLS allows member access)", async () => {
    const projectId = createdProjectIds[0];

    const { data, error } = await regularClient
      .from("projects")
      .select("id, title")
      .eq("id", projectId)
      .single();

    assert.equal(error, null, `Reviewer project read failed: ${error?.message}`);
    assert.equal(data?.id, projectId);
    assert.equal(data?.title, "Integration Test Project");
  });

  it("assigned reviewer can see their own membership", async () => {
    const projectId = createdProjectIds[0];

    const { data, error } = await regularClient
      .from("project_members")
      .select("project_id, role")
      .eq("project_id", projectId)
      .eq("user_id", regularUserId);

    assert.equal(error, null, `Membership read failed: ${error?.message}`);
    assert.equal(data?.length, 1);
    assert.equal(data?.[0].role, "reviewer");
  });

  it("duplicate assignment returns constraint violation", async () => {
    const projectId = createdProjectIds[0];

    const { error } = await adminClient.rpc("assign_project_member", {
      p_project_id: projectId,
      p_user_id: regularUserId,
      p_role: "uploader",
    });

    assert.ok(error, "Duplicate assignment should fail");
    assert.equal(error!.code, "23505", `Expected unique violation, got code: ${error!.code}`);
  });
});
