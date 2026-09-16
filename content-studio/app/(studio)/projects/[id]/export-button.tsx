"use client";

import { useState } from "react";
import { exportContentPack } from "./_actions/export";

export function ExportButton({ projectId }: { projectId: string }) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleExport() {
    setPending(true);
    setError(null);

    const formData = new FormData();
    formData.set("project_id", projectId);

    try {
      const result = await exportContentPack(formData);
      if (result.error) {
        setError(result.error);
        setPending(false);
        return;
      }

      const url = URL.createObjectURL(result.blob!);
      const a = document.createElement("a");
      a.href = url;
      a.download = result.filename!;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch {
      setError("Export failed. Please try again.");
    } finally {
      setPending(false);
    }
  }

  return (
    <div>
      <button
        className="button button--export"
        type="button"
        onClick={handleExport}
        disabled={pending}
      >
        {pending ? "Exporting..." : "Export content pack"}
      </button>
      {error && <p className="error" role="alert" style={{ marginTop: 8 }}>{error}</p>}
    </div>
  );
}
