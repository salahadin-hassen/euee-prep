"use client";

import { useActionState } from "react";
import { assignMember, type AssignMemberState } from "../../_actions/member";

interface AssignableUser {
  id: string;
  display_name: string | null;
  role: string;
}

interface AssignFormProps {
  projectId: string;
  assignableUsers: AssignableUser[];
}

const initialState: AssignMemberState = { error: null, success: false };

export function AssignForm({ projectId, assignableUsers }: AssignFormProps) {
  const [state, formAction, pending] = useActionState(assignMember, initialState);

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Assign member</h2>
        <span className="badge">Admin only</span>
      </div>
      <form className="form" action={formAction}>
        <input type="hidden" name="project_id" value={projectId} />
        <label>
          User
          <select name="user_id" required defaultValue="">
            <option value="" disabled>
              Select a user
            </option>
            {assignableUsers.map((u) => (
              <option key={u.id} value={u.id}>
                {u.display_name || "Unnamed"} ({u.role})
              </option>
            ))}
          </select>
        </label>
        <label>
          Role
          <select name="role" required defaultValue="">
            <option value="" disabled>
              Select role
            </option>
            <option value="reviewer">Reviewer</option>
            <option value="uploader">Uploader</option>
          </select>
        </label>
        {state.error && (
          <p className="error" role="alert">
            {state.error}
          </p>
        )}
        {state.success && (
          <p style={{ color: "var(--teal)", fontWeight: 700 }}>
            Member assigned successfully.
          </p>
        )}
        <button className="button" type="submit" disabled={pending}>
          {pending ? "Assigning..." : "Assign"}
        </button>
      </form>
    </section>
  );
}
