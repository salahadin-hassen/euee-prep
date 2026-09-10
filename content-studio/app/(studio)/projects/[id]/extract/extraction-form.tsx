"use client";

import { useCallback, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { PageSelectionError, parsePageSelection } from "@/lib/extraction/page-selection";
import {
  MAX_SOURCE_PDF_BYTES,
  prepareSourceDocumentUpload,
  registerSourceDocument,
} from "./_actions/source-document";
import { createExtractionJob } from "./_actions/job";

function formatBytes(bytes: number): string {
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

async function sha256(file: File): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", await file.arrayBuffer());
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function hasPdfSignature(file: File): Promise<boolean> {
  const bytes = new Uint8Array(await file.slice(0, 5).arrayBuffer());
  return new TextDecoder().decode(bytes) === "%PDF-";
}

async function detectPdfPageCount(file: File): Promise<number | null> {
  try {
    const pdfjsLib = await import("pdfjs-dist");
    pdfjsLib.GlobalWorkerOptions.workerSrc = "";
    const buffer = await file.arrayBuffer();
    const doc = await pdfjsLib.getDocument({ data: buffer, useSystemFonts: true }).promise;
    const count = doc.numPages;
    doc.destroy();
    return count;
  } catch {
    return null;
  }
}

export function ExtractionForm({ projectId }: { projectId: string }) {
  const router = useRouter();
  const [file, setFile] = useState<File | null>(null);
  const [pageInput, setPageInput] = useState("1");
  const [detectedPages, setDetectedPages] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const onFileChange = useCallback(async (event: React.ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0] ?? null;
    setFile(selected);
    setDetectedPages(null);
    if (selected && selected.type === "application/pdf") {
      const count = await detectPdfPageCount(selected);
      if (count && count > 0) {
        setDetectedPages(count);
        setPageInput(`1-${count}`);
      }
    }
  }, []);

  async function submit() {
    setError(null);
    if (!file) {
      setError("Choose a PDF first.");
      return;
    }

    let pages: number[];
    try {
      pages = parsePageSelection(pageInput);
    } catch (selectionError) {
      setError(selectionError instanceof PageSelectionError ? selectionError.message : "Invalid page selection.");
      return;
    }
    if (file.type !== "application/pdf" || !file.name.toLowerCase().endsWith(".pdf")) {
      setError("Only PDF files are allowed.");
      return;
    }
    if (file.size <= 0 || file.size > MAX_SOURCE_PDF_BYTES) {
      setError("PDF files must be smaller than 50 MB.");
      return;
    }
    if (!(await hasPdfSignature(file))) {
      setError("The file does not have a valid PDF signature.");
      return;
    }

    setPending(true);
    try {
      const prepared = await prepareSourceDocumentUpload(projectId, file.name, file.type, file.size);
      if (prepared.error || !prepared.documentId || !prepared.storagePath || !prepared.token) {
        setError(prepared.error ?? "Could not prepare the upload.");
        return;
      }

      const supabase = createClient();
      const { error: uploadError } = await supabase.storage
        .from("source-pdfs")
        .uploadToSignedUrl(prepared.storagePath, prepared.token, file);
      if (uploadError) {
        setError(`Upload failed: ${uploadError.message}`);
        return;
      }

      const registered = await registerSourceDocument({
        projectId,
        documentId: prepared.documentId,
        storagePath: prepared.storagePath,
        originalFilename: file.name,
        mimeType: file.type,
        byteSize: file.size,
        sha256: await sha256(file),
      });
      if (registered.error || !registered.documentId) {
        setError(registered.error ?? "Could not register the uploaded PDF.");
        return;
      }

      const job = await createExtractionJob(projectId, registered.documentId, pages);
      if (!job.ok) {
        setError(job.error);
        return;
      }

      if (job.dispatchWarning) {
        setError(job.dispatchWarning);
      }

      setFile(null);
      setPageInput("1");
      setDetectedPages(null);
      router.refresh();
    } finally {
      setPending(false);
    }
  }

  return (
    <section className="panel">
      <div className="panel-head">
        <h2>Prepare extraction</h2>
      </div>
      <p className="empty" style={{ marginBottom: 16 }}>
        Upload a PDF and all pages will be queued automatically. The extraction worker processes jobs within minutes.
      </p>
      <div className="form">
        <label>
          Source PDF
          <input
            type="file"
            accept="application/pdf,.pdf"
            onChange={onFileChange}
            disabled={pending}
          />
        </label>
        {file && <p className="project-meta">{file.name} · {formatBytes(file.size)}{detectedPages ? ` · ${detectedPages} pages detected` : ""}</p>}
        <label>
          Pages
          <input
            type="text"
            value={pageInput}
            onChange={(event) => setPageInput(event.target.value)}
            placeholder="e.g. 1,3,4-6"
            disabled={pending}
          />
        </label>
        <p className="project-meta">All pages are selected by default. Adjust if you only need specific pages.</p>
        {error && <p className="error" role="alert">{error}</p>}
        <button className="button" type="button" onClick={submit} disabled={pending}>
          {pending ? "Uploading..." : "Upload and extract"}
        </button>
      </div>
    </section>
  );
}
