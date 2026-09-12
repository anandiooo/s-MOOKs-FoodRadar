#!/usr/bin/env node
// Asserts that the JavaScript wrap() reproduces the Swift reference implementation.
//
// Regenerate the golden file whenever Theme.wrap() changes:
//   cd ../mooks-sim && swift run mooks-render --emit-vectors > ../mooks-content/test/wrap-vectors.json
//
//   node test/wrap.test.mjs

import { readFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { wrap, wrapAll } from "../scripts/lib/wrap.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const vectors = JSON.parse(readFileSync(join(here, "wrap-vectors.json"), "utf8"));

let failed = 0;
let passed = 0;

const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);

for (const v of vectors) {
  const gotClipped = wrap(v.text, v.charsPerLine, v.maxLines);
  const gotAll = wrapAll(v.text, v.charsPerLine);

  const label = `wrap(${JSON.stringify(v.text)}, ${v.charsPerLine}, ${v.maxLines})`;

  if (!eq(gotClipped, v.lines)) {
    failed++;
    console.log(`  FAIL  ${label}\n          swift: ${JSON.stringify(v.lines)}\n          js:    ${JSON.stringify(gotClipped)}`);
  } else if (!eq(gotAll, v.allLines)) {
    failed++;
    console.log(`  FAIL  ${label} [unclipped]\n          swift: ${JSON.stringify(v.allLines)}\n          js:    ${JSON.stringify(gotAll)}`);
  } else {
    passed++;
    console.log(`  ok    ${label} -> ${JSON.stringify(gotClipped)}`);
  }
}

console.log(`\n  ${passed} passed, ${failed} failed (${vectors.length} vectors)\n`);
if (failed > 0) {
  console.log("  The simulator and the content pipeline disagree about what fits on the");
  console.log("  panel. Fix before publishing — this is exactly the divergence that ships");
  console.log("  clipped text to hardware.\n");
  process.exit(1);
}
