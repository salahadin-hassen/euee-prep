"use server";

import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";

export type AssignMemberState = {
  error: string | null;
  success: boolean;
};

export async function assignMember(
  _prev: AssignMemberState,
  formData: FormData,
): Promise<AssignMemberState> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return { error: "You must be signed in.", success: false };
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  if (!profile || !canAccessAdminSurface(profile.role as AppRole)) {
    return { error: "Only admins can assign members.", success: false };
  }

  const projectId = formData.get("project_id");
  const userId = formData.get("user_id");
  const role = formData.get("role");

  if (
    typeof projectId !== "string" ||
    typeof userId !== "string" ||
    typeof role !== "string"
  ) {
    return { error: "Missing required fields.", success: false };
  }

  if (role !== "reviewer" && role !== "uploader") {
    return { error: "Role must be reviewer or uploader.", success: false };
  }

  const { error: insertError } = await supabase
    .from("project_members")
    .insert({
      project_id: projectId,
      user_id: userId,
      role,
    });

  if (insertError) {
    if (insertError.code === "23505") {
      return { error: "This user is already assigned to this project.", success: false };
    }
    return { error: `Failed to assign member: ${insertError.message}`, success: false };
  }

  const { error: auditError } = await supabase
    .from("audit_events")
    .insert({
      actor_id: user.id,
      action: "member.assigned",
      entity_type: "project",
      entity_id: projectId,
      metadata: { assigned_user_id: userId, role },
    });

  if (auditError) {
    return { error: `Assignment saved but audit log failed: ${auditError.message}`, success: false };
  }

  return { error: null, success: true };
}
