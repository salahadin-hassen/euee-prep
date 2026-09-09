"use client";

import { useActionState } from "react";
import Link from "next/link";
import { createProject, type CreateProjectState } from "../../_actions/project";

const initialState: CreateProjectState = { error: null };

export default function NewProjectPage() {
  const [state, formAction, pending] = useActionState(createProject, initialState);

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Create project</p>
          <h1>New project</h1>
          <p className="lede">
            Create a new authoring project. You will be added as an admin member automatically.
          </p>
        </div>
        <Link className="button" href="/admin">
          Back to dashboard
        </Link>
      </section>

      <section className="panel">
        <form className="form" action={formAction}>
          <label>
            Project title
            <input
              type="text"
              name="title"
              required
              placeholder="e.g. EC 2025 Mathematics"
            />
          </label>

          <label>
            Subject
            <input
              type="text"
              name="subject"
              required
              placeholder="e.g. Mathematics"
            />
          </label>

          <label>
            Exam year
            <input
              type="number"
              name="exam_year"
              required
              min={1}
              placeholder="e.g. 2025"
            />
          </label>

          <label>
            Stream
            <select name="stream" required defaultValue="">
              <option value="" disabled>
                Select stream
              </option>
              <option value="natural_science">Natural Science</option>
              <option value="social_science">Social Science</option>
            </select>
          </label>

          {state.error && (
            <p className="error" role="alert">
              {state.error}
            </p>
          )}

          <button className="button" type="submit" disabled={pending}>
            {pending ? "Creating..." : "Create project"}
          </button>
        </form>
      </section>
    </main>
  );
}
