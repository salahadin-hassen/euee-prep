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

  const { error: insertError } = await supabase
    .from("project_members")
    .insert({
      project_id: projectId,
      user_id: target.id,
      role: "reviewer",
    });

  if (insertError) {
    if (insertError.code === "23505") {
      return { error: "They're already helping with this paper.", success: false };
    }
    return { error: `Couldn't add them: ${insertError.message}`, success: false };
  }

  await supabase.from("audit_events").insert({
    actor_id: user.id,
    action: "member.invited",
    entity_type: "project",
    entity_id: projectId,
    metadata: { invited_user_id: target.id, invited_name: target.display_name },
  });

  return { error: null, success: true };
}
