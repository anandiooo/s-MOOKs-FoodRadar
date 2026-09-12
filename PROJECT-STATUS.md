================================================================================
 MOOKS — FOOD RADAR
 PROJECT STATUS & SPECIFICATION
================================================================================

 What this document is:
   1. The final recommended specification (what MOOKS should be).
   2. Exactly what has been implemented, and verified how.
   3. Exactly what has NOT been implemented, and why.
   4. What you have to build yourself, in order.

 How to read the status tags used throughout:

   [DONE]     Implemented and verified. Evidence is stated.
   [PARTIAL]  Started; specific gaps are named.
   [DESIGN]   Specified/written but NOT executed or compiled. A plan, not a fact.
   [TODO]     Not started. On you (or a later session).
   [DECISION] A choice you still have to make before building.

 Golden rule for this file: a claim is only [DONE] if it was run and observed.
 "I wrote code that should work" is [DESIGN], not [DONE]. This distinction is the
 whole point of the document.

 Last updated: 12 Sep 2026
 Repo: github.com/anandiooo/s-MOOKs-FoodRadar

================================================================================
 PART 0 — THE ONE-PARAGRAPH SUMMARY
================================================================================

 MOOKS is a tiny, battery-powered, single-knob device that shows you five food
 discoveries a day and then tells you it is finished. The DESIGN is complete and
 reviewed. The USER INTERFACE is fully implemented and rendered at true pixel size
 in a Swift simulator (works, verified). The CONTENT BACKEND is a fully working,
 tested, server-less pipeline (works, verified). The FIRMWARE that runs on the
 actual ESP32 is about 30% written as an architecture skeleton and has NEVER been
 compiled — it needs a real board and toolchain. No physical hardware has been
 built. So: the product is fully designed and its software halves are proven on a
 desktop; the embedded firmware and the physical object are the remaining work.

================================================================================
 PART 1 — FINAL RECOMMENDED SPECIFICATION (MOOKS V1)
================================================================================

 This is the target. Sourced from MOOKS-design-review.md §21; component
 dimensions and electrical facts were checked against manufacturer datasheets
 (citations live in the review). Anything marked [VERIFY] must be confirmed with
 calipers or a datasheet before you spend money.

 ---- IDENTITY ----------------------------------------------------------------
   Name .................. MOOKS
   Type .................. Physical food-discovery device / desk companion
   Promise ............... Five discoveries a day, then it stops.
   Tagline ............... "Five things. Then you're done."
   NOT ................... a feed, a smart speaker, a phone replacement, a toy

 ---- ENCLOSURE ---------------------------------------------------------------
   V1 shell .............. VBM-X1 PVC project box, 77 x 51 x 27 mm (off-shelf)
   V1 finish ............. matte graphite (wet-sand + matte clear, OR 3M vinyl wrap)
   Usable interior ....... ~72.6 x 46.6 x 22.6 mm  [EST, assumes 2.2mm wall — VERIFY]
   Front-panel window .... 62 x 36 mm usable "safe window"
   Front panel ........... 2 mm black CAST acrylic, back-masked, press-fit
   Internal chassis ...... 3D-printed PETG cartridge, routed wire channels
   Ballast ............... 60 x 35 x 2 mm steel/brass in base (~33 g)
   Target mass ........... 95-105 g  (density is the #1 perceived-quality signal)
   V2 target shell ....... 70 x 45 x 18 mm, custom (see note on crown below)

 ---- DISPLAY -----------------------------------------------------------------
   RECOMMENDED ........... 1.32" OLED, 128 x 96, SSD1327, 16-level greyscale, SPI
                           module 34.3 x 30.5 mm, active area 26.86 x 20.14 mm
   Why this one .......... smaller module than the 1.3", +50% pixels, greyscale
                           (greyscale is what makes typography read as "designed")
   FALLBACK / bench mule . the 1.3" 128x64 SH1106 you already own
   Interface fact ........ your 4-pin module is I2C @ 0x3C, NOT SPI as its listing
                           claims (4 pins cannot be SPI; SPI needs 6-7)

 ---- MCU ---------------------------------------------------------------------
   Board ................. ESP32-C3 SuperMini, 22.5 x 18 x 4.5 mm
   Connectivity .......... Wi-Fi 2.4 GHz (BLE available, unused in V1)
   MUST VERIFY ........... on-board LDO is ME6211-class, NOT AMS1117 (dropout kills
                           the battery plan if it's AMS1117)
   MUST MODIFY ........... desolder the power LED (saves 1-3 mA, > sleep budget);
                           no pin headers anywhere; >=10 mm metal-free antenna zone
   V2 .................... ESP32-C3-MINI-1 module on a custom PCB

 ---- INPUT (one control, three gestures) -------------------------------------
   Encoder ............... EC11 incremental, 15 mm shaft, ~20 detents, push switch
   Knob .................. ALUMINIUM, knurled, 16-18 mm dia, 6 mm D-shaft, set screw
                           (the only surface a user touches — do not cheap out)
   Filter ................ RC on each channel: 10k series + 100nF to GND
   Gestures .............. ROTATE = browse   PRESS = select/save   HOLD(500ms) = back
   Wake .................. press wakes from deep sleep (switch on RTC-capable GPIO)

 ---- POWER -------------------------------------------------------------------
   Cell .................. 3.7 V ~700 mAh, 603040 size, WITH integrated protection
   Charger ............... TP4057 (SOT23-6) @ ~350 mA from USB-C
   Power path ............ ONE Schottky (SS14) from battery to the board's 5V pin
                           -> runs while charging + clean charge termination
   Decoupling ............ 220 uF low-ESR + 10 uF ceramic at the board (MANDATORY —
                           without it Wi-Fi TX bursts brown-out and reboot the chip)
   Battery sense ......... 2x 1M divider + 100nF into an ADC1 pin
   Power switch .......... mini slide (SS-12D00), REAR face, service cutoff only
   Reported as ........... 4 states (Full/Good/Low/Critical) — NEVER a percentage
   V2 power .............. BQ25185 power-path + low-Iq buck + USB-C ESD protection

 ---- RUNTIME (all figures are ESTIMATES) -------------------------------------
   Deep sleep ............ ~50 uA  -> months (self-discharge limited)
   Browsing (radio off) .. ~33 mA  -> ~17 h continuous
   Per fetch ............. ~0.13 mAh
   Typical use ........... ~3.5 mAh/day -> charge roughly once a month
   Charge time ........... ~2.5 h @ 350 mA
   (These hold ONLY if deep sleep, LED removal, and radio-off-between-fetches are
    all actually implemented. Skip any one and you're at ~6 h.)

 ---- CONNECTIVITY & PROVISIONING ---------------------------------------------
   Wi-Fi ................. 2.4 GHz, HTTPS with a pinned root CA (not setInsecure)
   Setup ................. SoftAP "MOOKS-setup" + captive portal, joined by
                           scanning a QR code shown on the OLED (no app, no keyboard)
   NFC ................... passive NTAG213 under rear label -> setup URL (optional)

 ---- BACKEND -----------------------------------------------------------------
   V1 .................... authored JSON -> CI validates & builds -> static files on
                           a CDN. NO SERVER. Device does one conditional GET.
   Conditional GET ....... If-None-Match; the common path is a ~400-byte 304
   Cache ................. NVS (creds, saves, tag affinity) + LittleFS (last 2 drops)
   Ranking ............... editorial - 8*seen + 3*tag_affinity - 40*saved. No ML.
   Content shape ......... exactly 5 items/day, one city, hard end-state

 ---- UX ----------------------------------------------------------------------
   IA .................... boot straight into TODAY (5 cards). No root menu.
                           Long-press opens MENU: Saved / Nearby / Wi-Fi / About.
   Loop .................. pick up -> press -> browse 5 -> open one -> save ->
                           "That's all for today." -> put down -> return tomorrow
   Handoff ............... QR on screen -> short link -> Maps/recipe on the phone
                           (this is the answer to "why not just use my phone?")
   Type hierarchy ........ by GREY LEVEL: label 40% / body 75% / title 100%,
                           left-aligned, one accent per screen, one card per screen

 ---- CORE PROMISE ------------------------------------------------------------
   Your phone is built to never let you finish. MOOKS is built to let you finish.
   It shows five things, hands the best one to your phone, and says it's done.

================================================================================
 PART 2 — WHAT IS IMPLEMENTED  (and how it was verified)
================================================================================

 Three code artefacts exist. Two run and are verified. One is a skeleton.

--------------------------------------------------------------------------------
 2A. THE DESIGN REVIEW                                                   [DONE]
--------------------------------------------------------------------------------
   File:     MOOKS-design-review.md   (1,489 lines)
   Contains: 21 sections + an appendix answering 30 specific engineering
             questions. Executive verdict, physical-feasibility maths,
             component-by-component keep/replace/remove, exact target
             dimensions, ASCII layouts, power architecture, battery-life
             estimates, provisioning, firmware & backend architecture, UX/IA,
             industrial design, differentiation, V1/V1.5/V2 split, risk
             register, build order, procurement list, test plan, and Apple
             Developer Academy framing.
   Verified: it's a document; "done" means complete and self-consistent.

--------------------------------------------------------------------------------
 2B. UI SIMULATOR  (mooks-sim/)  — Swift, zero dependencies             [DONE]
--------------------------------------------------------------------------------
   What it is:
     A pure-Swift program that draws every MOOKS screen into a 128 x 96 4-bit
     greyscale framebuffer — the exact geometry of the recommended panel — and
     exports PNGs. It is the design tool, and the MooksUI module is written so a
     SwiftUI app can import it later to become the interactive/demo simulator.

   Files (1,523 lines of Swift + a 97-line PNG-shrink tool):
     Package.swift ................ library + CLI targets
     Sources/MooksUI/
       Font5x7.swift .............. 5x7 ASCII bitmap font (0x20-0x7E)
       FrameBuffer.swift .......... framebuffer + all draw primitives + PNG-able
       PNG.swift .................. dependency-free PNG writer
       Theme.swift ................ the design system (grey levels, geometry, wrap)
       Model.swift ................ Item / Drop / Trend + sample content
       Screens.swift .............. all screen layouts (the actual UI)
       Panel.swift ................ front-panel proportion drawings (dial vs crown)
     Sources/mooks-render/main.swift  the CLI + the report it prints
     tools/optimize-png.mjs ....... shrinks the emitted PNGs ~99% for the repo

   Screens implemented (16), rendered to mooks-sim/out/screens/{1x,6x}/:
     01 boot .............. wordmark, the only time it appears on screen
     02 first-run ......... no creds / no cache, sets the promise
     02b how-to .......... one-time gesture teaching (turn/press/hold)
     03 today-1 ........... card 1/5, dish with a sourced trend number
     04 today-2 ........... card 2/5, oddity, direction word (no number)
     05 today-3 ........... card 3/5, a place, steady
     06 today-offline ..... cached drop, offline mark, "yesterday's picks"
     07 detail ............ the payoff sentence, "> save"
     08 detail-place ...... detail variant for a place
     09 saved-confirm ..... "Saved. N kept"
     10 handoff ........... the QR-to-phone screen
     11 end-of-day ........ "That's all for today." — the anti-feed screen
     12 menu .............. behind the long-press
     13 saved-list ........ the saved destination
     14 setup-wifi ........ SoftAP QR provisioning screen
     15 low-battery ....... calm, once, dismissable, no percentage
     (QR screens use a PLACEHOLDER symbol of correct geometry — see Part 3.)

   Also renders 3 front-panel proportion studies:
     panel-A-dial-77x51 ... front-mounted knob (your original layout)
     panel-B-crown-77x51 .. side crown, display centred
     panel-C-crown-62x42 .. the V2 shell, for comparison

   HOW VERIFIED:
     - `swift build` -> Build complete.
     - `swift run mooks-render` -> ran, wrote 16 screens x2 scales + 3 panels.
     - PNGs opened and inspected pixel-by-pixel (not just "the file exists").
     - `swift run mooks-render --emit-vectors` produces the golden file the
       content pipeline tests against.

   WHAT BUILDING IT PROVED (three of the review's own claims were WRONG):
     1. Text capacity: review guessed why<=96 chars; MEASURED limit is 60.
        Limits are computed against a fixed-width font so a proportional font on
        the real device can only ever give MORE room, never break a layout.
     2. Detail footer collided: "Kopi Nako"(52px) + "press to save"(76px) = 128px
        in a 120px column. Fixed to a 31px "> save". Caught by rendering, not
        by reading the layout.
     3. Font bug: the classic 5x7 'u' glyph reads as 'v' at 2x ("Tiramisv").
        Squared off.
     Plus two measurements:
     4. Screen-to-face ratio: 13.8% on the 77x51 shell (a phone is ~85%), 20.8%
        on a 62x42 shell. Shrinking the shell makes a FRONT dial impossible, so
        the side crown is what unlocks the smaller device. This is a hard
        dependency, now shown visually rather than asserted.
     5. Average lit pixels across all screens = 8.0% — evidence that the dark
        aesthetic IS the battery strategy.

--------------------------------------------------------------------------------
 2C. CONTENT PIPELINE  (mooks-content/) — Node, zero dependencies       [DONE]
--------------------------------------------------------------------------------
   What it is:
     The entire V1 backend. Authored drops go in; validated static JSON comes
     out. There is no server and nothing to keep alive — you publish dist/ to
     any CDN with ETag support and point the firmware at /v1/manifest.json.

   Files (~680 lines):
     contract.json .............. SINGLE SOURCE OF TRUTH for display limits
     content/2026-09-12.json .... sample authored drop (Jakarta, 5 items)
     content/2026-09-13.json .... a second sample drop
     scripts/lib/wrap.mjs ....... JS mirror of the Swift wrap algorithm
     scripts/validate.mjs ....... the content validator (fails the build on error)
     scripts/build.mjs .......... pre-wraps text into lines, emits manifest+drops+links
     test/wrap.test.mjs ......... asserts JS wrap == Swift reference
     test/wrap-vectors.json ..... the golden file (generated by the simulator)
     package.json ............... npm test / validate / build / ci
     (.github/workflows/content.yml lives at the REPO ROOT, not here — GitHub
      only runs workflows from the root. It runs the test, validate, and build.)

   Key design idea (this is what makes the firmware simpler):
     The BUILD pre-wraps every string into display lines. The device receives
     titleLines / hookLines / whyLines — not sentences. So the firmware carries
     NO word-wrap code and CANNOT break its own layout. Server edits, device draws.

   What the validator enforces:
     - exactly 5 items per drop (finiteness is enforced, not just intended)
     - title/hook/why/place fit the panel (measured limits from contract.json)
     - ASCII only — the panel font has no glyph outside 0x20-0x7E, and non-ASCII
       renders as NOTHING, silently (the review's own "Cafes" label was a trap)
     - a numeric trend MUST cite a source, or you use a direction word instead
     - unique ids and link codes; link codes <=4 chars (keeps the QR readable)

   HOW VERIFIED:
     - `npm test`     -> 13/13 wrap-parity vectors pass (JS agrees with Swift).
     - `npm run validate` on good content -> passes.
     - A deliberately-broken fixture -> produced 13 distinct errors, exit code 1,
       then was deleted. (A validator that has never failed is untested.)
     - `npm run build` -> largest drop 1,508 bytes, manifest 399 bytes,
       10 short links. Confirms the 304-first fetch strategy is realistic.

================================================================================
 PART 3 — WHAT IS NOT IMPLEMENTED  (and why)
================================================================================

--------------------------------------------------------------------------------
 3A. FIRMWARE — the code that runs on the actual ESP32          [PARTIAL / ~30%]
--------------------------------------------------------------------------------
   *** THIS HAS NEVER BEEN COMPILED. *** No ESP32 toolchain existed in the
   environment it was written in. Treat every file as a reviewed DESIGN, not as
   working code. Your first real step is `pio run` and fixing what falls out.

   WRITTEN (586 lines) — architecture + the two hardest-to-get-right pieces:
     platformio.ini ............. [DESIGN] pinned deps, 3 build envs
     include/config.h ........... [DESIGN] pin map, all thresholds, the reasoning
     src/core/EventBus.h ........ [DESIGN] the one-queue architecture keystone
     src/data/Models.h .......... [DESIGN] fixed-size PODs, no heap after boot
     src/hal/Encoder.{h,cpp} .... [DESIGN] ISR quadrature + long-press FSM (the
                                  one .cpp that exists, because it's the fiddly bit)
     src/hal/Display.h .......... [DESIGN] header only — I stopped here
     src/ui/Theme.h ............. [DESIGN] mirror of the simulator's design system

   NOT WRITTEN AT ALL — you need all of these to have a running device:
     src/hal/Display.cpp ........ [TODO] the U8g2 draw implementation
     src/hal/Power.{h,cpp} ...... [TODO] sleep/wake, battery ADC, the state ladder
     src/hal/Battery.{h,cpp} .... [TODO] ADC median read -> 4 states
     src/net/WifiService.* ...... [TODO] connect/retry/backoff, NVS creds
     src/net/ApiClient.* ........ [TODO] HTTPS GET + ETag + streaming JSON parse
     src/net/Provisioning.* ..... [TODO] SoftAP + captive portal + QR payload
     src/data/Store.{h,cpp} ..... [TODO] NVS: creds, 30 saves, tag affinity
     src/data/Cache.{h,cpp} ..... [TODO] LittleFS: last 2 drops
     src/ui/Screen.h + Router ... [TODO] screen stack + transitions
     src/ui/screens/*.cpp ....... [TODO] port each screen from Screens.swift
     src/app/App.{h,cpp} ........ [TODO] wire events -> state -> router
     src/main.cpp ............... [TODO] init, spawn tasks, loop()
   Estimated remaining: ~1,600-2,000 lines.

   Additional firmware-level gaps even in what's written:
     - Greyscale: U8g2 drives the SSD1327 as 1 bit/pixel, so the 16-grey
       hierarchy the design depends on is NOT there on that backend (greys get
       thresholded at >=8). True greyscale = swap to Adafruit_SSD1327 or LVGL
       behind the same Display API. Deliberate V1.5 task, not a V1 blocker.
     - QR generation: the simulator draws a geometry PLACEHOLDER, not a real
       symbol. Firmware needs a real QR encoder (e.g. ricmoo/QRCode) for both
       the Wi-Fi setup screen and the handoff screen.

   WHY it was left here: the bottleneck for firmware is the debug loop against
   real silicon, not the typing. Writing 2,000 uncompilable lines now would have
   a high defect rate and you'd pay the debug cost anyway. Do it file-by-file
   with a live `pio run` once parts arrive. The hard part (the encoder driver)
   and the shape (event bus, models, config) are already done to copy from.

--------------------------------------------------------------------------------
 3B. SwiftUI INTERACTIVE SIMULATOR / DEMO APP                          [TODO]
--------------------------------------------------------------------------------
   [DESIGN] Recommended in review §20. Would import the existing MooksUI module,
   add a draggable knob, and render the UI at 4x on macOS/iPadOS. Value: a faster
   design loop, demo insurance if the hardware dies in an interview, and the only
   Swift in an otherwise-Swift-less portfolio. NOT built. The groundwork (MooksUI
   being platform-independent) is deliberately in place so this is additive.

--------------------------------------------------------------------------------
 3C. BACKEND BEYOND V1                                                 [TODO]
--------------------------------------------------------------------------------
   [DONE]  V1 static pipeline (Part 2C).
   [TODO]  Live CDN deploy (the workflow has a commented-out Cloudflare step).
   [TODO]  V1.5 dynamic API (/drop, /item, /saves, /link, /fw) — a Worker/FastAPI.
   [TODO]  The link redirector as a live route (currently a static links.json).
   [TODO]  Real trend signals, personalisation, OTA. All explicitly V2.
   [TODO]  Real content — only 2 sample days exist. Content decay is risk #1;
           you want ~30 days authored before any demo.

--------------------------------------------------------------------------------
 3D. PHYSICAL HARDWARE                                                 [TODO]
--------------------------------------------------------------------------------
   NOTHING physical exists. Not started (correctly — software/design first).
     [TODO] buy parts (review §18 has exact search strings)
     [TODO] bench mule, power measurements, Wi-Fi range test
     [TODO] 3D-printed chassis, laser-cut acrylic front panel
     [TODO] assembly, the ballast plate, the aluminium knob
     [TODO] user testing (8 people) + iteration
     [TODO] product photos + case study + story

================================================================================
 PART 4 — OPEN DECISIONS (you must choose before building)
================================================================================
   [DECISION] Dial vs Crown input layout.
              Dial = easier V1 build. Crown = required for the smaller V2 and
              a cleaner face. See panel-A/B/C renders. Recommendation: build
              Option A (dial) for V1, plan the crown for V2.
   [DECISION] Display: build the mule on the 1.3" you own now, but order the
              1.32" SSD1327 in parallel for the real build? (Recommended: yes.)
   [DECISION] Keep the daily content cron enabled? It will fail on stale sample
              content until you either author real drops or disable the schedule.
   [DECISION] Device name. "mook" is mildly derogatory US slang but also means a
              magazine-book hybrid — which is exactly this product. Own the
              second meaning, or reconsider. (See review §14.)

================================================================================
 PART 5 — BUILD ORDER (dependency order, not dates)
================================================================================
   Fuller version with exit tests in review §17. Short form:

   S0  Paper-prototype the screens with 3 people          [TODO]
   S1  Bench mule: C3 + OLED, identify the controller,    [TODO]
       measure Wi-Fi range and the enclosure walls
   S2  THE WHOLE UI on the bench with fake data           [TODO]  <- spend most time here
       (port Screens.swift -> firmware; it's the product)
   S3  Content + network + cache + offline mode           [PARTIAL: content done]
   S4  Wi-Fi provisioning (SoftAP + captive portal + QR)  [TODO]
   S5  Power: battery, charger, Schottky, sleep, measure  [TODO]
   S6  Mechanical: chassis, acrylic, ballast, knob        [TODO]
   S7  Polish: timeouts, transitions, burn-in, toasts     [TODO]
   S8  User testing, 8 people                             [TODO]
   S9  Iterate the top 3 frictions, re-test               [TODO]
   S10 Story: photos, exploded render, case study, app    [TODO]

   Hard rules: S2 before S6 (experience before enclosure). S5 before S6
   (electrical truth before geometry). S8 before S9, never in deadline week.

================================================================================
 PART 6 — STATUS AT A GLANCE
================================================================================
   Design review ................................ [DONE]      100%
   UI design (16 screens, rendered & verified) ... [DONE]      100%
   UI simulator (Swift, runs) .................... [DONE]      100%
   Content backend V1 (validated pipeline) ....... [DONE]      100%
   Content itself (real drops) ................... [PARTIAL]   ~5% (2 sample days)
   Firmware architecture ......................... [PARTIAL]   ~30%, uncompiled
   Firmware, runnable on a board ................. [TODO]      0%
   Wi-Fi / provisioning firmware ................. [TODO]      0%
   Power firmware + measurements ................. [TODO]      0%
   SwiftUI demo app .............................. [TODO]      0%
   Live backend deploy ........................... [TODO]      0%
   Physical hardware ............................. [TODO]      0%
   User testing & iteration ...................... [TODO]      0%

   Bottom line: everything that can be proven on a desktop is proven. The
   remaining work is the embedded firmware (needs a board) and the physical
   build (needs parts). The design de-risks both, and the two working tools
   mean the UI and the content are settled before you spend a cent.

================================================================================
 VERIFICATION APPENDIX — commands you can run to check these claims
================================================================================
   cd mooks-sim     && swift build && swift run mooks-render
       -> "Build complete", renders 16 screens + 3 panels, prints the report
   cd mooks-content && npm run ci
       -> "13 passed", "All content fits the panel", "drops built  2"
   Both are dependency-free: no packages, no accounts, no network, no keys.

   Every [DONE] above was produced by running one of these. Every [DESIGN] was
   written but not run. That line is the honest boundary of this project today.
================================================================================
