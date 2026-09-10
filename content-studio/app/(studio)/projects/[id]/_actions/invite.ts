"use server";

import { createClient } from "@/lib/supabase/server";

export type InviteState = {
  error: string | null;
  success: boolean;
};

export async function inviteHelper(
  _prev: InviteState,
  formData: FormData,
): Promise<InviteState> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", success: false };

  const projectId = formData.get("project_id") as string;
  const displayName = formData.get("display_name") as string;
  if (!projectId || !displayName?.trim()) return { error: "Name is required.", success: false };

  const { data: candidates, error: lookupError } = await supabase
    .from("profiles")
    .select("id, display_name")
    .ilike("display_name", displayName.trim());

  if (lookupError) return { error: `Search failed: ${lookupError.message}`, success: false };
  if (!candidates || candidates.length === 0) {
    return { error: "Couldn't find anyone with that name. They may need to sign up first.", success: false };
  }

  const target = candidates[0];

  const { error: insertError } = await supabase.rpc("assign_project_member", {
    p_project_id: projectId,
    p_user_id: target.id,
    p_role: "reviewer",
  });

  if (insertError) {
    if (insertError.code === "23505") {
      return { error: "They're already helping with this paper.", success: false };
    }
    return { error: `Couldn't add them: ${insertError.message}`, success: false };
  }

  return { error: null, success: true };
}
