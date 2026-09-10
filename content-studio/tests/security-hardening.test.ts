import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const migrationPath = resolve(process.cwd(), "supabase/migrations/20260912000000_m1_5_security_followup.sql");
const migration = readFileSync(migrationPath, "utf8");

describe("M1.5 migration security contract", () => {
  it("revokes direct authenticated workflow mutations", () => {
    assert.match(migration, /revoke insert, update, delete on public\.audit_events from public, anon, authenticated/);
    assert.match(migration, /revoke execute on function public\.create_project\(text, integer, text, text\) from public, anon/);
    assert.match(migration, /revoke execute on function public\.approve_project\(uuid\) from public, anon/);
  });

  it("grants only authenticated access to client RPCs", () => {
    assert.match(migration, /grant execute on function public\.create_project\(text, integer, text, text\) to authenticated/);
    assert.match(migration, /grant execute on function public\.verify_question\(uuid\) to authenticated/);
    assert.match(migration, /grant execute on function public\.set_question_image_path\(uuid, uuid, text\) to authenticated/);
  });

  it("locks the parent project before review mutations", () => {
    assert.match(migration, /from public\.projects where id = question_row\.project_id for update/);
    assert.match(migration, /from public\.projects where id = p_project_id for update/);
    assert.match(migration, /perform 1 from public\.questions where project_id = p_project_id for update/);
  });

  it("requires verification metadata during approval", () => {
    assert.match(migration, /q\.status <> 'verified'/);
    assert.match(migration, /q\.verified_by is null/);
    assert.match(migration, /q\.verified_at is null/);
    assert.match(migration, /alter table public\.questions validate constraint questions_verification_consistency/);
  });

  it("defines the explicit project lifecycle transitions", () => {
    assert.match(migration, /status in \('draft', 'in_review', 'blocked'\)/);
    assert.match(migration, /project_status_value <> 'ready_for_approval'/);
    assert.match(migration, /current_status <> 'approved'/);
    assert.match(migration, /project_status_value <> 'approved'/);
  });

  it("prevents direct deletion of attached storage objects", () => {
    assert.match(migration, /authorized users can delete unreferenced question images/);
    assert.match(migration, /not exists \(select 1 from public\.questions q where q\.image_path = name\)/);
    assert.doesNotMatch(migration, /create policy "authorized users can update question images"/);
  });
});

describe("M1.5 application RPC callers", () => {
  const actionFiles = [
    "app/(studio)/_actions/project.ts",
    "app/(studio)/_actions/member.ts",
    "app/(studio)/projects/[id]/_actions/invite.ts",
    "app/(studio)/projects/[id]/review/_actions/edit.ts",
    "app/(studio)/projects/[id]/review/_actions/flag.ts",
    "app/(studio)/projects/[id]/review/_actions/verify-redirect.ts",
    "app/(studio)/projects/[id]/review/_actions/upload-image.ts",
    "app/(studio)/_actions/approval.ts",
  ];

  it("uses RPCs for all workflow mutations", () => {
    for (const file of actionFiles) {
      const source = readFileSync(resolve(process.cwd(), file), "utf8");
      assert.match(source, /supabase\.rpc\(/, `${file} must call a database RPC`);
      assert.doesNotMatch(source, /from\("(projects|project_members|questions|audit_events)"\)[\s\S]*\.(insert|update|delete)\(/, `${file} contains a direct workflow table mutation`);
    }
  });

  it("does not write audit events from server actions", () => {
    for (const file of actionFiles) {
      const source = readFileSync(resolve(process.cwd(), file), "utf8");
      assert.doesNotMatch(source, /from\("audit_events"\)/, `${file} must not write audit events directly`);
    }
  });
});
