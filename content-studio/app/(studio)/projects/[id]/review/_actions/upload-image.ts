"use server";

import { createClient } from "@/lib/supabase/server";

export type UploadImageState = {
  error: string | null;
  image_path: string | null;
};

function hasSignature(bytes: Uint8Array, type: string): boolean {
  if (type === "image/png") {
    return [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a].every((value, index) => bytes[index] === value);
  }
  if (type === "image/jpeg") {
    return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  }
  if (type === "image/gif") {
    return new TextDecoder().decode(bytes.slice(0, 6)) === "GIF87a" || new TextDecoder().decode(bytes.slice(0, 6)) === "GIF89a";
  }
  if (type === "image/webp") {
    return new TextDecoder().decode(bytes.slice(0, 4)) === "RIFF" && new TextDecoder().decode(bytes.slice(8, 12)) === "WEBP";
  }
  return false;
}

export async function uploadQuestionImage(
  _prev: UploadImageState,
  formData: FormData,
): Promise<UploadImageState> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in.", image_path: null };

  const questionId = formData.get("question_id") as string;
  const projectId = formData.get("project_id") as string;
  const file = formData.get("file") as File | null;

  if (!questionId || !projectId) return { error: "Missing question or project.", image_path: null };
  if (!file || file.size === 0) return { error: "No file selected.", image_path: null };

  const allowedTypes = ["image/png", "image/jpeg", "image/webp", "image/gif"];
  if (!allowedTypes.includes(file.type)) {
    return { error: "Only PNG, JPEG, WebP, and GIF images are allowed.", image_path: null };
  }

  const maxSize = 5 * 1024 * 1024; // 5MB
  if (file.size > maxSize) {
    return { error: "Image must be under 5MB.", image_path: null };
  }

  const { data: existing, error: questionError } = await supabase
    .from("questions")
    .select("project_id, image_path")
    .eq("id", questionId)
    .single();
  if (questionError || !existing) return { error: "Question not found or inaccessible.", image_path: null };
  if (existing.project_id !== projectId) return { error: "Question does not belong to this paper.", image_path: null };

  const bytes = new Uint8Array(await file.arrayBuffer());
  if (!hasSignature(bytes, file.type)) {
    return { error: "The file content does not match its image type.", image_path: null };
  }

  // Use a server-generated bounded filename, never the client filename.
  const extByType: Record<string, string> = {
    "image/png": "png",
    "image/jpeg": "jpg",
    "image/webp": "webp",
    "image/gif": "gif",
  };
  const ext = extByType[file.type];
  const storagePath = `${projectId}/${questionId}/${crypto.randomUUID()}.${ext}`;

  const { error: uploadError } = await supabase.storage
    .from("question-images")
    .upload(storagePath, file, { contentType: file.type, upsert: false });

  if (uploadError) return { error: `Upload failed: ${uploadError.message}`, image_path: null };

  const { data: oldPath, error: updateError } = await supabase.rpc("set_question_image_path", {
    p_question_id: questionId,
    p_project_id: projectId,
    p_image_path: storagePath,
  });

  if (updateError) {
    // Clean up the uploaded file if the DB update fails.
    await supabase.storage.from("question-images").remove([storagePath]);
    return { error: `Failed to save: ${updateError.message}`, image_path: null };
  }

  // The new reference is committed. Removing the old object is now safe; if
  // cleanup fails, it is unreferenced and can be removed by a later job.
  if (oldPath) {
    await supabase.storage.from("question-images").remove([oldPath]);
  }

  return { error: null, image_path: storagePath };
}

export async function removeQuestionImage(
  questionId: string,
): Promise<{ error: string | null }> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in." };

  const { data: existing, error: questionError } = await supabase
    .from("questions")
    .select("project_id, image_path")
    .eq("id", questionId)
    .single();

  if (questionError || !existing) return { error: "Question not found or inaccessible." };
  if (!existing.image_path) return { error: null };

  const { data: oldPath, error } = await supabase.rpc("set_question_image_path", {
    p_question_id: questionId,
    p_project_id: existing.project_id,
    p_image_path: null,
  });
  if (error) return { error: `Failed to remove: ${error.message}` };
  if (oldPath) await supabase.storage.from("question-images").remove([oldPath]);
  return { error: null };
}
