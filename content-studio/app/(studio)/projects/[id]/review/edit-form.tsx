"use client";

import { useState, useRef, useActionState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { editQuestion, type EditState } from "./_actions/edit";
import { uploadQuestionImage, removeQuestionImage, type UploadImageState } from "./_actions/upload-image";

interface Question {
  id: string;
  order_index: number;
  question_text: string;
  choices: string[];
  correct_answer: string;
  explanation: string;
  status: string;
  flag_note: string | null;
  image_path: string | null;
}

interface EditFormProps {
  question: Question;
  imageUrl: string | null;
  projectId: string;
}

const initialEditState: EditState = { error: null, saved: false };
const initialUploadState: UploadImageState = { error: null, image_path: null };

export function EditForm({ question, imageUrl, projectId }: EditFormProps) {
  const router = useRouter();
  const [state, formAction, pending] = useActionState(editQuestion, initialEditState);
  const [uploadState, , uploadPending] = useActionState(uploadQuestionImage, initialUploadState);
  const [isRefreshing, startTransition] = useTransition();
  const [choices, setChoices] = useState<string[]>(question.choices.length > 0 ? question.choices : ["", ""]);
  const [expanded, setExpanded] = useState(false);
  const [savedCount, setSavedCount] = useState(0);
  const [previewUrl, setPreviewUrl] = useState<string | null>(imageUrl);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [removing, setRemoving] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  if (state.saved && savedCount === 0) {
    setSavedCount(1);
    setExpanded(false);
    startTransition(() => { router.refresh(); });
  }

  if (uploadState.image_path && uploadState.image_path !== question.image_path) {
    startTransition(() => { router.refresh(); });
  }

  function addChoice() {
    setChoices([...choices, ""]);
  }

  function updateChoice(index: number, value: string) {
    const next = [...choices];
    next[index] = value;
    setChoices(next);
  }

  function removeChoice(index: number) {
    if (choices.length <= 2) return;
    setChoices(choices.filter((_, i) => i !== index));
  }

  async function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;

    // Show local preview immediately.
    const reader = new FileReader();
    reader.onload = () => setPreviewUrl(reader.result as string);
    reader.readAsDataURL(file);

    // Upload to storage.
    setUploadError(null);
    const formData = new FormData();
    formData.set("question_id", question.id);
    formData.set("project_id", projectId);
    formData.set("file", file);

    const result = await uploadQuestionImage(initialUploadState, formData);
    if (result.error) {
      setUploadError(result.error);
    } else {
      startTransition(() => { router.refresh(); });
    }
  }

  async function handleRemoveImage() {
    setRemoving(true);
    const result = await removeQuestionImage(question.id);
    if (!result.error) {
      setPreviewUrl(null);
      startTransition(() => { router.refresh(); });
    }
    setRemoving(false);
  }

  if (!expanded) {
    return (
      <button className="button" type="button" onClick={() => setExpanded(true)} style={{ background: "var(--muted)" }}>
        Edit this question
      </button>
    );
  }

  return (
    <div style={{ display: "grid", gap: 16 }}>
      {/* Image upload section */}
      <div style={{ border: "1px solid var(--line)", borderRadius: 10, padding: 16 }}>
        <label style={{ fontWeight: 700, fontSize: 13, color: "var(--muted)", textTransform: "uppercase", letterSpacing: ".06em" }}>
          Question image (optional)
        </label>
        {previewUrl && (
          <div style={{ marginTop: 10, position: "relative" }}>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={previewUrl}
              alt="Question diagram"
              style={{ maxWidth: "100%", maxHeight: 300, borderRadius: 8, border: "1px solid var(--line)" }}
            />
            <button
              type="button"
              onClick={handleRemoveImage}
              disabled={removing}
              className="signout"
              style={{ position: "absolute", top: 8, right: 8, color: "#a33d32", fontWeight: 700, fontSize: 13, background: "white", borderRadius: 4, padding: "2px 6px" }}
            >
              {removing ? "Removing..." : "Remove"}
            </button>
          </div>
        )}
        <div style={{ marginTop: 10 }}>
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp,image/gif"
            ref={fileInputRef}
            onChange={handleFileSelect}
            style={{ fontSize: 13 }}
          />
        </div>
        {uploadPending && <p style={{ fontSize: 13, color: "var(--muted)", marginTop: 6 }}>Uploading...</p>}
        {uploadError && <p className="error" role="alert" style={{ marginTop: 8 }}>{uploadError}</p>}
      </div>

      {/* Text fields form */}
      <form className="form" action={formAction} style={{ border: "1px solid var(--line)", borderRadius: 10, padding: 20 }}>
        <input type="hidden" name="question_id" value={question.id} />
        <input type="hidden" name="choices" value={JSON.stringify(choices)} />

        <label>
          Question text
          <textarea name="question_text" rows={3} defaultValue={question.question_text} required />
        </label>

        <div>
          <label style={{ marginBottom: 8, display: "block" }}>Choices</label>
          {choices.map((c, i) => (
            <div key={i} className="choice-row">
              <input
                type="text"
                value={c}
                onChange={(e) => updateChoice(i, e.target.value)}
                placeholder={`Choice ${i + 1}`}
              />
              {choices.length > 2 && (
                <button type="button" onClick={() => removeChoice(i)} className="signout" style={{ fontSize: 14 }}>
                  Remove
                </button>
              )}
            </div>
          ))}
          <button type="button" onClick={addChoice} className="signout" style={{ fontSize: 13, marginTop: 4 }}>
            + Add choice
          </button>
        </div>

        <label>
          Answer draft (optional)
          <input type="text" name="correct_answer" defaultValue={question.correct_answer} />
        </label>

        <label>
          Explanation draft
          <textarea name="explanation" rows={3} defaultValue={question.explanation} />
        </label>

        {state.error && <p className="error" role="alert">{state.error}</p>}

        <div className="btn-stack">
          <button className="button" type="submit" disabled={pending || isRefreshing}>
            {pending ? "Saving..." : "Save edits"}
          </button>
          <button className="button" type="button" onClick={() => setExpanded(false)} style={{ background: "var(--muted)" }}>
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}
