"use client";

import { useActionState } from "react";
import { createProject, type CreateProjectState } from "../../_actions/project";

const initialState: CreateProjectState = { error: null };

export function NewProjectForm() {
  const [state, formAction, pending] = useActionState(createProject, initialState);
  return (
    <form className="form" action={formAction}>
      <label>Project title<input type="text" name="title" required placeholder="e.g. EC 2025 Mathematics" /></label>
      <label>Subject<input type="text" name="subject" required placeholder="e.g. Mathematics" /></label>
      <label>Exam year<input type="number" name="exam_year" required min={1} placeholder="e.g. 2025" /></label>
      <label>Stream<select name="stream" required defaultValue=""><option value="" disabled>Select stream</option><option value="natural_science">Natural Science</option><option value="social_science">Social Science</option></select></label>
      {state.error && <p className="error" role="alert">{state.error}</p>}
      <button className="button" type="submit" disabled={pending}>{pending ? "Creating..." : "Create project"}</button>
    </form>
  );
}
