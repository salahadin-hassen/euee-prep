"use server";

import { createClient } from "@/lib/supabase/server";

export type UploadImageState = {
  error: string | null;
  image_path: string | null;
};

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

  // Delete any existing image for this question first.
  const { data: existing } = await supabase
    .from("questions")
    .select("image_path")
    .eq("id", questionId)
    .single();

  if (existing?.image_path) {
    await supabase.storage.from("question-images").remove([existing.image_path]);
  }

  // Build the storage path: {project_id}/{question_id}/{original_filename}
  const ext = file.name.split(".").pop() || "png";
  const storagePath = `${projectId}/${questionId}/${crypto.randomUUID()}.${ext}`;

  const { error: uploadError } = await supabase.storage
    .from("question-images")
    .upload(storagePath, file, { contentType: file.type, upsert: false });

  if (uploadError) return { error: `Upload failed: ${uploadError.message}`, image_path: null };

  // Update the question's image_path.
  const { error: updateError } = await supabase
    .from("questions")
    .update({ image_path: storagePath })
    .eq("id", questionId);

  if (updateError) {
    // Clean up the uploaded file if the DB update fails.
    await supabase.storage.from("question-images").remove([storagePath]);
    return { error: `Failed to save: ${updateError.message}`, image_path: null };
  }

  return { error: null, image_path: storagePath };
}

export async function removeQuestionImage(
  questionId: string,
): Promise<{ error: string | null }> {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { error: "You must be signed in." };

  const { data: existing } = await supabase
    .from("questions")
    .select("image_path")
    .eq("id", questionId)
    .single();

  if (!existing?.image_path) return { error: null };

  await supabase.storage.from("question-images").remove([existing.image_path]);

  const { error } = await supabase
    .from("questions")
    .update({ image_path: null })
    .eq("id", questionId);

  if (error) return { error: `Failed to remove: ${error.message}` };
  return { error: null };
}
