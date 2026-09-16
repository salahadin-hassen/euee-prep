"use client";

import { useActionState, useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { revokeAssignment, type RevokeState } from "./_actions/revoke";

const initialState: RevokeState = { error: null, success: false };

export function RevokeButton({ assignmentId }: { assignmentId: string }) {
  const [state, formAction, pending] = useActionState(revokeAssignment, initialState);
  const router = useRouter();
  const [confirming, setConfirming] = useState(false);
  const dialogRef = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    if (state.success) {
      setConfirming(false);
      router.refresh();
    }
  }, [router, state.success]);

  useEffect(() => {
    if (confirming) dialogRef.current?.showModal();
    else dialogRef.current?.close();
  }, [confirming]);

  return (
    <>
      <button
        className="button button--revoke"
        type="button"
        onClick={() => setConfirming(true)}
      >
        Revoke
      </button>

      <dialog ref={dialogRef} onClose={() => setConfirming(false)}>
        <form method="dialog" style={{ padding: 24 }}>
          <p>Remove this assignment? The reviewer will lose access to these questions.</p>
          {state.error && <p className="error" role="alert">{state.error}</p>}
          <div style={{ display: "flex", gap: 8, marginTop: 16 }}>
            <button className="button" type="submit">
              Cancel
            </button>
          </div>
        </form>
        <form action={formAction} style={{ padding: "0 24px 24px" }}>
          <input type="hidden" name="assignment_id" value={assignmentId} />
          <button className="signout" type="submit" disabled={pending}>
            {pending ? "Revoking..." : "Revoke assignment"}
          </button>
        </form>
      </dialog>
    </>
  );
}
