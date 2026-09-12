# MOOKS — Food Radar

A tiny, tactile, battery-powered food-discovery device. One knob, one small OLED,
five discoveries a day, and then it tells you it's finished.

**Tagline:** *Five things. Then you're done.*

Four artefacts. One is a design review; two are working tools; one is an
intentionally-unfinished firmware skeleton.

```
.
├── MOOKS-design-review.md     ← START HERE. Full engineering + product review.
├── mooks-sim/                 ← works. Renders the UI at true panel resolution.
├── mooks-content/             ← works. Validates + builds the content payload.
└── mooks-firmware/            ← ~30%. Written but NEVER COMPILED. See caveat below.
```

> **Quickest way in:** open [`mooks-sim/out/screens/6x/`](mooks-sim/out/screens/6x)
> and look at the 16 screens. That's the product. Then read the review.

---

## The plan, and why each piece exists

The review made a lot of claims. Three of them were guesses dressed as numbers, and
guesses are exactly what sinks a hardware project — you find out they were wrong
after the acrylic is cut. So each tool below exists to convert one guess into a
measurement, **before you spend money.**

| Piece | The guess it removes | Status |
|---|---|---|
| `mooks-sim` | "this text will fit on the screen" / "this face looks balanced" | ✅ measured |
| `mooks-content` | "the content will be well-formed" | ✅ enforced in CI |
| `mooks-firmware` | "this architecture will work" | ⚠️ unverified |

The order is deliberate and it matches build order S0→S2 in the review: **design the
experience in software, then commit to geometry, then build hardware.** Every one of
these tools runs with no parts on your desk.

---

## 1. `mooks-sim` — the UI simulator (Swift, zero dependencies)

Draws every MOOKS screen into a 128×96 4-bit greyscale framebuffer — the exact
geometry of the recommended 1.32" SSD1327 panel — and exports PNGs.

**Why Swift and not Python:** because this same `MooksUI` module can be imported by a
SwiftUI app on macOS/iPadOS to become the interactive simulator (review §20). One
codebase serves as your design tool, your demo backup, and the Swift in a portfolio
that otherwise has none.

```bash
cd mooks-sim
swift build
swift run mooks-render                 # renders everything + prints the report
swift run mooks-render --ascii 07       # dump screen 07 in the terminal
swift run mooks-render --ascii all
swift run mooks-render --emit-vectors   # golden file for the content pipeline
```

The renderer has no zlib available, so it emits valid but uncompressed PNGs. After
re-rendering, shrink them before committing (no pixels are altered — it inflates and
re-deflates the IDAT, typically 99% smaller):

```bash
node tools/optimize-png.mjs out
```

**Output** (browsable on GitHub, or in the file explorer — top-right icon):

- `out/screens/1x/` — true size, 128×96. What the panel actually shows.
- `out/screens/6x/` — 6× nearest-neighbour for review. **Look at these.**
- `out/panel-A-dial-77x51.png` — front-mounted knob, your original layout
- `out/panel-B-crown-77x51.png` — side crown, display centred
- `out/panel-C-crown-62x42.png` — the V2 shell, for proportion comparison

**What it found (these correct the review):**

1. **Review §10.2 was wrong.** I guessed `why ≤ 96` chars. Measured, the safe limit is
   **60** (3 lines × 20 chars). Limits are now computed against a *fixed-width* font so
   that switching to a proportional face on device can only ever give you more room —
   a font change must never be able to break a layout.
2. **The detail footer collided.** `"Kopi Nako"` (52px) + `"press to save"` (76px) =
   128px in a 120px column. Caught by *rendering* it, not by reading the layout.
   Replaced with a 31px `> save` affordance; gesture teaching moved to a one-time card.
3. **A font bug.** The classic GLCD 5×7 `u` glyph is nearly identical to `v`, so
   "Tiramisu" rendered as "Tiramisv" at 2× scale. Squared off.
4. **Screen-to-face ratio**, which is the number that decides whether a device reads
   as a product or as a component in a box (a phone is ~85%):

   | Face | Screen % | Front dial fits? |
   |---|---|---|
   | 77 × 51 (as bought) | **13.8%** — screen looks lost | yes |
   | 70 × 45 | 17.2% | **no** |
   | 62 × 42 (V2 target) | 20.8% | **no** |

   That table contains a dependency you cannot design around: **shrinking the shell
   to V2 proportions makes a front-mounted dial physically impossible.** The crown
   layout isn't a styling preference — it's what unlocks the smaller device.
5. **Average lit pixels across all screens: 8.0%.** This is a power proxy (OLED
   current scales with lit pixels), so it's evidence for the review's claim that the
   dark aesthetic *is* the battery strategy rather than a justification for it.

---

## 2. `mooks-content` — the content pipeline (Node, zero dependencies)

Authored drops in → validated static JSON out. **There is no server.** Publish
`dist/` to any CDN with ETag support and point the firmware at
`<origin>/v1/manifest.json`.

```bash
cd mooks-content
npm test        # 13 wrap-parity vectors: does JS agree with Swift?
npm run validate
npm run build
npm run ci      # all three, as CI runs them
```

**The central idea:** the build step **pre-wraps** every string into display lines.
The device receives `titleLines`, `hookLines`, `whyLines` — not sentences. So the
firmware carries no word-wrap code and *cannot break its own layout.* The server
edits; the device draws.

```
content/2026-09-12.json          →     dist/v1/drops/2026-09-12.json
  "why": "Matcha's bitterness           "whyLines": ["Matcha's bitterness",
    cuts the mascarpone.                              "cuts the mascarpone.",
    That's the trick."                                "That's the trick."]
```

**Verified:** validator passes the real content, and on a deliberately-broken fixture
it produced 13 distinct errors and exited non-zero. Largest drop is 1,508 bytes; the
manifest is 399 bytes — so the device checks 399 bytes before deciding whether to
download 1,508, which is what keeps the daily radio cost near zero.

**What it found:** the panel font is **ASCII-only** (0x20–0x7E). Non-ASCII doesn't
render as a fallback box — it renders as *nothing, silently*. The review's own
`Cafés` menu label would have shipped as `Caf s`. Now a build failure.

It also enforces the honesty rule from review risk #13: a numeric trend **must**
carry a `source` field, or you use a direction word (`rising`/`steady`/`peaking`)
instead. You cannot accidentally print `↑238%` with nothing behind it.

---

## 3. `mooks-firmware` — ⚠️ incomplete and never compiled

**Read this before you trust anything in that folder.** There is no ESP32 toolchain
in the environment this was written in, so it has never been through a compiler.
Treat it as a reviewed design, not as working code.

Written (586 lines):

| File | What's in it |
|---|---|
| `platformio.ini` | pinned deps, three envs (`device` / `bench` / `native` tests) |
| `include/config.h` | **the pin map, and it matters** — see below |
| `src/core/EventBus.h` | the architectural keystone: one queue, UI drains, everything else posts |
| `src/hal/Encoder.{h,cpp}` | ISR-driven quadrature with a 16-entry transition LUT |
| `src/data/Models.h` | fixed-size PODs, no `String`, no allocation after boot |
| `src/ui/Theme.h` | mirror of the simulator's design system |
| `src/hal/Display.h` | header only — I stopped here |

Not written: `Display.cpp`, `Power`, `Store`, `WifiService`, `ApiClient`, `Screen`/
`Router`, the screen implementations, `App`, `main.cpp`. Roughly 1,600–2,000 more lines.

**The two things in `config.h` worth reading even if you write the rest yourself:**

1. **Never put an encoder channel on GPIO2, 8 or 9.** They're strapping pins sampled
   at reset. An encoder is mechanical and can sit in *any* state at power-on, so this
   gives you a board that sometimes refuses to boot — an intermittent fault that
   looks like dead hardware. Encoder is on 0/1/3.
2. **Only GPIO0–5 are RTC-capable on the C3**, so only those can wake it from deep
   sleep. The encoder *switch* must be in that range. Rotation can't wake the chip
   (quadrature needs a running CPU), so the interaction is "press to wake" — same as
   a watch crown.

And one honest limitation in `Display.h`: U8g2 drives the SSD1327 as **1 bit per
pixel**, so the greyscale hierarchy the design depends on isn't there on that backend
— greys get thresholded at ≥8. The layout is still correct. True 16-level greys mean
swapping to `Adafruit_SSD1327` or LVGL behind the same API. That's a deliberate V1.5
task, not a V1 blocker.

---

## Suggested next steps

1. **Look at `mooks-sim/out/screens/6x/`.** That's the product. If the interaction
   doesn't feel right there, no enclosure work will save it.
2. **Order parts** (review §18). Shipping is your critical path, not code.
3. **Decide dial vs crown** from `panel-A` / `panel-B` / `panel-C`.
4. **Write real content** — 30 days of it, into `mooks-content/content/`, while you're
   waiting for parts. Content decay is risk #1 in the register and this is the cheapest
   time to buy yourself a buffer.
5. **Firmware last**, with a real `pio run` loop, once parts are on your desk.

## A note on what these tools are worth to you

Three of the five findings above are things the review asserted incorrectly. That's
the argument for building tools before hardware, and it's also a portfolio point:
*"I built a simulator, and it proved three of my own design assumptions wrong before
I cut anything."* That sentence demonstrates more engineering maturity than a working
device does.
