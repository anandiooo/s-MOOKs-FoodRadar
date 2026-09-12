#!/usr/bin/env node
// Builds the static payload the device fetches.
//
//   node scripts/build.mjs
//
// Output (dist/) is what you upload to Cloudflare Pages / GitHub Pages. There is no
// server, no database and no runtime. The device does one conditional GET against a
// CDN and gets a 304 on the common path (review §10.1).
//
// THE IMPORTANT PART: this step pre-wraps every string into display lines. The
// firmware receives lines, not sentences, and renders them at fixed coordinates.
// The server does the editing; the device does the rendering.

import { readFileSync, readdirSync, mkdirSync, writeFileSync } from "node:fs";
import { join, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";
import { wrap } from "./lib/wrap.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const contract = JSON.parse(readFileSync(join(root, "contract.json"), "utf8"));
const contentDir = join(root, "content");
const distDir = join(root, "dist", "v1");
const dropsDir = join(distDir, "drops");

mkdirSync(dropsDir, { recursive: true });

const KIND_LABEL = { dish: "DISH", drink: "DRINK", place: "PLACE", oddity: "ODDITY" };
const L = contract.limits;

/** Accent string + glyph direction, decided here so the device just draws it. */
function accentFor(trend) {
  if (typeof trend.percent === "number") {
    return { text: `${Math.abs(trend.percent)}%`, glyph: trend.percent >= 0 ? "up" : "down" };
  }
  switch (trend.word) {
    case "rising":  return { text: "RISING",  glyph: "up" };
    case "peaking": return { text: "PEAKING", glyph: "up" };
    case "steady":  return { text: "STEADY",  glyph: "flat" };
    default:        return { text: "",        glyph: "flat" };
  }
}

function buildItem(item) {
  const accent = accentFor(item.trend);
  const out = {
    id: item.id,
    kind: item.kind,
    kindLabel: KIND_LABEL[item.kind],
    accent: accent.text,
    glyph: accent.glyph,
    titleLines: wrap(item.title, L.title.charsPerLine, L.title.maxLines),
    hookLines: wrap(item.hook, L.hook.charsPerLine, L.hook.maxLines),
    whyLines: wrap(item.why, L.why.charsPerLine, L.why.maxLines),
    tags: item.tags,
  };
  if (item.place) out.place = item.place;
  if (item.link) out.link = item.link;
  return out;
}

const files = readdirSync(contentDir).filter((f) => f.endsWith(".json")).sort();
const built = [];

for (const file of files) {
  const src = JSON.parse(readFileSync(join(contentDir, file), "utf8"));
  const payload = {
    schema: contract.schema,
    dropId: src.dropId,
    city: src.city,
    // The device treats a drop older than 36h as "yesterday's picks" but still
    // renders it. Offline is a mode, not an error (review §10.3).
    expires: new Date(new Date(src.publishAt).getTime() + 36 * 3600 * 1000).toISOString(),
    items: src.items.map(buildItem),
  };

  const json = JSON.stringify(payload);
  const etag = `"${createHash("sha256").update(json).digest("hex").slice(0, 16)}"`;
  writeFileSync(join(dropsDir, `${src.dropId}.json`), json + "\n");

  built.push({
    dropId: src.dropId,
    city: src.city,
    publishAt: src.publishAt,
    bytes: Buffer.byteLength(json),
    etag,
  });
}

built.sort((a, b) => a.dropId.localeCompare(b.dropId));
const latest = built[built.length - 1];

// The device fetches ONLY this manifest on a normal wake. If latestDropId matches
// what is cached, it stops — no drop download, no parse, no extra radio time.
const manifest = {
  schema: contract.schema,
  generatedAt: new Date().toISOString(),
  latestDropId: latest.dropId,
  latestEtag: latest.etag,
  drops: built.map(({ dropId, city, publishAt, bytes, etag }) => ({ dropId, city, publishAt, bytes, etag })),
  firmware: { version: "0.1.0", url: null },
};
writeFileSync(join(distDir, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n");

// A tiny redirector map for the QR short links. In production this is a Worker
// route; as a static file it is enough to prove the handoff end to end.
const links = {};
for (const file of files) {
  const src = JSON.parse(readFileSync(join(contentDir, file), "utf8"));
  for (const item of src.items) {
    if (item.link) {
      links[item.link] = {
        id: item.id,
        title: item.title,
        target: item.place
          ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(item.place)}`
          : `https://www.google.com/search?q=${encodeURIComponent(item.title)}`,
      };
    }
  }
}
writeFileSync(join(distDir, "links.json"), JSON.stringify(links, null, 2) + "\n");

// MARK: - Report

const maxBytes = Math.max(...built.map((b) => b.bytes));
const manifestBytes = Buffer.byteLength(JSON.stringify(manifest));

console.log(`\nMOOKS CONTENT BUILD -> dist/v1/\n`);
console.log(`  drops built        ${built.length}`);
console.log(`  latest             ${latest.dropId} (${latest.city})`);
console.log(`  largest drop       ${maxBytes} bytes`);
console.log(`  manifest           ${manifestBytes} bytes`);
console.log(`  short links        ${Object.keys(links).length}`);

// Tie the payload size back to the power budget, because that is the reason to care.
// ~90 mA while the radio is up; a fetch is dominated by association + TLS, not bytes.
const fetchSeconds = 5;
const mAhPerFetch = (90 * fetchSeconds) / 3600;
console.log(`
  Payload vs power budget:
    A ${maxBytes}-byte drop is irrelevant next to the cost of bringing the radio up.
    One full fetch ~= ${fetchSeconds}s at ~90 mA = ${mAhPerFetch.toFixed(3)} mAh.
    The manifest-only path (304, no drop body) is what keeps the daily cost near zero,
    which is why the device checks ${manifestBytes} bytes before it downloads ${maxBytes}.

  Deploy: publish dist/ to a CDN with ETag support and point the firmware at
          <origin>/v1/manifest.json. No server to run, nothing to keep alive.
`);
