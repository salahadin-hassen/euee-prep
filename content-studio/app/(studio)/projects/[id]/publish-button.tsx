"use client";

import { useState } from "react";
import { publishContentPack } from "./_actions/publish";

export function PublishButton({ projectId }: { projectId: string }) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [published, setPublished] = useState<string | null>(null);

  async function handlePublish() {
    setPending(true);
    setError(null);
    setPublished(null);

    const formData = new FormData();
    formData.set("project_id", projectId);

    try {
      const result = await publishContentPack(formData);
      if (result.error) {
        setError(result.error);
        return;
      }
      setPublished(`${result.packId} v${result.packVersion} published`);
    } catch {
      setError("Publish failed. Please try again.");
    } finally {
      setPending(false);
    }
  }

  return (
    <div>
      <button
        className="button button--export"
        type="button"
        onClick={handlePublish}
        disabled={pending}
      >
        {pending ? "Publishing..." : "Publish to app"}
      </button>
      {error && <p className="error" role="alert" style={{ marginTop: 8 }}>{error}</p>}
      {published && (
        <p className="success" role="status" style={{ marginTop: 8 }}>{published}</p>
      )}
    </div>
  );
}
