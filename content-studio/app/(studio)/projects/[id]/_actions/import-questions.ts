"use server";

import { revalidatePath } from "next/cache";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";

export type ImportState = {
  error: string | null;
  success: boolean;
  count: number;
};

const MAX_PAYLOAD_BYTES = 2 * 1024 * 1024;

export async function importQuestions(
  _prev: ImportState,
  formData: FormData,
): Promise<ImportState> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", success: false, count: 0 };

  const { data: profile } = await supabase
    .from("profiles")
    .select("role")
    .eq("id", user.id)
    .single();
  if (!profile || !canAccessAdminSurface(profile.role as AppRole)) {
    return { error: "Only admins can import questions.", success: false, count: 0 };
  }

  const projectId = formData.get("project_id") as string;
  const file = formData.get("file") as File | null;
  if (!projectId) return { error: "Missing project.", success: false, count: 0 };
  if (!file || file.size === 0) return { error: "Choose a JSON file.", success: false, count: 0 };
  if (file.size > MAX_PAYLOAD_BYTES) {
    return { error: "JSON file is too large (max 2 MB).", success: false, count: 0 };
  }

  let rawText: string;
  try {
    rawText = await file.text();
  } catch {
    return { error: "Could not read the file.", success: false, count: 0 };
  }

  let parsed: unknown;
  try {
    parsed = JSON.parse(rawText);
  } catch {
    return { error: "File is not valid JSON.", success: false, count: 0 };
  }

  const payload = parsed as Record<string, unknown>;

  const { data, error } = await supabase.rpc("import_manual_questions", {
    p_project_id: projectId,
    p_raw_payload: payload,
    p_source_filename: file.name,
  });

  if (error) {
    return { error: `Import failed: ${error.message}`, success: false, count: 0 };
  }

  const count = (data as number) ?? 0;
  revalidatePath(`/projects/${projectId}`);
  return { error: null, success: true, count };
}
