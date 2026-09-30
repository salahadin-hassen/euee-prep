import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  computeChecksum,
  canonicalJson,
} from "../lib/checksum.ts";

describe("FNV-1a 64-bit checksum", () => {
  it("produces deterministic output", () => {
    const pack = {
      schema_version: "3",
      pack_id: "test-pack",
      stream: "natural_science",
    };
    const a = computeChecksum(pack);
    const b = computeChecksum(pack);
    assert.equal(a, b);
    assert.ok(a.startsWith("fnv1a64:"));
    assert.equal(a.length, 24); // "fnv1a64:" (8) + 16 hex chars
  });

  it("excludes checksum field from canonical form", () => {
    const without = { schema_version: "3", stream: "natural_science" };
    const withChecksum = { ...without, checksum: "fnv1a64:0000000000000000" };
    assert.equal(computeChecksum(without), computeChecksum(withChecksum));
  });

  it("sorts keys alphabetically at all nesting levels", () => {
    const a = { z: { b: 1, a: 2 }, m: "hello" };
    const b = { m: "hello", z: { a: 2, b: 1 } };
    assert.equal(canonicalJson(a), canonicalJson(b));
  });

  it("canonical JSON uses 2-space indentation", () => {
    const pack = { a: 1, b: { c: 2 } };
    const canonical = canonicalJson(pack);
    assert.ok(canonical.includes('  "b":'));
    assert.ok(!canonical.includes("\t"));
  });

  it("handles arrays deterministically", () => {
    const pack = { items: ["c", "a", "b"] };
    const canonical = canonicalJson(pack);
    assert.ok(canonical.includes('"c"'));
    assert.ok(canonical.includes('"a"'));
    assert.ok(canonical.includes('"b"'));
  });

  it("computes same checksum as Dart for cross-language fixture", () => {
    const fixturePath = resolve(
      process.cwd(),
      "tests/fixtures/cross-language-pack.json",
    );
    const raw = readFileSync(fixturePath, "utf8");
    const pack = JSON.parse(raw);
    const expectedChecksum = pack.checksum;
    const computed = computeChecksum(pack);
    assert.equal(
      computed,
      expectedChecksum,
      `Checksum mismatch: TS computed ${computed}, fixture has ${expectedChecksum}`,
    );
  });
});

describe("cross-language fixture", () => {
  it("fixture exists and is valid JSON", () => {
    const fixturePath = resolve(
      process.cwd(),
      "tests/fixtures/cross-language-pack.json",
    );
    const raw = readFileSync(fixturePath, "utf8");
    const pack = JSON.parse(raw);
    assert.equal(pack.schema_version, "3");
    assert.equal(pack.pack_id, "biology-2018-natural-science");
    assert.equal(pack.stream, "natural_science");
    assert.equal(pack.questions.length, 2);
    assert.ok(pack.checksum.startsWith("fnv1a64:"));
  });
});
