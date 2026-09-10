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

  const { error: insertError } = await supabase.rpc("assign_project_member", {
    p_project_id: projectId,
    p_user_id: userId,
    p_role: role,
  });

  if (insertError) {
    if (insertError.code === "23505") {
      return { error: "This user is already assigned to this project.", success: false };
    }
    return { error: `Failed to assign member: ${insertError.message}`, success: false };
  }

  return { error: null, success: true };
}
