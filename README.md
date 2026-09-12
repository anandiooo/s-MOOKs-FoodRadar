# MOOKS — Food Radar

A tiny, tactile, battery-powered food-discovery device. One knob, one small screen,
five discoveries a day — and then it tells you it's finished.

**Tagline:** *Five things. Then you're done.*

MOOKS is the opposite of a social feed. A phone feed is infinite and designed to
keep you scrolling; MOOKS shows you exactly five curated food/café discoveries, lets
you save the ones you like, hands the best to your phone via a QR code, and then
stops. It is a single-purpose desk object with one physical control: a rotary knob
you turn, press, and hold.

---

## Table of contents

1. [What is in this repository](#1-what-is-in-this-repository)
2. [Glossary — every term and acronym used here](#2-glossary--every-term-and-acronym-used-here)
3. [Why these technologies (with alternatives compared)](#3-why-these-technologies-with-alternatives-compared)
4. [How the three pieces fit together](#4-how-the-three-pieces-fit-together)
5. [`mooks-sim/` — the UI simulator, file by file](#5-mooks-sim--the-ui-simulator-file-by-file)
6. [`mooks-content/` — the content backend, file by file](#6-mooks-content--the-content-backend-file-by-file)
7. [`mooks-firmware/` — the device code, file by file](#7-mooks-firmware--the-device-code-file-by-file)
8. [How to run everything](#8-how-to-run-everything)
9. [Status, and suggested next steps](#9-status-and-suggested-next-steps)

> **New here? Do this first.** Open
> [`mooks-sim/out/screens/6x/`](mooks-sim/out/screens/6x) and look at the 16 PNG
> images. That is the actual product interface. Then skim
> [`MOOKS-design-review.md`](MOOKS-design-review.md) for the reasoning, and
> [`PROJECT-STATUS.md`](PROJECT-STATUS.md) for the honest done/not-done breakdown.

---

## 1. What is in this repository

There are four things here. One is a written review, two are working desktop tools,
and one is an unfinished skeleton for the code that will eventually run on the
physical device.

```
s-MOOKs-FoodRadar/
├── README.md                  ← this file
├── PROJECT-STATUS.md          ← what's done / designed / not started, tagged line-by-line
├── MOOKS-design-review.md     ← the full engineering + product review (21 sections)
│
├── mooks-sim/                 ← [WORKS] draws the interface and exports images
├── mooks-content/             ← [WORKS] turns authored food data into device-ready files
└── mooks-firmware/            ← [~30%, NEVER COMPILED] the code for the ESP32 chip
```

Why is it split this way? Because a hardware product is really **four separate
problems** — the physical object, the on-screen interface, the data it shows, and the
embedded code that ties them together — and each can be worked on independently. The
two tools here (`mooks-sim`, `mooks-content`) let you finish the interface and the
data **on a laptop, before buying a single component**. That ordering is the whole
strategy: design → prove in software → then build hardware.

---

## 2. Glossary — every term and acronym used here

If you have read the design review or the code and hit a word you did not know, it is
almost certainly here. Grouped by area.

### Hardware / electronics

| Term | Plain-English meaning |
|---|---|
| **MCU** | Microcontroller unit — the small computer chip that runs the device. Ours is an ESP32-C3. |
| **ESP32-C3** | A popular, cheap Wi-Fi microcontroller made by Espressif. "SuperMini" is a tiny ready-made board built around it. |
| **RISC-V** | The instruction-set/CPU architecture inside the ESP32-C3. Just means "the kind of processor it is." |
| **OLED** | Organic LED display. Each pixel emits its own light, so "off" pixels are truly black — perfect for a dark, premium look. |
| **SSD1327 / SH1106 / SSD1306** | Display "driver" chips — the controller baked into an OLED module that the MCU talks to. Different modules use different ones; you must know which, because the code differs. |
| **Panel / module / active area** | *Panel* = the glass. *Module* = the glass plus its little circuit board. *Active area* = just the part that actually lights up (smaller than the module). |
| **Greyscale (16-level / 4-bit)** | The screen can show 16 shades of grey, not just on/off. This lets text have soft edges and lets us build visual hierarchy with brightness. |
| **1-bit / monochrome** | A screen that can only do on/off — no greys. Cheaper, but text looks jagged. |
| **I²C / SPI** | Two ways a chip talks to a display over wires. I²C uses 2 signal wires (4 pins total); SPI uses 4+ signal wires (6–7 pins) but is faster. **A 4-pin display is I²C, full stop** — this matters because a seller mislabelled ours as "SPI." |
| **EC11** | A specific, common model of *rotary encoder* — the knob. |
| **Rotary encoder** | A knob that reports *how much it turned and which way*, rather than an absolute position. Ours also clicks in as a button. |
| **Quadrature** | The two-signal scheme an encoder uses to tell rotation direction apart. Reading it correctly is the fiddly part of the firmware. |
| **Detent** | The little mechanical "click" you feel per step of the knob. One detent = one item moved. |
| **LiPo** | Lithium-polymer rechargeable battery — a flat pouch cell. |
| **mAh** | Milliamp-hours — battery capacity. Bigger = longer runtime. |
| **PCM / protection circuit** | A tiny board on the battery that prevents over-charge, over-discharge, and short circuits. A LiPo without one is a fire risk. |
| **TP4057 / TP4056 / BQ25185** | Battery-charger chips. They take USB 5 V and safely charge the LiPo. TP4057 is the small one we recommend. |
| **Schottky diode** | A diode with a very low voltage drop. One of these lets the device run off USB while charging, without current flowing backward into the battery. |
| **LDO** | Low-dropout regulator — turns the battery's ~3.7 V into a clean 3.3 V for the chip, even when the battery sags. |
| **ME6211 / AMS1117** | Two specific LDO models. The ME6211 works on battery power; the AMS1117 does not (it needs too much headroom). You must check which your board has. |
| **Deep sleep** | A near-off power state (~50 microamps) the chip drops into when idle, so the battery lasts weeks. Wakes on a button press. |
| **RTC-capable GPIO** | Only certain pins (GPIO0–5 on this chip) can wake it from deep sleep. The knob's button must be on one of them. |
| **Strapping pin** | A few pins (GPIO2/8/9) are read at power-on to decide how the chip boots. You must NOT put the encoder on them, or the device sometimes won't start. |
| **GPIO** | General-purpose input/output — a physical pin you can wire something to. |
| **ADC** | Analog-to-digital converter — lets the chip *measure* a voltage (e.g. the battery level). |
| **Ballast** | Dead weight (a metal plate) added on purpose. A heavier object feels more premium; MOOKS is otherwise too light for its size. |
| **NFC / NTAG213** | Near-field communication — a passive sticker your phone can tap to open a URL. Optional; used for setup instructions. |
| **NVS** | Non-volatile storage — a small key/value store in the chip's flash that survives power-off (Wi-Fi password, saved items). |
| **LittleFS** | A tiny filesystem for the chip's flash — used to cache the last couple of daily "drops." |

### Software / architecture

| Term | Plain-English meaning |
|---|---|
| **Framebuffer** | An in-memory picture of the whole screen (128×96 values here). You draw into it, then push it to the display in one go. |
| **U8g2** | The standard open-source graphics library for small monochrome/OLED displays on Arduino/ESP32. Handles fonts and shapes. |
| **Bitmap font** | A font where each character is a small grid of on/off dots (ours is 5×7). Contrast with vector/proportional fonts. |
| **Fixed-width vs proportional font** | Fixed-width: every character is the same width (like a typewriter). Proportional: `i` is narrower than `m`. We size layouts against fixed-width so the real proportional font can only ever fit *better*. |
| **Word wrap** | Breaking a sentence into lines that fit a given width. We do this once on the server, not on the device. |
| **PNG / IDAT / zlib / DEFLATE** | PNG is the image format. IDAT is its pixel-data chunk. zlib/DEFLATE is the compression inside it. Relevant because our Swift renderer writes *uncompressed* PNGs and a small Node tool shrinks them. |
| **FreeRTOS** | The real-time operating system built into the ESP32 firmware. Lets the device run several "tasks" (UI, networking) at once. |
| **Task** | An independent unit of work FreeRTOS runs "simultaneously." We keep the UI task and the network task separate so a slow network never freezes the screen. |
| **Event bus / queue** | A single mailbox that all parts of the firmware post messages to, and the UI reads from. Keeps the code from becoming tangled. |
| **ISR** | Interrupt service routine — a tiny function the chip runs *instantly* when a pin changes. We read the fast-moving knob this way instead of polling. |
| **State machine** | A model of "what mode are we in and what can happen next" (e.g. Browsing → Detail → Saved). |
| **POD** | Plain old data — a simple struct with no dynamic memory. We use these so the device never fragments its memory over weeks of uptime. |
| **Heap / heap fragmentation** | The pool of dynamically-allocated memory. If you allocate/free constantly (e.g. via `String`), it fragments and eventually a big allocation (like a secure connection) fails. We avoid this by not allocating after startup. |

### Backend / networking

| Term | Plain-English meaning |
|---|---|
| **API** | Application programming interface — the agreed way two programs talk. Here, how the device asks the backend for today's data. |
| **Backend** | The server side. In V1 there is *no live server* — just static files on a CDN. |
| **CDN** | Content delivery network — globally distributed static file hosting (e.g. Cloudflare Pages, GitHub Pages). Fast, cheap, nothing to maintain. |
| **Static files / server-less** | The device just downloads files; no program runs on a server to answer it. Simplest possible, and free. |
| **Drop** | One day's set of exactly 5 discoveries. The unit of content. |
| **Manifest** | A tiny index file (~400 bytes) listing what the latest drop is, so the device can check "is there anything new?" cheaply. |
| **JSON** | The plain-text data format both the content and the API use. Human-readable. |
| **Conditional GET / ETag / 304** | A web technique: the device sends the *fingerprint* (ETag) of what it already has; if nothing changed, the server replies "304 Not Modified" (~200 bytes) instead of resending the file. Saves battery. |
| **HTTPS / TLS / CA pinning** | Encrypted web requests. "Pinning the CA" means the device only trusts a specific certificate authority — more secure than accepting any certificate. |
| **CI** | Continuous integration — automation (GitHub Actions here) that validates and builds the content every time it changes, so mistakes never ship. |
| **Captive portal** | The "sign in to Wi-Fi" web page that pops up when you join a network — like at a hotel. We use one so you can enter your Wi-Fi password from your phone. |
| **SoftAP** | Software access point — the device briefly *becomes* a Wi-Fi hotspot (`MOOKS-setup`) so your phone can connect to it during setup. |
| **QR code** | The square barcode. We show one on the OLED so your phone can join setup, or open a location, by scanning instead of typing. |
| **OTA** | Over-the-air update — sending new firmware to the device over Wi-Fi. Planned for later. |

### Product / design

| Term | Plain-English meaning |
|---|---|
| **UX / UI** | User experience / user interface. UX = how it feels to use; UI = what's on screen. |
| **IA** | Information architecture — how the content and menus are organised. |
| **Core loop** | The short repeated cycle of using the product (pick up → browse → save → done). |
| **Handoff** | Passing a task from MOOKS to your phone (via QR) — e.g. "open this café in Maps." |
| **BOM** | Bill of materials — the parts list. |
| **V1 / V1.5 / V2** | Version milestones. V1 = the first working product; later numbers add features. |
| **Burn-in** | OLED wear: pixels lit constantly get permanently dimmer. We jitter the layout and keep it dark to prevent it. |

---

## 3. Why these technologies (with alternatives compared)

Every technology choice here was deliberate. This section explains the *reasoning*,
including what was rejected and why — because "why not X?" is the first question a
reviewer (or your future self) will ask.

### 3.1 Why Swift for the UI simulator?

The simulator draws the interface on a computer so you can perfect it before the
hardware exists. It could have been written in almost any language. It is Swift for
one specific strategic reason:

> **This project is preparation for the Apple Developer Academy, whose curriculum is
> built around Swift and SwiftUI. A beautiful hardware project with zero Apple-platform
> code is an awkward fit for that application.** Writing the simulator's core as a
> reusable Swift module (`MooksUI`) means a SwiftUI app on macOS/iPadOS can later
> `import` it and become an interactive, draggable-knob demo — which triples its value:
> it is a design tool *now*, demo insurance if the hardware fails in an interview
> *later*, and the Swift-in-a-portfolio the Academy expects.

Compared with the alternatives:

| Option | Verdict | Reasoning |
|---|---|---|
| **Swift** (chosen) | ✅ | Reusable by a future SwiftUI app; puts Swift in the portfolio; fast, type-safe, no runtime to install on macOS. |
| Python + Pillow | ❌ | Fastest to prototype, but a throwaway — nothing carries forward to an Apple-platform app, and the environment had no Pillow anyway. |
| JavaScript / Canvas | ❌ | Would run in a browser (nice for sharing), but again nothing feeds the SwiftUI goal. Kept JS only for the *content* side, where Node is the natural fit. |
| Draw directly in firmware (C++) | ❌ | You would need the hardware to see anything, and every change means a reflash. Far too slow a loop for design iteration. |

**Why zero dependencies?** The simulator uses no third-party packages — it even ships
its own bitmap font and PNG writer. That means anyone can `swift build` it years from
now with no package resolution, no version drift, and no broken links. For a
portfolio artefact that must survive, that durability is worth the ~100 extra lines.

### 3.2 Why Node/JavaScript for the content pipeline?

The content pipeline validates food data and turns it into files the device
downloads. It is Node because:

- **The data is JSON and the output is JSON** — JavaScript is the mother tongue of
  JSON; no serialization library needed.
- **CI (GitHub Actions) has Node built in** — the validator runs on every change with
  zero setup.
- **It is glue code, not application code** — small scripts that read files, check
  them, and write files. Node is ideal for exactly this.

| Option | Verdict | Reasoning |
|---|---|---|
| **Node, zero deps** (chosen) | ✅ | Native JSON, built into CI, trivial to run, and the wrap algorithm is simple enough to not need a library. |
| Python | ⚪ | Perfectly fine too; chosen Node only because the wrap logic had to mirror the simulator and JS kept the two implementations easy to eyeball side by side. |
| A real database + server | ❌ | Massive overkill for one editor publishing 5 items a day. A server is something to pay for, secure, monitor, and keep alive. Static files are free and never go down. |
| A CMS (Contentful, Sanity, etc.) | ❌ | Adds an account, an API key on the device, and a dependency — for data you can author in a text file or a spreadsheet. |

### 3.3 Why a server-less / static-file backend?

This is the most important backend decision, so it gets its own note. The device does
**one HTTPS GET** to download a small JSON file from a CDN. There is no application
server.

**Reasoning:** MOOKS has one user (you) and shows 5 items a day. A traditional
backend (server + database) would be something to run, pay for, secure, and debug —
all to serve a file that changes once a day and is identical for everyone. Static
files on a CDN are free, globally fast, never crash, and have no secret that could
leak from a device you hand to strangers. Using the *conditional GET* trick (ETag →
304), the everyday case is a ~200-byte response, which protects battery life. This is
a more sophisticated answer than "I built a REST API," precisely because it is
simpler.

### 3.4 Why C++/PlatformIO/FreeRTOS/U8g2 for the firmware?

This stack is the mainstream, well-trodden path for ESP32 devices — chosen so that
when something breaks, the answer is one search away.

| Choice | Why | Alternative rejected |
|---|---|---|
| **C++ (Arduino-ESP32 framework)** | Huge library ecosystem, the display and JSON libraries are one line away. | Bare ESP-IDF: more control, but you'd rebuild what U8g2/ArduinoJson give free. Rust: excellent, but a smaller ESP ecosystem and a steeper path for a student project. |
| **PlatformIO** (not the Arduino IDE) | Real project structure, *pinned* library versions (so an update can't silently change behaviour months later), git-friendly, multiple build profiles. | Arduino IDE: no dependency pinning, poor for version control, no project layout. |
| **FreeRTOS tasks** | Lets networking run on its own task so a slow/dying Wi-Fi never freezes the screen — the single most important reliability decision. | One big `loop()`: simplest, but any blocking call (like a network timeout) stalls the whole UI. |
| **U8g2 graphics library** | The de-facto standard for small OLEDs; supports our display controllers; tiny and battle-tested. | Adafruit GFX: fine, but U8g2 has better fonts and lower memory use for monochrome. (We do plan to swap to `Adafruit_SSD1327` later *just* for true greyscale — see the firmware notes.) |
| **ArduinoJson** | The standard streaming JSON parser for embedded; can parse without loading the whole document into RAM. | Hand-rolled parser: pointless and bug-prone when a proven one exists. |

---

## 4. How the three pieces fit together

The three code folders are not independent — they share one design and reinforce each
other. The key connections:

```
  ┌─────────────────┐   defines the exact character limits that both sides obey
  │  contract.json  │───────────────────────────────────────────────┐
  │ (in mooks-      │                                                │
  │  content)       │                                                ▼
  └─────────────────┘                                     ┌────────────────────┐
                                                           │  mooks-content     │
  ┌────────────────────┐   Swift wrap() is the "reference  │  build.mjs pre-     │
  │  mooks-sim         │   answer"; the content pipeline    │  wraps text into   │
  │  Theme.wrap()      │──►tests its JS wrap() against it   │  display lines     │
  │  (draws the UI)    │   via a golden file of vectors     │                    │
  └────────────────────┘                                    └─────────┬──────────┘
           │  renders the same layouts                                │ emits
           ▼  the firmware must reproduce                             ▼
  ┌────────────────────┐                                    ┌────────────────────┐
  │  mooks-firmware     │◄───────────────────────────────── │  static JSON on a  │
  │  Theme.h + screens  │   downloads the pre-wrapped drop,  │  CDN (device reads)│
  │  (runs on device)   │   draws it at fixed coordinates    └────────────────────┘
  └────────────────────┘
```

Three shared ideas make this hang together:

1. **One source of truth for "what fits":** `mooks-content/contract.json` holds the
   character limits. The simulator's `Theme.swift`, the firmware's `Theme.h`, and the
   content validator all obey the same numbers.
2. **The server edits; the device draws.** Text is wrapped into lines *once*, at build
   time, by `build.mjs`. The device receives ready-made lines and never has to (and
   cannot) break its own layout. This is why the firmware needs no word-wrap code.
3. **Swift is the reference; JavaScript is tested against it.** Two languages
   implement the same wrap algorithm, which is a real risk. So the simulator can emit
   a "golden file" of known-correct outputs, and the content pipeline's test asserts
   its JS matches — turning an assumption into a guarantee.

---

## 5. `mooks-sim/` — the UI simulator, file by file

**Purpose:** draw every MOOKS screen at true panel resolution (128×96) on your
computer and export them as PNG images, so you can perfect the interface before any
hardware exists. Written in Swift, no dependencies.

```
mooks-sim/
├── Package.swift                       Swift package manifest (targets + build config)
├── Sources/
│   ├── MooksUI/                        the reusable library (a SwiftUI app could import this)
│   │   ├── Font5x7.swift               a 5×7 dot-matrix font for printable ASCII
│   │   ├── FrameBuffer.swift           the 128×96 canvas + all drawing primitives
│   │   ├── PNG.swift                   writes the canvas out as a PNG image file
│   │   ├── Theme.swift                 the design system: grey levels, spacing, text limits, wrap()
│   │   ├── Model.swift                 the data types (Item, Drop, Trend) + sample content
│   │   ├── Screens.swift               every screen's layout — THIS IS THE ACTUAL UI
│   │   └── Panel.swift                 front-face proportion drawings (knob vs crown, V1 vs V2)
│   └── mooks-render/
│       └── main.swift                  the command-line program: renders everything, prints a report
├── tools/
│   └── optimize-png.mjs                shrinks the exported PNGs ~99% before committing
└── out/                                the generated images (committed so they're viewable on GitHub)
    ├── screens/1x/                     true size (128×96) — what the panel really shows
    ├── screens/6x/                     6× enlarged — for looking at on a monitor
    └── panel-*.png                     the front-face layout studies
```

**File-by-file:**

- **`Package.swift`** — Tells Swift how to build the project: one *library* target
  (`MooksUI`, the reusable part) and one *executable* target (`mooks-render`, the CLI
  that uses it). This split is deliberate — the library has no command-line code in
  it, so a future SwiftUI app can import `MooksUI` cleanly.

- **`Font5x7.swift`** — A hand-encoded bitmap font: each printable ASCII character
  (space through `~`) as a 5-wide × 7-tall grid of dots. Small screens need a compact
  font, and shipping our own means zero dependencies. *This file is also where a bug
  was caught:* the classic version of the lowercase `u` looked almost identical to
  `v`, so "Tiramisu" rendered as "Tiramisv" at 2× size. It's squared off now, with a
  comment explaining why.

- **`FrameBuffer.swift`** — The canvas. A 128×96 grid where each cell holds a grey
  value 0–15. It provides every drawing operation — pixels, lines, rectangles, text,
  and small custom glyphs (the trend arrow, the battery icon, the selection chevron, a
  QR-code placeholder). Every one of these has a direct equivalent in the U8g2 library,
  so layout code written here ports to the firmware almost line-for-line. It also
  computes the **"lit-pixel percentage,"** a proxy for power draw (OLED current scales
  with how many pixels are lit) and can print an ASCII preview of a screen to the
  terminal.

- **`PNG.swift`** — A minimal, dependency-free PNG image writer. The environment had
  no image library and no internet to fetch one, so this encodes PNG by hand. It uses
  *uncompressed* data blocks (valid PNG, just large), which is why the `optimize-png`
  tool exists.

- **`Theme.swift`** — The **design system**, expressed as numbers a firmware author
  can copy: the four grey levels (title 15/15, body 11/15, label 6/15, quiet 4/15 —
  i.e. 100% / 73% / 40% / 27% brightness), the
  margins and grid, the type scale, and — critically — the **measured text capacity**
  (how many characters fit in a title, hook, why-text, etc.). It also contains the
  `wrap()` function that breaks a sentence into lines. This function is the
  **reference implementation** the content pipeline must match.

- **`Model.swift`** — The data structures the UI displays: an `Item` (one discovery),
  a `Drop` (a day of five), and `Trend` (either a sourced percentage or a direction
  word like "rising"). Plus the sample content used to render the screens.

- **`Screens.swift`** — **The interface itself.** Every screen — boot, the five
  "today" cards, the detail view, save confirmation, the QR handoff, the "that's all
  for today" end screen, the menu, saved list, Wi-Fi setup, low battery — is a
  function here that draws into a `FrameBuffer`. Layout is *fixed* (positions are
  constants, not computed at runtime) on purpose: the device draws at these exact
  coordinates and the backend guarantees the text fits, so a content mistake can never
  produce a broken screen.

- **`Panel.swift`** — Not a screen, but scale drawings of the *front face* of the
  device (10 pixels = 1 mm), with a real rendered screen composited into the display
  window. It draws two input layouts (a front-mounted **dial** vs a side **crown**)
  and two shell sizes (the 77×51 mm V1 box vs a 62×42 mm V2), and it computes the
  **screen-to-face ratio** — the number that reveals whether the display looks
  intentional or lost. This is where the "the small shell needs a crown" dependency
  became visible instead of assumed.

- **`Sources/mooks-render/main.swift`** — The command-line program. It renders all 16
  screens (at 1× and 6×) plus the 3 panel studies, then prints a report: the
  lit-pixel percentage per screen, the measured text limits, a validation of the
  sample content against those limits, and the front-face proportion table. It can
  also dump any screen to the terminal as ASCII (`--ascii 07`) or emit the wrap
  "golden file" the content tests need (`--emit-vectors`).

- **`tools/optimize-png.mjs`** — A small Node utility that re-compresses the exported
  PNGs. Because `PNG.swift` writes them uncompressed, they start at ~8 MB total; this
  shrinks them to ~150 KB **without changing a single pixel** (it just re-packs the
  existing image data). Run it after re-rendering, before committing.

- **`out/`** — The generated images. These are committed to the repo on purpose so you
  can view the interface directly on GitHub without installing Swift.

---

## 6. `mooks-content/` — the content backend, file by file

**Purpose:** the entire V1 backend. You author daily "drops" as JSON; this validates
them and builds the exact files the device downloads. **There is no server** — the
output goes on a CDN. Written in Node, no dependencies.

```
mooks-content/
├── contract.json                   THE SINGLE SOURCE OF TRUTH for what fits on screen
├── content/                        the drops you author (input)
│   ├── 2026-09-12.json             a sample day (5 items, Jakarta)
│   └── 2026-09-13.json             a second sample day
├── scripts/
│   ├── lib/
│   │   └── wrap.mjs                JavaScript copy of the Swift wrap() algorithm
│   ├── validate.mjs                checks every drop; fails the build on any error
│   └── build.mjs                   pre-wraps text + emits the device-ready files
├── test/
│   ├── wrap.test.mjs               proves the JS wrap matches the Swift reference
│   └── wrap-vectors.json           the "golden file" of correct answers (from the simulator)
├── package.json                    npm commands: test / validate / build / ci
└── dist/                           the built output (git-ignored; regenerate with `npm run build`)
    └── v1/
        ├── manifest.json           tiny index: "what's the latest drop?"
        ├── drops/2026-09-12.json   a day's data, pre-wrapped into display lines
        └── links.json              short-code → destination map for the QR handoff
```

**File-by-file:**

- **`contract.json`** — The rules that define what physically fits on the panel: max
  characters and lines for each text field (title, hook, why, place), the exact number
  of items per drop (5), the max QR short-link length, the allowed categories, and the
  rule that a numeric trend must cite a source. Both the validator and (by mirroring)
  the simulator obey this one file. Change a limit here, re-render the simulator, and
  everything stays in sync.

- **`content/*.json`** — The drops *you write*. Each is one day: a date, a city, and
  exactly five items. This is the only file type you touch day-to-day. In production
  you'd author these in a spreadsheet or Notion and have CI convert them, but plain
  JSON is enough to prove the whole system.

- **`scripts/lib/wrap.mjs`** — The word-wrap algorithm, in JavaScript. It is a
  deliberate line-for-line copy of the Swift `Theme.wrap()`. Two copies of one
  algorithm is a risk (they could drift apart), which is exactly why the test below
  exists.

- **`scripts/validate.mjs`** — The gatekeeper. It checks every drop against the
  contract: text lengths, line counts, exactly-five-items, valid categories, unique
  IDs, short-link format, and — a subtle one — that all text is **plain ASCII**,
  because the panel font has no glyph for anything else and non-ASCII would render as
  *nothing, silently*. (This caught that the design review's own "Cafés" label would
  have shipped as "Caf s".) On any error it prints a clear message and exits non-zero,
  which **fails the build** so the mistake never reaches a device.

- **`scripts/build.mjs`** — The builder. For each valid drop it **pre-wraps** every
  string into display lines, decides the trend accent + arrow direction, and writes:
  the per-day drop file (with `titleLines`, `hookLines`, `whyLines` instead of raw
  sentences), a tiny **manifest** (so the device can cheaply ask "anything new?"), and
  a **links** map (short codes → Google Maps/search URLs for the QR handoff). It also
  reports payload sizes and ties them to the battery budget.

- **`test/wrap.test.mjs` + `test/wrap-vectors.json`** — The parity guarantee.
  `wrap-vectors.json` is a "golden file" of known-correct wrap results *generated by
  the Swift simulator*. The test feeds the same inputs to the JavaScript `wrap()` and
  asserts identical output. If someone edits one language's wrap and not the other,
  this test goes red — catching the exact drift that would otherwise ship clipped text
  to hardware.

- **`package.json`** — Defines the commands: `npm test` (parity), `npm run validate`,
  `npm run build`, and `npm run ci` (all of them, as the automation runs them).

- **`dist/`** — The built output the device actually downloads. It is **git-ignored**
  because it's generated — regenerate any time with `npm run build`. CI builds and
  (once configured) deploys it to the CDN.

- **`.github/workflows/content.yml`** *(at the repo root, not in this folder)* — The
  automation. On every change it runs the parity test, validates the content, and
  builds the output. It also has a daily scheduled run (so a fresh drop is live before
  the morning) and a commented-out Cloudflare deploy step ready to enable. It lives at
  the repo root because GitHub only runs workflows from there.

---

## 7. `mooks-firmware/` — the device code, file by file

**Purpose:** the code that will run on the physical ESP32-C3. **⚠️ This is ~30% written
and has NEVER been compiled** — there was no ESP32 toolchain in the environment it was
authored in. Treat every file as a *reviewed design*, not working code. Your first
real step is `pio run` and fixing what the compiler flags.

Why leave it unfinished on purpose? Because the slow, expensive part of firmware is
the debug loop against real silicon, not the typing. Writing 2,000 more uncompilable
lines now would have a high defect rate and you'd pay the debug cost anyway. What's
here is the *architecture* plus the single trickiest piece (the encoder driver), so
the rest can be filled in file-by-file with a board on the desk.

```
mooks-firmware/
├── platformio.ini              build config: pinned libraries + 3 build profiles
├── include/
│   └── config.h                EVERY tunable in one place: pin map, thresholds, sizes
└── src/
    ├── core/
    │   └── EventBus.h          the architectural keystone: one message queue
    ├── data/
    │   └── Models.h            fixed-size data structs (no dynamic memory)
    ├── hal/                    "hardware abstraction layer" — talks to the physical parts
    │   ├── Encoder.h / .cpp    the knob driver (the one fully-written .cpp — it's the hard bit)
    │   └── Display.h           the screen driver (header only; .cpp not written)
    └── ui/
        └── Theme.h             mirror of the simulator's design system
```

**What each written file is:**

- **`platformio.ini`** — The build recipe. Pins exact library versions (so a future
  update can't silently break things) and defines three build profiles: `device`
  (real, with deep sleep), `bench` (verbose logging, sleep disabled, fake content —
  for debugging without the device vanishing), and `native` (host-side logic tests, no
  hardware needed).

- **`include/config.h`** — Every number that might need tuning, in one file: the pin
  map, screen settings, all the battery-voltage thresholds, timeouts, storage sizes,
  and the ranking weights. **Two rules in here matter even if you rewrite everything
  else:** (1) the encoder must not go on strapping pins GPIO2/8/9 or the device
  sometimes won't boot; (2) the knob's button must be on an RTC-capable pin (GPIO0–5)
  because only those can wake the chip from deep sleep.

- **`src/core/EventBus.h`** — The keystone of the whole architecture. One message queue
  that every part posts to and the UI reads from. This is what makes "the screen stays
  responsive while Wi-Fi is dying" possible: networking runs on its own task and only
  ever *posts a message*; it never touches the screen directly.

- **`src/data/Models.h`** — The on-device data types, as **fixed-size structs with no
  dynamic memory**. Two reasons: a secure (TLS) connection needs a large *contiguous*
  block of memory, which a fragmented heap can't provide after days of uptime; and
  fixed layout means the drawing code has no failure mode. Note there are no full
  sentences here — only pre-wrapped lines, because the server did the wrapping.

- **`src/hal/Encoder.h` / `Encoder.cpp`** — The knob driver, and the only fully-written
  `.cpp` because it's the fiddliest code in the project. It reads the encoder using
  interrupts and a 16-entry lookup table that *refuses to guess* on an impossible
  signal transition (which is what electrical noise looks like) — this is why cheap
  knobs feel like they "jump" and this one won't. It also implements the press vs
  long-press timing and sets up press-to-wake from deep sleep.

- **`src/hal/Display.h`** — The screen driver's interface (the `.cpp` is not written).
  Its drawing methods mirror the simulator's `FrameBuffer` exactly, so screens port
  across cleanly. **One honest caveat documented in the file:** the U8g2 library drives
  our greyscale panel as 1-bit (on/off), so the 16-level grey hierarchy the design
  relies on isn't there yet on that backend. Getting true greyscale means swapping to
  a different display library behind this same interface — a deliberate later task, not
  a blocker.

- **`src/ui/Theme.h`** — The firmware's copy of the design system (grey levels,
  coordinates, spacing), mirroring `Theme.swift` in the simulator so the device
  reproduces what you designed on the laptop.

**What is NOT written** (roughly 1,600–2,000 more lines): `Display.cpp`, the power/
sleep/battery code, Wi-Fi + the HTTPS API client + provisioning, the storage/cache
layer, the screen router and the per-screen implementations, the app wiring, and
`main.cpp`. See [`PROJECT-STATUS.md`](PROJECT-STATUS.md) for the full done/todo list.

---

## 8. How to run everything

Both desktop tools are **dependency-free** — no packages to install, no accounts, no
keys, no internet needed.

**The UI simulator** (needs Swift 5.9+):

```bash
cd mooks-sim
swift build
swift run mooks-render                 # render all screens + panels, print the report
swift run mooks-render --ascii 07       # dump screen 07 to the terminal as text
swift run mooks-render --ascii all      # dump every screen
swift run mooks-render --emit-vectors   # regenerate the content pipeline's golden file
node tools/optimize-png.mjs out         # shrink the PNGs before committing (needs Node)
```

Expected: `Build complete`, 16 screens written to `out/screens/`, and a report ending
with `All ... sample items fit`.

**The content pipeline** (needs Node 18+):

```bash
cd mooks-content
npm test          # 13 wrap-parity vectors — does JS match the Swift reference?
npm run validate  # check the authored content against the contract
npm run build     # produce the device-ready files in dist/
npm run ci        # all of the above, as the automation runs them
```

Expected: `13 passed, 0 failed`, `All content fits the panel`, `drops built  2`.

**The firmware** (needs PlatformIO + a real ESP32-C3 — will NOT fully compile yet):

```bash
cd mooks-firmware
pio run              # attempt a build; expect errors — files are missing (see §7)
```

---

## 9. Status, and suggested next steps

Full, line-by-line status is in [`PROJECT-STATUS.md`](PROJECT-STATUS.md). In brief:

| Part | Status |
|---|---|
| Design review | ✅ complete |
| UI design + simulator (16 screens) | ✅ works, verified |
| Content backend (validated pipeline) | ✅ works, verified |
| Real content (actual drops) | 🟡 2 sample days only |
| Firmware architecture | 🟡 ~30%, never compiled |
| Runnable firmware / Wi-Fi / power | ⬜ not started |
| SwiftUI demo app | ⬜ not started |
| Live backend deploy | ⬜ not started |
| Physical hardware | ⬜ not started |

**Suggested order from here:**

1. **Look at `mooks-sim/out/screens/6x/`.** If the interaction doesn't feel right
   there, no enclosure work will fix it. This is the cheapest place to iterate.
2. **Order parts** — shipping time is the real critical path, not code. The exact
   search strings are in the design review's procurement section.
3. **Decide dial vs crown** using the `panel-A/B/C` renders.
4. **Author ~30 days of real content** while waiting for parts. Content going stale is
   the project's #1 risk, and this is the cheapest time to build a buffer.
5. **Do the firmware last**, file-by-file, with a live `pio run` loop once the parts
   are on your desk. The hard part (the encoder) and the shape (event bus, models,
   config) are already there to copy from.

---

## Why this repo looks the way it does

A one-line summary for anyone reviewing it: **the software that could be finished and
proven on a laptop was finished and proven; the parts that need physical hardware were
designed carefully and left honestly labelled as unbuilt.** Building the simulator
even disproved three of the design review's own numeric claims before any money was
spent — which is the entire argument for doing design and simulation before hardware.
