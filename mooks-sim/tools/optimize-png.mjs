#!/usr/bin/env node
// Re-compresses the PNGs emitted by mooks-render.
//
// The Swift renderer has no zlib available (swift-corelibs-foundation exposes no
// compression API, and the build environment has no network to add a dependency), so
// it writes valid PNGs using DEFLATE "stored" blocks — correct, but uncompressed.
// Fine for a local design loop, wasteful for a repository.
//
// This does not touch pixels. It inflates the existing IDAT and re-deflates it at
// maximum level, then fixes the CRC. Byte-for-byte identical image, ~30x smaller.
//
//   node tools/optimize-png.mjs out

import { readFileSync, writeFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { inflateSync, deflateSync } from "node:zlib";

const crcTable = Array.from({ length: 256 }, (_, i) => {
  let c = i;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});

function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, payload) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(payload.length);
  const body = Buffer.concat([Buffer.from(type, "ascii"), payload]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
}

/** Walks the chunk list, concatenating IDAT payloads. */
function optimize(buf) {
  const sig = buf.subarray(0, 8);
  if (sig.toString("hex") !== "89504e470d0a1a0a") throw new Error("not a PNG");

  const out = [sig];
  const idatParts = [];
  let offset = 8;

  while (offset < buf.length) {
    const len = buf.readUInt32BE(offset);
    const type = buf.toString("ascii", offset + 4, offset + 8);
    const payload = buf.subarray(offset + 8, offset + 8 + len);

    if (type === "IDAT") {
      idatParts.push(payload);
    } else if (type === "IEND") {
      // Emit the single recompressed IDAT immediately before IEND.
      const raw = inflateSync(Buffer.concat(idatParts));
      out.push(chunk("IDAT", deflateSync(raw, { level: 9 })));
      out.push(chunk("IEND", Buffer.alloc(0)));
    } else {
      out.push(chunk(type, payload));
    }
    offset += 12 + len;
  }
  return Buffer.concat(out);
}

function walk(dir) {
  const files = [];
  for (const entry of readdirSync(dir)) {
    const p = join(dir, entry);
    if (statSync(p).isDirectory()) files.push(...walk(p));
    else if (entry.endsWith(".png")) files.push(p);
  }
  return files;
}

const target = process.argv[2] ?? "out";
const files = walk(target);
let before = 0;
let after = 0;

for (const file of files) {
  const original = readFileSync(file);
  const optimized = optimize(original);
  // Never grow a file.
  const chosen = optimized.length < original.length ? optimized : original;
  writeFileSync(file, chosen);
  before += original.length;
  after += chosen.length;
}

const pct = before === 0 ? 0 : (1 - after / before) * 100;
console.log(
  `optimized ${files.length} PNG(s): ${(before / 1024 / 1024).toFixed(2)} MB -> ` +
  `${(after / 1024 / 1024).toFixed(2)} MB (${pct.toFixed(1)}% smaller)`
);
