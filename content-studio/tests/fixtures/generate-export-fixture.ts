/**
 * Regenerates `exported-content-pack-v3.json` from `export-sample.ts`.
 *
 * Run from the content-studio directory:
 *   node --experimental-strip-types tests/fixtures/generate-export-fixture.ts
 *
 * The generated file is the cross-system contract fixture: the same bytes are
 * asserted by the TypeScript export tests, the Python pipeline validator, and
 * the Flutter importer.
 */

import { writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { buildContentPack } from "../../lib/export-pack.ts";
import {
  SAMPLE_GENERATED_AT,
  sampleProject,
  sampleQuestions,
} from "./export-sample.ts";

const here = dirname(fileURLToPath(import.meta.url));
const pack = buildContentPack(sampleProject, sampleQuestions, SAMPLE_GENERATED_AT);
const target = resolve(here, "exported-content-pack-v3.json");

writeFileSync(target, `${JSON.stringify(pack, null, 2)}\n`, "utf8");
console.log(`wrote ${target}`);
console.log(`checksum ${String(pack.checksum)}`);
