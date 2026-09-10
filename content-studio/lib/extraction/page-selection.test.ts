import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { PageSelectionError, parsePageSelection } from "./page-selection.ts";

describe("page selection", () => {
  it("normalizes pages and ranges", () => {
    assert.deepEqual(parsePageSelection("1,3-5"), [1, 3, 4, 5]);
  });

  it("rejects duplicate pages", () => {
    assert.throws(() => parsePageSelection("1,1"), PageSelectionError);
    assert.throws(() => parsePageSelection("1-3,3"), PageSelectionError);
  });

  it("rejects malformed and reversed ranges", () => {
    assert.throws(() => parsePageSelection("0"), PageSelectionError);
    assert.throws(() => parsePageSelection("4-2"), PageSelectionError);
    assert.throws(() => parsePageSelection("1,,2"), PageSelectionError);
  });

  it("enforces the page selection limit", () => {
    assert.throws(() => parsePageSelection("1-3", 2), PageSelectionError);
  });
});
