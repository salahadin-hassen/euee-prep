"use client";

import { useState, useActionState } from "react";
import { useRouter } from "next/navigation";
import { flagQuestion, type FlagState } from "./_actions/flag";

interface FlagFormProps {
  questionId: string;
  projectId: string;
}

const initialFlagState: FlagState = { error: null, done: false };

export function FlagForm({ questionId, projectId }: FlagFormProps) {
  const router = useRouter();
  const [state, formAction, pending] = useActionState(flagQuestion, initialFlagState);
  const [doneCount, setDoneCount] = useState(0);

  if (state.done && doneCount === 0) {
    setDoneCount(1);
    router.refresh();
  }

  return (
    <form className="form" action={formAction} style={{ border: "1px solid var(--line)", borderRadius: 10, padding: 16, marginTop: 12 }}>
      <input type="hidden" name="question_id" value={questionId} />
      <input type="hidden" name="project_id" value={projectId} />
      <label>
        What looks off? (optional)
        <input type="text" name="flag_note" placeholder="e.g. wrong answer, unclear wording" />
      </label>
      {state.error && <p className="error" role="alert">{state.error}</p>}
      <button className="button" type="submit" disabled={pending} style={{ background: "var(--amber)" }}>
        {pending ? "Flagging..." : "Flag & skip"}
      </button>
    </form>
  );
}
