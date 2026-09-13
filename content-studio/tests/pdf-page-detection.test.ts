import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync, existsSync } from "node:fs";
import { resolve } from "node:path";

const root = resolve(process.cwd(), "..");
const read = (path: string) => readFileSync(resolve(root, path), "utf8");

describe("PDF page detection", () => {
  const source = read("content-studio/app/(studio)/projects/[id]/inline-extraction.tsx");

  it("serves worker from /pdf.worker.min.mjs (public dir)", () => {
    assert.match(source, /workerSrc = "\/pdf\.worker\.min\.mjs"/);
  });

  it("public/pdf.worker.min.mjs exists and matches pdfjs-dist version", () => {
    const workerPath = resolve(process.cwd(), "public/pdf.worker.min.mjs");
    assert.ok(existsSync(workerPath), "public/pdf.worker.min.mjs must exist");
    const pkg = JSON.parse(readFileSync(resolve(process.cwd(), "package.json"), "utf8"));
    const expectedVersion = pkg.dependencies["pdfjs-dist"];
    assert.ok(expectedVersion, "pdfjs-dist version must be in package.json");
  });

  it("does not set workerSrc to empty string", () => {
    assert.doesNotMatch(source, /workerSrc = ""/);
  });

  it("does not use CDN fallback", () => {
    assert.doesNotMatch(source, /unpkg\.com/);
  });

  it("passes Uint8Array data to getDocument", () => {
    assert.match(source, /new Uint8Array\(await file\.arrayBuffer\(\)\)/);
  });

  it("sets detecting state before detection", () => {
    assert.match(source, /setDetectionState\("detecting"\)/);
  });

  it("sets success state with count on success", () => {
    assert.match(source, /setDetectedPages\(count\)/);
    assert.match(source, /setDetectionState\("success"\)/);
  });

  it("sets error state on failure", () => {
    assert.match(source, /setDetectionState\("error"\)/);
  });

  it("logs the actual error for debugging", () => {
    assert.match(source, /console\.error\("\[InlineExtraction\]/);
  });

  it("does not silently return null from detection", () => {
    assert.doesNotMatch(source, /catch \{\s*return null\s*\}/);
  });

  it("disables Extract button while not in success state", () => {
    assert.match(source, /detectionState !== "success"/);
  });

  it("shows loading indicator during detection", () => {
    assert.match(source, /Checking PDF pages/);
  });

  it("shows error UI with retry on detection failure", () => {
    assert.match(source, /Couldn.*read this PDF/);
    assert.match(source, /Try again/);
  });

  it("uses detection token to reject stale async results", () => {
    assert.match(source, /detectionTokenRef/);
    assert.match(source, /token !== detectionTokenRef\.current/);
  });

  it("generates full page range from detected count", () => {
    assert.match(source, /Array\.from\(\{ length: detectedPages \}/);
  });

  it("does not hard-code page 1", () => {
    assert.doesNotMatch(source, /requested_pages.*=.*\[1\]/);
  });

  it("requires detection success before submit", () => {
    assert.match(source, /detectionState !== "success" \|\| !detectedPages/);
  });

  it("has separate detectionError state", () => {
    assert.match(source, /detectionError/);
  });
});
