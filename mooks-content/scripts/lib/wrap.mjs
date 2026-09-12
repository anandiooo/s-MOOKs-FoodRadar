// Greedy word wrap.
//
// This MUST agree exactly with Theme.wrap() in the Swift simulator
// (mooks-sim/Sources/MooksUI/Theme.swift). Swift is the reference implementation.
//
// The agreement is not assumed — it is tested. `mooks-render --emit-vectors` dumps
// the Swift output for a set of inputs, and test/wrap.test.mjs asserts this function
// reproduces it. Two implementations of the same algorithm in different languages is
// a real risk; a shared golden file is how you make it a managed one.

/**
 * @param {string} text
 * @param {number} charsPerLine
 * @returns {string[]} every line, with no truncation
 */
export function wrapAll(text, charsPerLine) {
  const lines = [];
  let current = "";

  for (const word of text.split(" ").filter((w) => w.length > 0)) {
    if (current.length === 0) {
      current = word;
    } else if (current.length + 1 + word.length <= charsPerLine) {
      current += " " + word;
    } else {
      lines.push(current);
      current = word;
    }
    // A single word longer than the line is a content bug, not a render bug.
    while (current.length > charsPerLine) {
      lines.push(current.slice(0, charsPerLine));
      current = current.slice(charsPerLine);
    }
  }
  if (current.length > 0) lines.push(current);
  return lines;
}

/** Wrapped and clipped to maxLines — what actually reaches the panel. */
export function wrap(text, charsPerLine, maxLines) {
  return wrapAll(text, charsPerLine).slice(0, maxLines);
}

/** True if the text survives wrapping without losing a line. */
export function fits(text, charsPerLine, maxLines) {
  return wrapAll(text, charsPerLine).length <= maxLines;
}
