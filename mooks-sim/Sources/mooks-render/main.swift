import Foundation
import MooksUI

// mooks-render — draws every MOOKS screen at true panel resolution.
//
//   swift run mooks-render                 render PNGs + print the report
//   swift run mooks-render --ascii 07      also dump screen 07 to the terminal
//   swift run mooks-render --ascii all     dump every screen to the terminal

let args = Array(CommandLine.arguments.dropFirst())

// --emit-vectors: dump the reference output of Theme.wrap() as JSON.
//
// The content pipeline reimplements this algorithm in JavaScript (CI has no Swift
// toolchain). Two implementations of one algorithm is a real risk, so Swift is the
// reference and the JS test asserts against this golden file.
if args.contains("--emit-vectors") {
    struct Vector: Encodable {
        let text: String
        let charsPerLine: Int
        let maxLines: Int
        let lines: [String]
        let allLines: [String]
    }
    let cases: [(String, Int, Int)] = [
        ("Matcha's bitterness cuts the mascarpone. That's the trick.", 20, 3),
        ("Matcha Tiramisu", 10, 2),
        ("Salt Bread", 10, 2),
        ("Everyone's ordering it.", 20, 2),
        ("", 20, 3),
        ("one", 20, 3),
        ("exactlytwentychars!!", 20, 2),
        ("twentyonecharacters!!", 20, 2),
        ("supercalifragilisticexpialidocious", 10, 2),
        ("a  b   c", 20, 2),
        ("This sentence is far too long to fit in the space available here.", 20, 3),
        ("Nine seats. One roast.", 20, 2),
        ("aaaaaaaaaaa bb", 10, 2),
    ]
    let vectors = cases.map { text, cpl, maxLines in
        Vector(text: text,
               charsPerLine: cpl,
               maxLines: maxLines,
               lines: Theme.wrap(text, charsPerLine: cpl, maxLines: maxLines),
               allLines: Theme.wrap(text, charsPerLine: cpl, maxLines: Int.max))
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(vectors)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
    exit(0)
}

let asciiIndex = args.firstIndex(of: "--ascii")
let asciiTarget: String? = {
    guard let i = asciiIndex, i + 1 < args.count else { return nil }
    return args[i + 1]
}()

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let outDir = root.appendingPathComponent("out")
let screensDir = outDir.appendingPathComponent("screens")
let screens1x = screensDir.appendingPathComponent("1x")
let screens6x = screensDir.appendingPathComponent("6x")

for dir in [outDir, screensDir, screens1x, screens6x] {
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
}

let catalog = Screens.catalog()

// MARK: - Render screens

for entry in catalog {
    try PNG.write(entry.frame, to: screens1x.appendingPathComponent("\(entry.name).png"), scale: 1)
    try PNG.write(entry.frame, to: screens6x.appendingPathComponent("\(entry.name).png"), scale: 6)
}

// MARK: - Render front-panel options, with a live screen composited in

let heroScreen = Screens.today(item: Sample.drop.items[0], index: 1, total: 5)

// V1 face, both input layouts.
try PNG.write(Panel.dial(screen: heroScreen),
              to: outDir.appendingPathComponent("panel-A-dial-77x51.png"), scale: 1)
try PNG.write(Panel.crown(screen: heroScreen),
              to: outDir.appendingPathComponent("panel-B-crown-77x51.png"), scale: 1)

// V2 target face, for the proportion comparison.
let v2W = 62.0, v2H = 42.0
try PNG.write(Panel.crown(screen: heroScreen, shellW: v2W, shellH: v2H),
              to: outDir.appendingPathComponent("panel-C-crown-62x42.png"), scale: 1)

// MARK: - Report

func pad(_ s: String, _ n: Int) -> String {
    s.count >= n ? String(s.prefix(n)) : s + String(repeating: " ", count: n - s.count)
}

print("""

MOOKS UI RENDER REPORT
Panel: 128 x 96, SSD1327, 16 grey levels (recommended 1.32" module)
Output: out/screens/1x (true size)  out/screens/6x (for review)  out/panel-*.png

""")

print(pad("SCREEN", 22) + pad("LIT%", 8) + pad("MEAN", 7) + "NOTE")
print(String(repeating: "-", count: 100))
var totalLit = 0.0
for entry in catalog {
    let (frac, mean) = entry.frame.litStats
    totalLit += frac
    print(pad(entry.name, 22)
          + pad(String(format: "%.1f", frac * 100), 8)
          + pad(String(format: "%.1f", mean), 7)
          + entry.note)
}
print(String(repeating: "-", count: 100))
print(String(format: "Average lit pixels across all screens: %.1f%%", totalLit / Double(catalog.count) * 100))
print("""

  Lit% is a power proxy. OLED current scales with lit pixel count and brightness,
  so a dark-dominant layout is both the aesthetic and the battery strategy (§7).
  Content screens sit under ~10%. The two QR screens are the peak at ~14-16%, which
  is fine because they are on for seconds. A filled/inverted UI would be 5-10x this.
""")

// MARK: - Face proportion — the finding the drawings made visible

print("""

FRONT-FACE PROPORTION
  Screen-to-face ratio is the number that decides whether a device reads as a product
  or as a component in a box. A phone is ~85%. Below roughly 15%, the display looks
  lost no matter how well the panel is finished.

""")
print(pad("FACE (mm)", 14) + pad("AREA cm2", 11) + pad("SCREEN%", 10) + pad("DIAL FITS?", 12) + "VERDICT")
print(String(repeating: "-", count: 82))
for (w, h, label) in [(77.0, 51.0, "V1 as bought"), (70.0, 45.0, "V2 conservative"), (62.0, 42.0, "V2 target")] {
    let ratio = Panel.screenToFaceRatio(shellW: w, shellH: h) * 100
    let fits = Panel.dialFits(shellW: w)
    let verdict = ratio < 15 ? "screen looks lost" : (ratio < 22 ? "acceptable" : "reads as a product")
    print(pad("\(Int(w)) x \(Int(h))", 14)
          + pad(String(format: "%.1f", w * h / 100), 11)
          + pad(String(format: "%.1f", ratio), 10)
          + pad(fits ? "yes" : "NO - crown", 12)
          + "\(label): \(verdict)")
}
print("""

  Read that table carefully, because it contains a dependency you cannot design around:
  shrinking the shell to V2 proportions makes a front-mounted dial physically impossible.
  The crown layout is not a styling preference — it is what UNLOCKS the smaller device.

""")

// MARK: - Measured layout capacity (this is the part that corrects the review)

print("""

MEASURED TEXT CAPACITY  (worst case: fixed-width 5x7 font)
  These limits are what the content validator must enforce. They are measured from
  the renderer, not estimated, and they are computed against a FIXED-width font so
  that moving to a proportional face on device can only ever give you more room.

""")
print(pad("FIELD", 10) + pad("SCALE", 8) + pad("CHARS/LINE", 12) + pad("LINES", 7) + "MAX CHARS")
print(String(repeating: "-", count: 60))
print(pad("title", 10) + pad("2x", 8) + pad("\(Theme.titleCharsPerLine)", 12)
      + pad("\(Theme.titleMaxLines)", 7) + "\(Theme.titleMaxChars)")
print(pad("hook", 10) + pad("1x", 8) + pad("\(Theme.hookCharsPerLine)", 12)
      + pad("\(Theme.hookMaxLines)", 7) + "\(Theme.hookMaxChars)")
print(pad("why", 10) + pad("1x", 8) + pad("\(Theme.whyCharsPerLine)", 12)
      + pad("\(Theme.whyMaxLines)", 7) + "\(Theme.whyMaxChars)")
print(pad("place", 10) + pad("1x", 8) + pad("\(Theme.placeMaxChars)", 12) + pad("1", 7) + "\(Theme.placeMaxChars)")

// MARK: - Validate the sample content against those limits

print("\nSAMPLE CONTENT CHECK\n")
var failures = 0
for item in Sample.drop.items {
    var problems: [String] = []
    if item.title.count > Theme.titleMaxChars { problems.append("title \(item.title.count)>\(Theme.titleMaxChars)") }
    if !Theme.fits(item.title, charsPerLine: Theme.titleCharsPerLine, maxLines: Theme.titleMaxLines) {
        problems.append("title wraps past \(Theme.titleMaxLines) lines")
    }
    if item.hook.count > Theme.hookMaxChars { problems.append("hook \(item.hook.count)>\(Theme.hookMaxChars)") }
    if !Theme.fits(item.hook, charsPerLine: Theme.hookCharsPerLine, maxLines: Theme.hookMaxLines) {
        problems.append("hook wraps past \(Theme.hookMaxLines) lines")
    }
    if item.why.count > Theme.whyMaxChars { problems.append("why \(item.why.count)>\(Theme.whyMaxChars)") }
    if !Theme.fits(item.why, charsPerLine: Theme.whyCharsPerLine, maxLines: Theme.whyMaxLines) {
        problems.append("why wraps past \(Theme.whyMaxLines) lines")
    }
    if let p = item.place, p.count > Theme.placeMaxChars { problems.append("place too long") }

    if problems.isEmpty {
        print("  ok    \(pad(item.id, 8)) \(item.title)")
    } else {
        failures += 1
        print("  FAIL  \(pad(item.id, 8)) \(item.title) — \(problems.joined(separator: ", "))")
    }
}
print(failures == 0
      ? "\n  All \(Sample.drop.items.count) sample items fit. This same check runs in CI (§10.1).\n"
      : "\n  \(failures) item(s) would break the layout. In CI this is a build failure.\n")

// MARK: - Optional terminal dump

if let target = asciiTarget {
    let wanted = catalog.filter { target == "all" || $0.name.hasPrefix(target) }
    for entry in wanted {
        print("\n\(entry.name) — \(entry.note)")
        print(entry.frame.asciiPreview())
    }
}
