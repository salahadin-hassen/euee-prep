"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { inviteHelper, type InviteState } from "./_actions/invite";

interface ReviewerOption {
  id: string;
  display_name: string | null;
}

interface InviteFormProps {
  projectId: string;
  reviewers: ReviewerOption[];
}

const initialState: InviteState = { error: null, success: false };

export function InviteForm({ projectId, reviewers }: InviteFormProps) {
  const [state, formAction, pending] = useActionState(inviteHelper, initialState);
  const router = useRouter();

  useEffect(() => {
    if (state.success) router.refresh();
  }, [router, state.success]);

  return (
    <section className="panel">
      <div className="panel-head">
          <h2>Assign reviewer</h2>
      </div>
      <form className="form" action={formAction}>
        <input type="hidden" name="project_id" value={projectId} />
          <label>
            Reviewer
            <select name="display_name" required defaultValue="">
              <option value="" disabled>
                {reviewers.length === 0 ? "No reviewers found" : "Choose a reviewer"}
              </option>
              {reviewers.map((r) => (
                <option key={r.id} value={r.display_name ?? ""}>
                  {r.display_name ?? "Unnamed"}
                </option>
              ))}
            </select>
          </label>
        <div className="choice-row">
          <label>
            From question
            <input type="number" name="start_question" min="1" placeholder="Whole paper" />
          </label>
          <label>
            Through question
            <input type="number" name="end_question" min="1" placeholder="Whole paper" />
          </label>
        </div>
        {state.error && (
          <p className="error" role="alert">{state.error}</p>
        )}
        {state.success && (
          <p style={{ color: "var(--teal)", fontWeight: 700 }}>
            Reviewer assigned.
          </p>
        )}
        <button className="button" type="submit" disabled={pending || reviewers.length === 0}>
          {pending ? "Assigning..." : "Assign reviewer"}
        </button>
      </form>
    </section>
  );
}
