"use client";

import { useActionState, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { inviteHelper, type InviteState } from "./_actions/invite";

interface ReviewerOption {
  id: string;
  display_name: string | null;
}

interface InviteFormProps {
  projectId: string;
  reviewers: ReviewerOption[];
  totalQuestions: number;
}

const initialState: InviteState = { error: null, success: false };

export function InviteForm({ projectId, reviewers, totalQuestions }: InviteFormProps) {
  const [state, formAction, pending] = useActionState(inviteHelper, initialState);
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [scope, setScope] = useState<"whole" | "range">("whole");
  const [startQ, setStartQ] = useState("");
  const [endQ, setEndQ] = useState("");

  useEffect(() => {
    if (state.success) {
      router.refresh();
      setOpen(false);
      setScope("whole");
      setStartQ("");
      setEndQ("");
    }
  }, [router, state.success]);

  const startNum = startQ ? parseInt(startQ, 10) : null;
  const endNum = endQ ? parseInt(endQ, 10) : null;
  const rangeCount = scope === "range" && startNum !== null && endNum !== null && endNum >= startNum
    ? endNum - startNum + 1
    : null;

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Review assignments</h2>
      </div>

      {!open && (
        <button
          className="button button--assign"
          type="button"
          onClick={() => setOpen(true)}
          disabled={reviewers.length === 0}
        >
          + Assign reviewer
        </button>
      )}

      {open && (
        <form className="form invite-form" action={formAction}>
          <input type="hidden" name="project_id" value={projectId} />

          <label>
            Reviewer
            <select name="display_name" required defaultValue="">
              <option value="" disabled>
                {reviewers.length === 0 ? "No reviewers found" : "Select a friend"}
              </option>
              {reviewers.map((r) => (
                <option key={r.id} value={r.display_name ?? ""}>
                  {r.display_name ?? "Unnamed"}
                </option>
              ))}
            </select>
          </label>

          <fieldset className="scope-fieldset">
            <legend>Scope</legend>
            <label className="radio-label">
              <input
                type="radio"
                name="scope"
                value="whole"
                checked={scope === "whole"}
                onChange={() => setScope("whole")}
              />
              Entire paper
              {totalQuestions > 0 && (
                <span className="radio-hint">({totalQuestions} questions)</span>
              )}
            </label>
            <label className="radio-label">
              <input
                type="radio"
                name="scope"
                value="range"
                checked={scope === "range"}
                onChange={() => setScope("range")}
              />
              Question range
            </label>
          </fieldset>

          {scope === "range" && (
            <div className="range-inputs">
              <label>
                From
                <input
                  type="number"
                  name="start_question"
                  min="1"
                  max={totalQuestions || undefined}
                  placeholder="1"
                  value={startQ}
                  onChange={(e) => setStartQ(e.target.value)}
                />
              </label>
              <label>
                To
                <input
                  type="number"
                  name="end_question"
                  min="1"
                  max={totalQuestions || undefined}
                  placeholder={totalQuestions > 0 ? String(totalQuestions) : "End"}
                  value={endQ}
                  onChange={(e) => setEndQ(e.target.value)}
                />
              </label>
              {rangeCount !== null && (
                <div className="range-preview">
                  {rangeCount} question{rangeCount !== 1 ? "s" : ""}
                </div>
              )}
            </div>
          )}

          {state.error && (
            <p className="error" role="alert">{state.error}</p>
          )}
          {state.success && (
            <p className="success" role="status">
              Reviewer assigned.
            </p>
          )}

          <div className="invite-form-actions">
            <button
              className="button"
              type="submit"
              disabled={pending || reviewers.length === 0}
            >
              {pending ? "Assigning..." : "Assign"}
            </button>
            <button
              className="button button--cancel"
              type="button"
              onClick={() => {
                setOpen(false);
                setScope("whole");
                setStartQ("");
                setEndQ("");
              }}
            >
              Cancel
            </button>
          </div>
        </form>
      )}
    </section>
  );
}
