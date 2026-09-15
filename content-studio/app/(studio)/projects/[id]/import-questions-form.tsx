"use client";

import { useRef, useState } from "react";
import { useActionState, useTransition } from "react";
import { useRouter } from "next/navigation";
import { importQuestions, type ImportState } from "./_actions/import-questions";

const initialState: ImportState = { error: null, success: false, count: 0 };

export function ImportQuestionsForm({ projectId }: { projectId: string }) {
  const [state, formAction, pending] = useActionState(importQuestions, initialState);
  const [, startTransition] = useTransition();
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [fileName, setFileName] = useState<string | null>(null);
  const [questionCount, setQuestionCount] = useState<number | null>(null);

  if (state.success && state.count > 0) {
    startTransition(() => { router.refresh(); });
  }

  async function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0] ?? null;
    setFileName(file?.name ?? null);
    setQuestionCount(null);

    if (file && file.name.endsWith(".json")) {
      try {
        const text = await file.text();
        const parsed = JSON.parse(text);
        const count = countQuestions(parsed);
        setQuestionCount(count);
      } catch {
        setQuestionCount(null);
      }
    }
  }

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Import questions</h2>
      </div>
      <p className="project-meta" style={{ marginBottom: 14 }}>
        Paste your JSON from Gemini/DeepSeek, then upload it here. Every imported
        question starts as <strong>unverified</strong> so a human can review it
        against the source PDF.
      </p>
      <form className="form" action={formAction}>
        <input type="hidden" name="project_id" value={projectId} />
        <label>
          JSON file
          <input
            type="file"
            name="file"
            accept=".json,application/json"
            required
            ref={fileRef}
            onChange={handleFileChange}
          />
        </label>
        {fileName && (
          <p className="project-meta">
            {fileName}
            {questionCount !== null && (
              <> &middot; {questionCount} question{questionCount !== 1 ? "s" : ""} found</>
            )}
          </p>
        )}
        {state.error && <p className="error" role="alert">{state.error}</p>}
        {state.success && state.count > 0 && (
          <p className="success" role="status">
            Imported {state.count} question{state.count !== 1 ? "s" : ""}.
          </p>
        )}
        <button className="button" type="submit" disabled={pending}>
          {pending ? "Importing..." : "Import questions"}
        </button>
      </form>
    </section>
  );
}

function countQuestions(payload: unknown): number {
  if (Array.isArray(payload)) return payload.length;

  if (payload && typeof payload === "object" && "chapters" in payload) {
    const pack = payload as { chapters?: Array<{ topics?: Array<{ questions?: unknown[] }> }> };
    let count = 0;
    for (const chapter of pack.chapters ?? []) {
      for (const topic of chapter.topics ?? []) {
        count += (topic.questions ?? []).length;
      }
    }
    return count;
  }

  return 0;
}
