#!/usr/bin/env node
// Content validator. Runs in CI. A content mistake must fail the BUILD, never reach
// a device — that is the whole reason the firmware carries no layout engine.
//
//   node scripts/validate.mjs

import { readFileSync, readdirSync } from "node:fs";
import { join, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { fits, wrapAll } from "./lib/wrap.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const contract = JSON.parse(readFileSync(join(root, "contract.json"), "utf8"));
const contentDir = join(root, "content");

const errors = [];
const warnings = [];
const seenIds = new Set();
const seenLinks = new Set();

function err(where, msg) { errors.push(`${where}: ${msg}`); }
function warn(where, msg) { warnings.push(`${where}: ${msg}`); }

/**
 * The panel font covers printable ASCII only (0x20-0x7E). A non-ASCII character
 * does not render as a fallback box — it renders as NOTHING, silently.
 *
 * This is a genuine trap: the original IA in the design review used "Cafés" as a
 * menu label, which would have shipped as "Caf s". Enforced here rather than
 * discovered on hardware.
 */
function checkAscii(where, field, value) {
  for (const ch of value) {
    const c = ch.codePointAt(0);
    if (c < 0x20 || c > 0x7e) {
      err(where, `${field} contains non-ASCII ${JSON.stringify(ch)} (U+${c.toString(16).toUpperCase().padStart(4, "0")}) — the 5x7 panel font has no glyph for it and it will render as blank. Use plain ASCII: ' not \u2019, "Cafes" not "Caf\u00e9s".`);
      return;
    }
  }
}

function checkTextField(where, field, value, limit, required) {
  if (value === undefined || value === null || value === "") {
    if (required) err(where, `${field} is required`);
    return;
  }
  if (typeof value !== "string") {
    err(where, `${field} must be a string`);
    return;
  }
  checkAscii(where, field, value);
  if (value.length > limit.maxChars) {
    err(where, `${field} is ${value.length} chars, limit ${limit.maxChars}`);
  }
  if (!fits(value, limit.charsPerLine, limit.maxLines)) {
    const lines = wrapAll(value, limit.charsPerLine);
    err(where, `${field} wraps to ${lines.length} lines, limit ${limit.maxLines} (${lines.map((l) => `"${l}"`).join(" / ")})`);
  }
  // A word too long for one line gets hard-broken mid-word, which looks broken.
  for (const word of value.split(" ")) {
    if (word.length > limit.charsPerLine) {
      err(where, `${field} contains "${word}" (${word.length} chars) which cannot fit one ${limit.charsPerLine}-char line and will be split mid-word`);
    }
  }
}

function validateItem(dropId, index, item) {
  const where = `${dropId}[${index}] ${item.id ?? "<no id>"}`;
  const L = contract.limits;

  if (!item.id || !/^[a-z]{2}-\d{3}$/.test(item.id)) {
    err(where, `id must match xx-000, got ${JSON.stringify(item.id)}`);
  } else if (seenIds.has(item.id)) {
    err(where, `duplicate id — ids must be unique across all drops, because the device stores "seen" and "saved" by id`);
  } else {
    seenIds.add(item.id);
  }

  if (!contract.kinds.includes(item.kind)) {
    err(where, `kind must be one of ${contract.kinds.join(", ")}, got ${JSON.stringify(item.kind)}`);
  }

  // Trend: a number needs a source, or use a direction word.
  const t = item.trend ?? {};
  const hasPercent = typeof t.percent === "number";
  const hasWord = typeof t.word === "string";
  if (hasPercent === hasWord) {
    err(where, `trend must have exactly one of {percent} or {word}`);
  }
  if (hasWord && !contract.trend.words.includes(t.word)) {
    err(where, `trend.word must be one of ${contract.trend.words.join(", ")}, got ${JSON.stringify(t.word)}`);
  }
  if (hasPercent) {
    if (!Number.isInteger(t.percent)) err(where, `trend.percent must be an integer`);
    if (Math.abs(t.percent) > 9999) err(where, `trend.percent is implausible`);
    if (contract.trend.percentRequiresSource && !t.source) {
      err(where, `trend.percent=${t.percent} has no source. Cite the signal or switch to a direction word — do not print invented precision on a physical object.`);
    }
  }

  checkTextField(where, "title", item.title, L.title, true);
  checkTextField(where, "hook", item.hook, L.hook, true);
  checkTextField(where, "why", item.why, L.why, true);
  checkTextField(where, "place", item.place, L.place, false);

  if (item.kind === "place" && !item.place) {
    warn(where, `kind is "place" but no place/neighbourhood is set — the card will have an empty footer`);
  }

  if (item.link !== undefined) {
    if (!new RegExp(`^[a-z0-9]{1,${contract.link.maxCodeLength}}$`).test(item.link)) {
      err(where, `link must be 1-${contract.link.maxCodeLength} lowercase alphanumerics (QR density — see contract.link.note), got ${JSON.stringify(item.link)}`);
    } else if (seenLinks.has(item.link)) {
      err(where, `duplicate link code ${item.link}`);
    } else {
      seenLinks.add(item.link);
    }
  }

  if (!Array.isArray(item.tags) || item.tags.length === 0) {
    err(where, `tags must be a non-empty array (they drive the on-device affinity re-rank)`);
  } else {
    if (item.tags.length > 4) warn(where, `${item.tags.length} tags; 2-4 is plenty`);
    for (const tag of item.tags) {
      if (typeof tag !== "string" || !/^[a-z0-9-]+$/.test(tag)) {
        err(where, `tag ${JSON.stringify(tag)} must be lowercase alphanumeric/hyphen`);
      }
    }
  }
}

// MARK: - Run

const files = readdirSync(contentDir).filter((f) => f.endsWith(".json")).sort();
if (files.length === 0) {
  console.error("No content files found in content/");
  process.exit(1);
}

const drops = [];
for (const file of files) {
  const where = file;
  let drop;
  try {
    drop = JSON.parse(readFileSync(join(contentDir, file), "utf8"));
  } catch (e) {
    err(where, `not valid JSON: ${e.message}`);
    continue;
  }

  const expectedId = basename(file, ".json");
  if (drop.dropId !== expectedId) {
    err(where, `dropId ${JSON.stringify(drop.dropId)} does not match filename ${expectedId}`);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(drop.dropId ?? "")) {
    err(where, `dropId must be YYYY-MM-DD`);
  }
  if (!drop.city || !/^[a-z]{3}$/.test(drop.city)) {
    err(where, `city must be a 3-letter code`);
  }
  if (!Array.isArray(drop.items)) {
    err(where, `items must be an array`);
    continue;
  }
  if (drop.items.length !== contract.drop.itemCount) {
    err(where, `has ${drop.items.length} items, must be exactly ${contract.drop.itemCount}. ${contract.drop.note}`);
  }
  drop.items.forEach((item, i) => validateItem(drop.dropId, i, item));
  drops.push(drop);
}

// MARK: - Report

console.log(`\nMOOKS CONTENT VALIDATION`);
console.log(`  ${files.length} drop(s), ${seenIds.size} item(s), contract schema ${contract.schema}\n`);

for (const w of warnings) console.log(`  warn  ${w}`);
if (warnings.length) console.log("");

if (errors.length) {
  for (const e of errors) console.log(`  FAIL  ${e}`);
  console.log(`\n  ${errors.length} error(s). Nothing is published.\n`);
  process.exit(1);
}

console.log(`  All content fits the panel. Safe to build.\n`);
