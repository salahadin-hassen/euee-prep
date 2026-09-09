"use client";

import { useActionState } from "react";
import { inviteHelper, type InviteState } from "./_actions/invite";

interface InviteFormProps {
  projectId: string;
}

const initialState: InviteState = { error: null, success: false };

export function InviteForm({ projectId }: InviteFormProps) {
  const [state, formAction, pending] = useActionState(inviteHelper, initialState);

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Invite someone to help</h2>
      </div>
      <form className="form" action={formAction}>
        <input type="hidden" name="project_id" value={projectId} />
        <label>
          Their name
          <input
            type="text"
            name="display_name"
            required
            placeholder="Type the name they signed up with"
          />
        </label>
        {state.error && (
          <p className="error" role="alert">{state.error}</p>
        )}
        {state.success && (
          <p style={{ color: "var(--teal)", fontWeight: 700 }}>
            They&apos;ve been invited!
          </p>
        )}
        <button className="button" type="submit" disabled={pending}>
          {pending ? "Inviting..." : "Invite"}
        </button>
      </form>
    </section>
  );
}
