"use server";

import { createClient } from "@/lib/supabase/server";

export type RevokeState = {
  error: string | null;
  success: boolean;
};

export async function revokeAssignment(
  _prev: RevokeState,
  formData: FormData,
): Promise<RevokeState> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", success: false };

  const assignmentId = formData.get("assignment_id") as string;
  if (!assignmentId) return { error: "Missing assignment ID.", success: false };

  const { error } = await supabase.rpc("revoke_review_assignment", {
    p_assignment_id: assignmentId,
  });

  if (error) return { error: `Could not revoke: ${error.message}`, success: false };
  return { error: null, success: true };
}
