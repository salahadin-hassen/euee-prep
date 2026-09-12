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

  const startValue = String(formData.get("start_question") ?? "").trim();
  const endValue = String(formData.get("end_question") ?? "").trim();
  const startQuestion = startValue ? Number(startValue) : null;
  const endQuestion = endValue ? Number(endValue) : null;
  if ((startQuestion === null) !== (endQuestion === null)
      || (startQuestion !== null && endQuestion !== null && (!Number.isInteger(startQuestion) || !Number.isInteger(endQuestion) || startQuestion < 1 || endQuestion < startQuestion))) {
    return { error: "Enter a valid question range, or leave both range fields empty.", success: false };
  }

  const { data: candidates, error: lookupError } = await supabase
    .from("profiles")
    .select("id, display_name")
    .ilike("display_name", displayName.trim());

  if (lookupError) return { error: `Search failed: ${lookupError.message}`, success: false };
  if (!candidates || candidates.length === 0) {
    return { error: "Couldn't find anyone with that name. They may need to sign up first.", success: false };
  }
  if (candidates.length > 1) {
    return { error: "More than one person has that name. Ask them to use a unique display name.", success: false };
  }

  const target = candidates[0];

  const { error: insertError } = await supabase.rpc("assign_reviewer", {
    p_project_id: projectId,
    p_reviewer_id: target.id,
    p_start_order_index: startQuestion === null ? null : startQuestion - 1,
    p_end_order_index: endQuestion === null ? null : endQuestion - 1,
  });

  if (insertError) {
    return { error: `Couldn't add them: ${insertError.message}`, success: false };
  }

  return { error: null, success: true };
}
