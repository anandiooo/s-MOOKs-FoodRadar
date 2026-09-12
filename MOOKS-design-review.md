# MOOKS — Master Design Review & Improvement Plan

Review type: early-stage product review + engineering design review
Reviewed: concept, ID, electronics, firmware, backend, UX, project scope
Date: 12 Sep 2026

> **How to read this.** Everything marked **[VERIFY]** is something you must measure with calipers or confirm from a datasheet before committing money. Everything marked **[EST]** is an engineering estimate, not a measurement. I have cited sources for the component dimensions I looked up; the enclosure interior is estimated because "BOX MULTI VBM-X1" has no published drawing I could find.

---

## 1. EXECUTIVE VERDICT

### Is the concept good?

The **interaction** is good. The **content model** is where the project will live or die, and right now it is the weakest part of the document — it is one line ("still conceptual") supporting the entire product.

Blunt version: a rotary knob that shows curated food cards is a lovely object. But as specified, MOOKS is a *worse feed than your phone* — fewer items, no images worth the name, no video, stale data, and one more thing to charge. If you frame MOOKS as "TikTok food discovery, but physical," you lose that comparison every single time, in front of every reviewer.

The concept becomes defensible the moment you invert it:

> **MOOKS is not a smaller feed. It is a finite one.**
> Five discoveries a day. When you've seen them, it says so and stops. Then it hands the winner to your phone and gets out of the way.

That single reframe fixes four problems at once: it kills the phone comparison (the phone is infinite, MOOKS is *done*), it makes daily curation feasible for one student, it creates a return ritual, and it turns the hardware's limitation (tiny mono screen, no video) into the point rather than the apology.

### Is X1 viable?

**Yes — and that is a problem, because it is viable with far too much room to spare.** Your components occupy roughly 25 cm³. The enclosure is 106 cm³. You have not chosen a case that is too small; you have chosen one that is too big and too hollow, which is exactly how a device ends up feeling like a project box instead of a product. Perceived quality tracks density. Rough numbers:

| Object | Volume | Mass | Density |
|---|---|---|---|
| AirPods Pro case | ~59 cm³ | ~51 g | **0.86 g/cm³** |
| MOOKS X1 as specified **[EST]** | 106 cm³ | ~70 g | **0.66 g/cm³** |
| MOOKS X1 with ballast plate **[EST]** | 106 cm³ | ~100 g | **0.94 g/cm³** |

So: build in X1, but add mass deliberately, and target a genuinely smaller shell for the final version.

### Biggest strengths

1. **One control, three gestures.** Rotate / press / long-press is a complete and honest input vocabulary. Do not add a second button. This is the best decision in the whole brief.
2. **The scope discipline is real.** Your non-goals list is better than most professional PRDs. Keep it.
3. **Hardware risk is genuinely low.** ESP32-C3 + I²C OLED + encoder + LiPo is the most-travelled path in hobby electronics. Nothing here can fail in a way you can't Google.
4. **The physical object is a portfolio multiplier.** Most Academy applicants bring screenshots. You can put something on the table.

### Biggest risks (ranked by what will actually kill this)

1. **Content decay — near-certain, fatal.** Two weeks after your demo, nobody has updated the JSON, and MOOKS shows stale matcha. Every single-purpose content device dies this way. *Mitigation: the content pipeline is a first-class deliverable, not an afterthought. See §10.*
2. **"Why not just use my phone?" — you have no answer yet.** *Mitigation: finiteness + QR handoff. See §12 and §14.*
3. **The hollow-box tell.** Visible screws, a 2.54 mm pin header, hot glue, a display floating in an oversized cutout. Any one of these and it reads as a hobby build regardless of how good the firmware is. *Mitigation: §13.*
4. **Under-designed power path.** As drawn (charger → battery → ESP32, with a load on the charger output), you get corrupted charge termination and a brownout risk at low battery. Fixable with one diode. *See §6.*
5. **Building the box before the experience.** If you drill the enclosure in week one, your UI will be shaped by your cutouts. *Mitigation: build order in §17.*

---

## 2. PHYSICAL FEASIBILITY

### 2.1 Usable interior **[EST]**

Injection-moulded plastic project boxes of this class use 1.8–2.5 mm walls. Assume **2.2 mm** until you measure.

```
External              77.0 × 51.0 × 27.0 mm      = 106 cm³
− walls (2 × 2.2)     72.6 × 46.6 × 22.6 mm      =  76 cm³   gross interior
− corner bosses       Ø6–7 mm at all four corners
− lid lip/step        1–2 mm around the perimeter
```

The number that actually governs your design is not interior volume — it is the **front-panel safe window**: the largest rectangle you can cut without hitting a wall radius or a screw boss.

```
Front face safe window  ≈ 62 × 36 mm      [VERIFY]
   (72.6 − 2 × 4 mm edge margin  ×  46.6 − 2 × 5 mm boss/lip margin)
Usable internal depth   ≈ 22.6 mm total, split by the lid seam
```

**Everything below is judged against 62 × 36 mm and 22.6 mm, not 77 × 51 × 27.**

### 2.2 Component-by-component fit

| Component | Footprint | Fits in 62 × 36? | Verdict |
|---|---|---|---|
| 1.3" OLED module | 35.5 × 33.7 mm | Yes, 33.7 vs 36 → **2.3 mm total vertical margin** | **Marginal.** Vertically you have ~1 mm per side. Any cutting error is visible. |
| ESP32-C3 SuperMini | 22.5 × 18.0 × 4.5 mm | N/A (internal) | Fine |
| EC11 encoder body | 12.4 × 12.4 mm, ~6.5 mm tall behind panel | Needs ~26 mm of width incl. knob | Fits *only* because the OLED leaves 26.5 mm |
| LiPo 500 mAh (503035) | 5 × 30 × 35 mm | N/A (internal) | Fits easily |
| TP4057 module | ~17 × 11 mm typical | N/A | Fine |
| Slide switch as spec'd | 23.3 × 7.5 × **12 mm** | — | **Reject.** 12 mm is half your depth budget. |

### 2.3 The collision you actually have

Front face, horizontal axis, 62 mm to spend:

```
[4mm margin][ OLED module 35.5 ][ gap ][ knob Ø16 ][4mm margin]
              35.5            +   2   +    16      = 53.5 mm  → fits in 62 ✓
```

It fits. But look at what it looks like. The 1.3" module's **visible pixels are only 29.42 × 14.70 mm** — the rest of that 35.5 × 33.7 mm board is bare FR4. So the front of your device is a 30 × 15 mm letterbox of light sitting inside a 62 × 36 mm face, next to a knob, with 21 mm of dead PCB above and below the image.

**That is the real problem with the current display: not that it doesn't fit, but that 64% of its footprint is invisible.**

The good news: dead PCB you cannot see does not exist. A custom front panel (§13) hides it entirely. So the fill ratio problem is solved with 2 mm of acrylic, not with a different display — *unless* you want more pixels, which you do (see §3.1).

### 2.4 Depth stack — the constraint you haven't checked

This is where builds like this actually fail:

```
Rear shell inner face
├─ 2.0 mm   steel/brass ballast plate (recommended, §13)
├─ 4.5 mm   ESP32-C3 SuperMini (board 1.2 + USB-C shell ~3.2)
├─ 1.0 mm   Kapton isolation
├─ 6.0 mm   LiPo cell (503035 = 5 mm + swell allowance)
├─ 1.5 mm   wiring channel / slack
├─ 5.0 mm   OLED module (glass 1.45 + PCB 1.2 + tape + solder)
├─ 2.0 mm   acrylic front panel
└──────────
   22.0 mm   vs 22.6 mm available  →  0.6 mm margin  ⚠
```

**Hard buildability rules that fall out of this:**

- **Do not solder the 4-pin header onto the OLED.** A 2.54 mm header is 11.5 mm tall. It alone blows the entire budget. Solder 30 AWG silicone wire flat to the pads and run it sideways.
- **Do not solder headers onto the C3 SuperMini either.** Wire directly to the pads.
- **No hot glue.** It adds 1–2 mm of unpredictable lumps and is the single most recognisable signature of a hobby build.
- Budget **1 mm of swell allowance** on the LiPo. Cells get thicker with age. A cell pressed between a screw boss and a PCB is a fire risk, not a packaging win.

### 2.5 Impossible / near-impossible combinations

| Combination | Verdict |
|---|---|
| 2.42" 128×64 OLED + this enclosure | **Impossible.** The bare COG module is 77.2 × 42.14 mm — wider than your entire external shell ([Raystar REH012864H](https://www.raystar-optronics.com/oled-graphic-display-module/REH012864H.html)). Beautiful display (55.01 × 27.49 mm active), wrong box. |
| 1.54" 128×64 (42.4 × 38.0 mm module) + front-mounted encoder | **Effectively impossible.** 42.4 mm leaves 19.6 mm for a knob inside a 62 mm window, and 38.0 mm exceeds your 36 mm vertical safe window. Only viable with a side-mounted crown. ([Raystar REA012864A](https://www.raystar-optronics.com/oled-graphic-display-module/REA012864A.html)) |
| 1.3" OLED + EC11 + 2.54 mm headers | **Impossible.** See §2.4. |
| Spec'd 23.3 × 7.5 × 12 mm slide switch | **Impossible** in a 22.6 mm stack alongside anything else. |
| 550 mAh in this box | **Trivially possible.** You're being too conservative — a 603450 cell (~1000 mAh, 6 × 34 × 50 mm) also fits. Capacity is not your constraint. |

---

## 3. RECOMMENDED HARDWARE: CURRENT → RECOMMENDED

### 3.1 Display — **REPLACE (for the polished build), KEEP (for the mule)**

**First, your interface question, answered directly.**

Your module is **almost certainly I²C, not SPI.** The listing is wrong. Reasoning:

- 4 pins on a 128×64 OLED = GND, VCC, SCL, SDA. There is no possible 4-wire SPI variant, because 4-wire SPI needs CS + DC + CLK + DIN + RES + VCC + GND = 7 pins. Even 3-wire SPI needs 6.
- Sellers copy-paste "SPI LCD LED" into titles as keyword spam. Pin count is physics; the title is marketing.

**Controller:** for a 1.3" 128×64 module, **SH1106 is the most likely** (it dominates that size), with SSD1306 and SSD1315 as alternates. This matters because SH1106 has 132 columns of RAM driving 128 columns of glass, so an SSD1306 driver renders shifted 2 px right and wrapped. U8g2 handles both — just pick the right constructor.

**How to identify it yourself, in order of effort:**

1. **Count the pins.** 4 = I²C. 6–7 = SPI. Done.
2. **Read the silkscreen.** `SDA/SCL` = I²C. `D0/D1/DC/CS/RES` = SPI.
3. **Look at the back for 0 Ω jumpers or solder bridges** — dual-mode modules select interface here (often labelled `IIC`/`SPI` or `BS0/BS1/BS2`).
4. **I²C scan.** Address `0x3C` (occasionally `0x3D`) responds → I²C confirmed.
5. **Distinguish SH1106 from SSD1306 empirically:** draw a 1 px vertical line at x=0 with an SSD1306 driver. If it lands 2 px in, or the right edge wraps, it's an SH1106.

**Is 1.3" right for MOOKS?** For fit, yes. For the product you're describing, no — and here is the swap that I think matters more than any other change in this document:

> **Recommended: 1.32" 128×96, SSD1327, 16-level greyscale.**
> Module **34.30 × 30.50 mm**, active area **26.86 × 20.14 mm**, SPI/I²C, 7-pin GH1.25 connector ([Waveshare 1.32inch OLED Module](https://www.waveshare.com/1.32inch-oled-module.htm)).

Why this is strictly better for you:

| | Current 1.3" 128×64 | Recommended 1.32" 128×96 SSD1327 |
|---|---|---|
| Module footprint | 35.5 × 33.7 mm | **34.3 × 30.5 mm — smaller** |
| Active area | 29.42 × 14.70 mm | **26.86 × 20.14 mm — 25% more area, far better shape** |
| Pixels | 8,192 | **12,288 (+50%)** |
| Greyscale | 1-bit | **4-bit, 16 levels** |
| Aspect | 2.0:1 letterbox | 1.33:1 — a *card*, not a ticker |
| Connector | soldered header | JST GH1.25 flex lead — thinner stack, no header problem |

Greyscale is the reason. Your entire design language is "minimal, premium, typographic." On 1-bit mono, type is jagged and hierarchy has to come from size alone. With 16 greys you get anti-aliased-looking text, dimmed secondary labels, dithered imagery, and real fades — the difference between "Arduino project" and "designed object" on a screen this small. It costs a few dollars and 8 KB of framebuffer (128 × 96 × 4 bit = 6 KB; trivial on the C3's ~400 KB SRAM). U8g2 supports SSD1327.

Also note: **1.32" is physically smaller than what you have.** You gain pixels, greyscale, and a better aspect ratio while *shrinking* the front footprint. That is a rare free win.

**Rejected alternatives, with reasons:**

| Option | Rejected because |
|---|---|
| 0.96" 128×64 | Active area ~21.7 × 10.9 mm. Too small to be read at arm's length; makes the device feel like a keychain. |
| 0.91" 128×32 | Two lines of text. Not enough for a card UI. |
| 1.54" 128×64 | Module 42.4 × 38.0 mm exceeds your 36 mm vertical safe window. Great display, needs a different box. |
| 2.42" 128×64 | Module is wider than your enclosure. |
| 1.5" 128×128 SSD1327 | Module 44.5 × 37 mm ([Waveshare](https://www.waveshare.com/wiki/1.5inch_OLED_Module)) — doesn't fit the safe window. Would be the pick for a slightly larger V2 shell. |
| Any colour TFT | Wrong. Backlit LCD in a dark bezel = visible grey rectangle when off. Emissive OLED on black is the entire aesthetic. Also 5–10× the power. |

**Recommendation:** build the mule on the 1.3" you already have (it works, U8g2 supports it, don't wait for shipping). Order the 1.32" SSD1327 now, in parallel, for the real build.

### 3.2 MCU — **KEEP, with three things to verify and one to modify**

ESP32-C3 SuperMini is the right call: 22.5 × 18 mm, native USB (no USB-serial chip burning idle current), Wi-Fi, enough RAM for TLS. Keep it for V1.

You were right to warn against assuming board equivalence. Specifically **[VERIFY]** on your actual board:

1. **The LDO part number.** Reference SuperMini boards use an **ME6211** 3.3 V low-dropout regulator, and suppliers state the `5V` pin accepts roughly 3.3–6 V ([Arduino Forum discussion](https://forum.arduino.cc/t/charging-lithium-ion-battery-using-the-usb-port-on-esp32-c3-supermini-with-tp4056-and-powering-the-esp32-with-the-battery-when-not-connected-via-usb/1302012/9)). This is what makes battery-into-`5V` viable. **If your clone has an AMS1117 instead (1.1 V dropout), the whole power plan collapses** — you'd brown out below ~4.4 V. Read the marking on the SOT-23-5 next to the USB connector under magnification.
2. **Whether `5V` is tied straight to VBUS or through a diode.** Determines whether you need your own blocking diode (you do — §6) and whether back-feeding is safe.
3. **The power LED.** Deep-sleep current on this board is reported around **43 µA, but only after removing the power LED** ([mischianti.org pinout & specs](https://mischianti.org/esp32-c3-super-mini-high-resolution-pinout-datasheet-and-specs/)); active current with no peripherals is around 26.8 mA. Desolder the POW LED. It is a 1–3 mA parasitic that will dominate your standby budget. This also answers §3.8: you already have an LED, and you should remove it.
4. **Antenna performance.** The SuperMini's compact on-board antenna is widely reported as its weak point. Test at your actual usage distance early (S1 in §17), and never mount the antenna end against the ballast plate or any metal. Keep a ≥10 mm metal-free keep-out around the antenna end of the board — this is a real mechanical constraint on your layout, not a footnote.

**ADC note:** on ESP32-C3, use **ADC1 channels (GPIO0–GPIO4)** for battery sensing. ADC2 is unusable when Wi-Fi is active.

**V2:** drop the dev board, put an **ESP32-C3-MINI-1** module on your own PCB with a proper PCB antenna keep-out. Saves ~4 mm of stack height and removes the USB-C connector height problem.

### 3.3 Encoder — **KEEP the EC11, REPLACE the knob, RECONSIDER the location**

EC11 is an 11 mm incremental encoder — your read is correct, it is not a digital potentiometer. Typical specs: 15 or 20 pulses/rev, 20–30 detents, integrated push switch, switch rated ~10 mA / 5 V DC, ~15,000-cycle switch life ([ALPS EC11 datasheet, Mouser](https://www.mouser.com/datasheet/2/15/EC11-1370808.pdf)).

**Is it too large? No.** Body 12.4 × 12.4 mm, sitting ~6.5–7 mm behind the panel plus ~3 mm of terminals. In a 22.6 mm depth budget with the panel-mounted bushing taking the load, it's fine. It fits the width too (§2.3). **Keep it** — going to an exotic low-profile encoder costs you detent quality, and detent quality *is* your product's feel.

Two things to change:

**(a) The knob is not an accessory, it is the product.** It is the only part the user's fingers ever touch. Specify: **aluminium, knurled, 16–18 mm diameter, 14–16 mm tall, 6 mm D-shaft with a set screw**, matte black anodised or raw brushed. Budget more for the knob than for the MCU and feel no guilt. A plastic knob on an otherwise perfect build destroys the entire impression in the first half-second of handling.

**(b) Shaft length.** Order the **15 mm shaft** variant, not 20 mm. With a 20 mm shaft you'll have an unsightly gap between knob and panel or a knob that towers over the face.

**Mounting — pick one:**

- **Option A — "Dial" (front-right, recommended for V1).** Lower risk, easier alignment, natural rotate-to-scroll mapping. What you already drew.
- **Option B — "Crown" (right-side edge, recommended for the final).** Frees the *entire* front face for display and negative space — which is what makes it look designed rather than assembled. Costs you a 3D-printed bracket and a precisely located 7 mm hole in a side wall. If you build only one device, do Option A and put the saved effort into the front panel.

Either way: **RC-filter the encoder** — 10 kΩ series + 100 nF to ground on each of A and B, at the encoder. Roughly $0.02 and it removes most of the phantom-step problem before you write a line of debounce code.

### 3.4 Battery — **REPLACE the target with a bigger, protected cell**

Your instinct ("thinness over capacity") is right in general and wrong here, because you have 22.6 mm of depth and are only using 5 of it.

| | Current | Recommended |
|---|---|---|
| Capacity | 400–550 mAh | **600–800 mAh** |
| Cell | unspecified | **603040** (6 × 30 × 40 mm, ~700 mAh) or **503035** (5 × 30 × 35 mm, ~500 mAh) if you want margin |
| Protection | "charger/protection board" | **Cell with integrated PCM (protection circuit module) on the tab** — non-negotiable |
| Connector | bare wires | **JST-PH 2.0 mm**, so you can disconnect the cell during assembly |

**Buy a protected cell.** Almost every reputable 3.7 V pouch cell sold with a red/black lead has a small PCB under the yellow tape providing over-charge, over-discharge, and short-circuit protection. That protection is your last line of defence and it belongs on the cell, not on a separate module you might wire wrong. Verify it's there: measure open-circuit voltage; if it reads 0 V it's a protected cell that has tripped, not a dead one.

**Never:** puncture it, solder directly to the pouch tabs, let a screw boss press into it, or trap it against a heat source. Mount it in a 3D-printed pocket with 0.5 mm clearance on all sides and a strip of 3M VHB, not glued hard to a PCB.

**Fuel gauge (MAX17048 etc.): not necessary.** A 2 × 1 MΩ divider into an ADC1 pin with a 100 nF cap is enough, and burns ~2 µA. See §7 for what to do with the reading.

### 3.5 Charging — **KEEP TP4057 for V1, add one diode, plan a real PMIC for V2**

TP4057 is a linear single-cell CC/CV charger in **SOT23-6** with reverse-battery protection ([TOPPWR](http://toppwr.com/eproduct), [datasheet](https://mm.digikey.com/Volume0/opasdata/d220001/medias/docus/5010/TP4057.pdf)). Relative to TP4056 (SOP-8, up to 1 A), the TP4057 is a smaller package in roughly the **500 mA** class ([comparison discussion](https://budgetlightforum.com/t/differences-between-tp4056-tp4057-and-mcp73831-2-controllers-for-charging/15577)). For a 700 mAh cell you want ~0.5 C ≈ 350 mA anyway, so TP4057 is genuinely the better fit and the smaller board — **your instinct here was correct.**

Watch out for one thing: many "TP4057 with protection, Type-C" modules are sold as "1 A." Ignore the marketing; set charge current by the programming resistor and target **300–400 mA** for a 700 mAh cell. Slower charging = cooler cell = longer life, and you don't care about charge time on a device you top up fortnightly.

- **Is a combined charger+protection board better?** If your cell already has a PCM, you don't need the module's protection — but it's harmless redundancy and the combined boards are small. Fine either way. Just never rely on *neither*.
- **Is power-path management necessary?** Not for V1, if you use the diode trick in §6. For V2, yes — use a real power-path charger (**TI BQ25185** or **BQ24074**) so the load runs from USB while the cell charges independently. That's the difference between "works" and "correct."
- **Custom PCB for V1?** No. Modules for V1, custom PCB for V2. Your V1 risk should be in the *product*, not in a board respin.

### 3.6 Power switch — **REPLACE, and demote it**

The 23.3 × 7.5 × 12 mm switch is out — 12 mm of body height in a 22.6 mm stack is indefensible.

**Do you need a hard switch at all?** Strictly, no. At ~50 µA deep sleep, a 700 mAh cell idles for months; self-discharge dominates. Premium products in this class have no power switch — they sleep.

But I agree with keeping one for V1, for a different reason than you gave: **you need a way to make the device unambiguously dead** while you're wiring, debugging, transporting it in a bag, or handing it to someone at an interview.

**Recommendation:** a **mini slide switch (SS-12D00 / MSK-12C02 class, ~8 × 4 × 6 mm body)** recessed into the **rear** face, treated as a shipping/service cutoff — not a control the user ever thinks about. Daily on/off is a long-press of the crown.

**Critical wiring detail:** put the switch **between the battery node and the load**, downstream of the charger's `B+`. If you put it between the cell and the charger, the device can't charge while switched off — which is the one behaviour everyone expects to work.

### 3.7 NFC — **KEEP, but repurpose it from Easter egg to onboarding**

As specified ("subtle interaction, Easter egg"), an NTAG213 is decoration and I'd cut it. But there is one genuinely good use, and it happens to solve your hardest UX problem:

> **The NFC tag on the underside is the setup instructions.** Tap your phone on MOOKS → it opens `mooks.id/setup` → a page that explains how to join `MOOKS-setup` and enter your Wi-Fi. Zero power, zero firmware, zero pins, ~$0.20, and it removes the printed quick-start card you'd otherwise need.

That reframes NFC from gimmick to onboarding infrastructure, and it makes a nice story: *"the device has no keyboard, so the packaging is the keyboard."* Keep it. Put it under the rear label. Do not mention it in the UI. Never make anything depend on it.

### 3.8 Status LED — **REMOVE. In fact, remove the one you already have.**

You don't need one, and you have an argument against it: any LED that can be lit while the screen is off is a battery leak and a visual noise source, and a lit LED inside a matte black shell means a visible light-leak seam.

- **Charging feedback?** The OLED already knows. Wake on plug-in, show a charge state, sleep the screen after 3 s.
- **Wi-Fi state?** A 6 px glyph in the corner of the screen, shown only when something is wrong.
- **Startup?** The boot animation is the startup indicator.

And per §3.2: **desolder the SuperMini's power LED.** You're spending 1–3 mA — more than your entire sleep budget — to illuminate the inside of a sealed box.

### 3.9 Summary table

| Component | Current | Action | Recommended |
|---|---|---|---|
| Display | 1.3" 128×64 SH1106 I²C, 35.5 × 33.7 | **REPLACE** (keep for mule) | 1.32" 128×96 SSD1327, 16-grey, SPI, 34.3 × 30.5 mm |
| MCU | ESP32-C3 SuperMini | **KEEP** + verify LDO, remove POW LED | Same; ESP32-C3-MINI-1 on custom PCB for V2 |
| Encoder | EC11 5-pin | **KEEP** | EC11, 15 mm shaft, + RC filter, + **aluminium knurled knob** |
| Knob | unspecified | **ADD** | Aluminium, knurled, Ø16–18 mm, 6 mm D-shaft |
| Battery | 400–550 mAh | **REPLACE** | 603040 ~700 mAh, integrated PCM, JST-PH |
| Charger | TP4057 module | **KEEP** + Schottky | TP4057 @ 350 mA; BQ25185 power-path for V2 |
| Switch | 23.3 × 7.5 × 12 mm slide | **REPLACE** | SS-12D00 mini slide, rear face, service cutoff only |
| NFC | NTAG213, Easter egg | **KEEP, repurpose** | NTAG213 under rear label → setup URL |
| Status LED | optional add | **REMOVE ×2** | None. Also desolder the board's POW LED. |
| Front panel | none (drill the PVC) | **ADD** | 2 mm black cast acrylic, back-masked |
| Chassis | none | **ADD** | 3D-printed PETG internal frame |
| Ballast | none | **ADD** | 25–30 g steel or brass plate in the base |
| Wire | "thin flexible" | **SPECIFY** | 30 AWG silicone, twisted pairs |


---

## 4. EXACT TARGET DIMENSIONS

All values **[VERIFY]** against your actual parts before cutting. Tolerances assume hand tools + a laser-cut panel.

### Enclosure

| Item | Value |
|---|---|
| V1 external | 77.0 × 51.0 × 27.0 mm (X1, as bought) |
| V1 assumed wall | 2.2 mm → interior 72.6 × 46.6 × 22.6 mm |
| Front-panel safe window | **62 × 36 mm** |
| **V2 target external** | **70 × 45 × 18 mm** (custom, 3D-printed or CNC) |
| Corner boss keep-out | Ø8 mm at each corner (Ø6 boss + 1 mm clearance) |
| Antenna keep-out | ≥10 mm metal-free around the C3's antenna end |

### Front panel (the part that makes or breaks the look)

| Item | Value |
|---|---|
| Material | 2.0 mm black **cast** acrylic (not extruded — cast laser-cuts with a polished edge) |
| Outline | Interior of the front recess **−0.3 mm** on all sides (press fit, no visible gap) |
| Corner radius | Match the shell's inner radius, typically R3–R4 |
| Display window (SSD1327 1.32") | **27.4 × 20.7 mm** = active area 26.86 × 20.14 + 0.25 mm per side |
| Display window (1.3" fallback) | **29.9 × 15.2 mm** = active 29.42 × 14.70 + 0.25 mm per side |
| Window position | Horizontally: 12 mm from panel left edge. Vertically: **centred, then raised 1.5 mm** — optical centring beats geometric centring when there's a knob below-right |
| Encoder hole (Option A) | **Ø7.2 mm** (EC11 bushing is 7 mm) + two Ø1.2 mm anti-rotation dimples if your EC11 has locating pegs |
| Encoder centre (Option A) | 12 mm from panel right edge, vertically centred |
| Min knob-to-window gap | **3.0 mm** of solid panel between knob skirt and window edge |
| Wordmark | Bottom-left, 6 pt, 12 mm from left, 4 mm from bottom |

### Cutouts in the shell

| Item | Value |
|---|---|
| USB-C slot | **9.5 × 3.6 mm**, bottom face, position determined by where the C3 board's connector actually lands (measure the assembled chassis, then cut) |
| USB-C slot chamfer | 0.5 mm on the outside edge so cables seat flush |
| Slide switch slot | 8.0 × 3.0 mm, rear face, recessed 1 mm |
| NFC tag | No cutout — PVC/ABS is RF-transparent. Tag goes inside, under the rear label. |

### Internal parts

| Item | Value |
|---|---|
| Battery pocket | 6.5 × 31 × 41 mm (603040 + 0.5 mm clearance all round + swell room) |
| Battery retention | 3M VHB strip + printed lip; **never** a screw through the pocket floor |
| MCU pocket | 23.5 × 19 × 5 mm, USB-C edge open to the shell wall |
| Charger module pocket | 18 × 12 × 3 mm |
| Chassis wall thickness | 1.2 mm (PETG) or 1.5 mm (PLA) |
| Wire channels | 2.0 mm wide × 1.5 mm deep |
| Ballast plate | 60 × 35 × 2.0 mm steel (≈33 g) or brass (≈36 g) |
| Min clearance, any conductor to any other | 1.0 mm, or Kapton between them |

### V2 PCB

| Item | Value |
|---|---|
| Outline | 66 × 41 mm, 4-layer, 1.6 mm |
| Layers | Sig / GND / PWR / Sig — solid ground plane is not optional with a Wi-Fi radio |
| Antenna | ESP32-C3-MINI-1 at a board edge, keep-out per Espressif's module datasheet, no copper under it on any layer |
| Encoder | Through-hole EC11 footprint + panel-mount bushing carrying the load, not the solder joints |
| Display | GH1.25 7-pin connector, SPI |
| Charger | BQ25185 + 350 mA program resistor + thermal pad to a copper pour |
| Regulator | 3.3 V buck, low-Iq (TPS62740 class) — a linear regulator wastes the top 20% of your cell |
| Protection | USB-C: **ESD diode array on D+/D−/CC + VBUS**, 5.1 kΩ CC pulldowns, 0.5 A polyfuse |
| Test points | VBAT, 3.3 V, GND, TX, RX, BOOT, EN — you will thank yourself |
| Battery connector | JST-PH 2.0, keyed, on the opposite side from the antenna |

---

## 5. INTERNAL LAYOUT

### Option A — "Dial" (V1, recommended to build first)

**Top view** (front panel removed, looking down into the front of the shell):

```
        ←──────────────────── 77.0 external ────────────────────→
        ┌───────────────────────────────────────────────────────┐
        │ ○                                                   ○ │  ← Ø6 boss
        │    ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐                          │
   5    │    │  DISPLAY MODULE       │       ╔═══════╗          │
   1    │    │  34.3 × 30.5          │       ║ EC11  ║          │
   .    │    │  ┌─────────────────┐  │       ║ 12.4  ║ ←knob    │
   0    │    │  │ active 26.9×20.1│  │       ║ sq.   ║  Ø16-18  │
        │    │  └─────────────────┘  │       ╚═══╤═══╝          │
   e    │    └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘           │ 5 wires      │
   x    │                                        ╰────────╮     │
   t    │ ○                                               ○     │
        └───────────────────────────────────────────────────────┘
             ↑12mm↑                                ↑12mm↑
              from left edge                    centre from right

        Layer beneath (dashed = hidden under display/battery):
        ┌───────────────────────────────────────────────────────┐
        │   ┌───────────────────────┐   ┌──────────────┐        │
        │   │  LiPo 603040          │   │ C3 SuperMini │        │
        │   │  30 × 40 × 6          │   │  22.5 × 18   │        │
        │   │  (under display)      │   │              │        │
        │   └───────────────────────┘   └───────┬──────┘        │
        │                    ┌────────┐         │ USB-C         │
        │                    │TP4057  │      ╭──┴──╮            │
        └────────────────────┴────────┴──────┤ ▭▭▭ ├────────────┘
                                              USB-C slot, bottom face
                                     ⚠ antenna end points LEFT,
                                       ≥10 mm from ballast plate
```

**Side view** (looking from the right, through the 51 × 27 face):

```
                 ←──────────── 51.0 ────────────→
        ┌─────────────────────────────────────────────┐ ─┐
    2.0 │▓▓▓▓▓▓▓▓▓▓▓ acrylic front panel ▓▓▓▓▓▓▓▓▓▓▓▓│  │
        ├─────────────────────────────────────────────┤  │
    5.0 │  ███ OLED glass + PCB ███                   │  │
        │ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │  │
    1.5 │  wire channel        ┌─ EC11 body ─┐        │  │  27.0
        ├──────────────────────┤   6.5 tall  │────────┤  │  ext
    6.0 │  ▒▒▒ LiPo 603040 ▒▒▒ └─────────────┘        │  │
        ├─────────────────────────────────────────────┤  │
    1.0 │  ─── Kapton isolation ───                   │  │
        ├─────────────────────────────────────────────┤  │
    4.5 │  ▓▓ C3 SuperMini ▓▓        ▓ TP4057 ▓       │  │
        ├─────────────────────────────────────────────┤  │
    2.0 │███████ steel ballast plate ████████████████ │  │
        └─────────────────────────────────────────────┘ ─┘
        ────────────────────────────────
        Σ = 22.0 mm used / 22.6 mm available   →  0.6 mm margin
```

### Option B — "Crown" (the final version)

```
   Front face becomes pure display + negative space:

        ┌───────────────────────────────────────────────────────┐
        │                                                       │
        │              ┌─────────────────────┐                  │╤═╗
        │              │                     │                  │║ ║ ← crown,
        │              │  active 26.9 × 20.1 │                  │║ ║   right
        │              │                     │                  │╧═╝   edge
        │              └─────────────────────┘                  │
        │   MOOKS.                                              │
        └───────────────────────────────────────────────────────┘
             ↑ wordmark, 6pt, 60% grey — the only other mark
```

The crown sits on the **right-side face (51 × 27 mm)**, upper third, so that with the device flat on a desk and the face toward you, your right thumb falls on it naturally. The encoder body extends ~10 mm inward from the side wall, held by a printed bracket bonded to the chassis — the bushing takes the axial load, never the solder joints.

**Direct answers to your layout questions (§ items 8–12):**

- **Stacking strategy:** display on the top shell, everything else on the bottom shell, single connector-less umbilical between the two halves (or better: a 6-pin JST between halves so you can open the device without desoldering).
- **Top shell carries:** front panel + display + encoder. All three must be co-planar and co-located, because they're what the user aligns visually.
- **Bottom shell carries:** MCU, battery, charger, switch, ballast. All the mass sits low — which also makes the device sit stable on a desk.
- **Battery under the display?** **Yes.** It's the flattest large part and the display is the flattest large part; they nest. Just put Kapton between them and leave 0.5 mm.
- **MCU beside or under the display?** **Beside** — because the USB-C connector must reach an outside wall, and because the antenna needs to be as far from the battery and the ballast plate as possible. Under the display it would be sandwiched between two RF-hostile slabs.

---

## 6. POWER ARCHITECTURE

### V1 — modules, one USB-C port, correct behaviour

```
   USB-C (the C3 SuperMini's own port — you need it for flashing anyway)
     │
     ├─ VBUS 5V ──→ [C3 SuperMini "5V" pin] ──→ ME6211 LDO ──→ 3.3V rail
     │                                                            │
     └─ VBUS 5V ──→ TP4057 VIN                                    │
                       │  CC/CV, Iset ≈ 350 mA                    │
                       ├─ BAT ──→ LiPo 700 mAh (with PCM)         │
                       │            │                             │
                       │            └─ SW ──→ ▷|── Schottky ──────┤
                       │              (rear)   (SS14 / MBR120)    │
                       │                        cathode at 5V pin │
                       │                                          ↓
                       └─ STAT ──→ (not used; OLED shows state)   3.3V:
                                                                  ├─ ESP32-C3
                                                                  ├─ OLED
                                                                  └─ encoder pull-ups

   VBAT sense:  VBAT ──[1MΩ]──┬──[1MΩ]── GND      → GPIO2 (ADC1)
                              └──[100nF]── GND
```

**Why the Schottky is the whole trick.** Without it, connecting USB puts 5 V on the same node as your 4.0 V battery through the closed switch, and current flows backward into the cell bypassing the charger. With the diode (cathode at the `5V` pin), the battery can *source* but never *sink*. Result:

- **USB plugged in:** VBUS (5 V) wins, powers the board directly, and independently feeds the charger. **The device runs at full power while charging, and the charge current isn't corrupted by the load** — which is a genuine power path, achieved with one $0.03 part. This answers your Q25 and Q24: charging and Wi-Fi coexist fine because they're on separate branches, and the TP4057 dissipates at most ~(5 − 3.7) × 0.35 ≈ 0.45 W. Give it 100 mm² of copper or thermal-tape it to the ballast plate. Do not bury it under the battery.
- **USB unplugged:** battery sources through the diode.

**Voltage headroom — the real limit.** Battery 3.5 V − Schottky 0.3 V = 3.2 V at the ME6211 input; with ~150 mV dropout you hold 3.3 V down to about **3.45–3.5 V of cell voltage**. Below that the rail sags toward the C3's 3.0 V floor and Wi-Fi TX bursts will brown out. So:

- Set **low-battery warning at 3.60 V**, **forced sleep at 3.45 V**. You'll leave ~10% of the cell unused. Accept it for V1.
- **Add bulk capacitance: 100–220 µF electrolytic or tantalum + 10 µF ceramic right at the C3's 3.3 V/GND pins.** Wi-Fi TX draws 300–400 mA spikes on a sub-millisecond scale. This capacitor is the single most common fix for "my ESP32 randomly reboots when it connects." Do not skip it.

**Absolute prohibition:** never feed 4.2 V into the `3V3` pin. The ESP32-C3's absolute maximum VDD is 3.6 V. That is a destroyed chip, not a brownout.

### V2 — custom PCB, done properly

```
   USB-C receptacle
     ├─ ESD array on VBUS/D+/D−/CC + 0.5 A polyfuse
     ├─ 5.1 kΩ × 2 CC pulldowns  (or a CC controller if you want >500 mA)
     ├─ D+/D− ──→ ESP32-C3 native USB (flashing + future host comms)
     └─ VBUS ──→ BQ25185 power-path charger
                   ├─ BAT ──→ LiPo (PCM on cell) + NTC thermistor to TS pin
                   ├─ SYS ──→ (auto-selects USB or battery, no diode drop)
                   │            │
                   │            └─→ TPS62740 buck (Iq ~360 nA) ──→ 3.3V
                   └─ /STAT, /PG ──→ GPIO (firmware knows charge state)
```

The V2 gains that matter: no diode drop (you use the cell down to 3.0 V, ~+15% runtime), a switching regulator instead of a linear one (+15–20% again), real charge-state signalling, cell temperature monitoring during charge (the actual safety improvement), and sub-µA regulator quiescent current.

**USB-C position:** bottom face, centred or slightly left. Rationale: it's where every phone user expects it, the cable exits downward so the device can stay face-up on a desk while charging, and it keeps the front and top faces free of holes. **Do not** put it on the front. **Do not** add a second port for charging — one port, both jobs.

---

## 7. BATTERY LIFE **[ALL FIGURES ARE ESTIMATES]**

Assumptions: 700 mAh cell, **~80% usable** given the 3.45 V cutoff → 560 mAh budget. Board figures anchored on the ~43 µA deep-sleep / ~26.8 mA active numbers reported for the SuperMini ([mischianti.org](https://mischianti.org/esp32-c3-super-mini-high-resolution-pinout-datasheet-and-specs/)), **with the POW LED removed**. OLED current is heavily content-dependent — a dark UI with sparse text lights few pixels.

| State | Current **[EST]** | Continuous runtime **[EST]** |
|---|---|---|
| Deep sleep (screen off, radio off) | ~50 µA (43 board + 2 divider + ~3 charger/leakage) | **~11,000 h ≈ 15 months** — self-discharge dominates long before this; expect 3–6 months realistically |
| Light sleep, waiting for input | ~2–4 mA | ~6 days |
| Browsing cached content, radio off, screen on | ~33 mA (27 MCU + ~6 OLED dark UI) | **~17 h** |
| Browsing, radio on with DTIM modem sleep | ~45 mA | ~12 h |
| Wi-Fi connected, no modem sleep | ~85–100 mA | ~6 h |
| One fetch cycle (assoc + TLS + GET + close, ~5 s @ ~90 mA) | — | **~0.13 mAh per fetch** |
| Charging @ 350 mA | — | ~2.5 h from empty |

**Realistic daily model** — 5 sessions × 45 s of screen-on, 2 fetches, rest asleep:

```
screen-on:   5 × 45 s × 33 mA  =  2.06 mAh
fetches:     2 × 0.13 mAh      =  0.26 mAh
deep sleep:  24 h × 0.05 mA    =  1.20 mAh
                                 ─────────
                                  3.52 mAh/day
560 mAh / 3.52  ≈  159 days  →  claim "6–8 weeks" and be safely right
```

**The honest claim: charge MOOKS about once a month.** That is a *great* product line and it's achievable — but only if you actually implement deep sleep, actually remove the POW LED, and actually keep the radio off between fetches. Skip any one of those and you're at 6 hours, which is a fundamentally different (and much worse) product.

**Low-battery behaviour — recommended:**

| Cell voltage | Behaviour |
|---|---|
| > 3.85 V | Nothing shown. No icons. |
| 3.60–3.85 V | Small battery glyph, top-right, dim. |
| 3.50–3.60 V | On wake: one full-screen card — "Low battery. Charge me soon." Dismiss with any input. Radio still allowed. |
| 3.45–3.50 V | Radio disabled. Cached content only, banner reads `offline · low battery`. |
| < 3.45 V | Show "Sleeping to protect the battery." for 2 s → deep sleep. Refuse to wake (2 s of screen, then back to sleep) until charged above 3.6 V. |

**Do not display a battery percentage.** With no coulomb counting and a load-dependent voltage curve, any percentage you show will be wrong in a way users immediately notice ("it said 40% yesterday and now it's 60%"). Four states are honest; a number is a lie with a decimal point.

---

## 8. WI-FI PROVISIONING

### Recommendation: SoftAP captive portal, launched by a QR code on the OLED

This is the best available answer for a device with one knob, and it needs no companion app.

```
First boot (or Menu → Wi-Fi):

  ┌────────────────────────────┐      1. Device starts SoftAP "MOOKS-setup"
  │ SET UP WI-FI               │         (open network, or WPA2 with the
  │                            │          code shown on screen)
  │  ▓▓▓▓▓▓▓  scan to join     │
  │  ▓ ███ ▓                   │      2. OLED renders a QR encoding
  │  ▓▓▓▓▓▓▓  or join          │         WIFI:S:MOOKS-setup;T:nopass;;
  │           MOOKS-setup      │         → iOS/Android join the AP directly
  │                            │
  │ turn to skip               │      3. Captive portal auto-opens:
  └────────────────────────────┘         network list + password field
                                      4. Device saves to NVS, reboots to
                                         station mode, AP disappears
```

**Why the QR matters:** it removes the single most error-prone step (typing an SSID) and it looks like magic in a demo. Feasibility check on a 128×96 display: a `WIFI:` payload of ~30–40 characters is a QR version 2–3 (25×25 to 29×29 modules); at 2 px per module that's 50–58 px square — fits, with room for a caption. **Keep the SSID short** so you stay in version 2. This is a real design constraint driven by pixel count, which is exactly the kind of detail that makes a portfolio piece credible.

**Rejected alternatives:**

| Method | Verdict |
|---|---|
| Hardcoded credentials | Fine for the bench mule **only**. Ship it and you fail the "product thinking" test, plus your demo dies on unfamiliar Wi-Fi — which is *every* demo. |
| ESP SmartConfig / ESP-Touch | Rejected. Requires a vendor app, fails on 5 GHz-only and many enterprise/mesh networks, and gives near-zero diagnostic feedback. Historically flaky. |
| BLE provisioning | Rejected for V1. Technically clean, but requires Espressif's app — a dependency you explicitly listed as a non-goal. Reconsider for V2 *only* if you write your own SwiftUI provisioning app (see §20 — there's an argument for this). |
| WPS | Dead. |
| Entering a password by rotating through a character set | Rejected, and I want to be clear about why: it *works*, it's ~90 seconds of misery, and it is the kind of thing that seems clever in a design doc and gets abandoned in user testing. Don't. |

**Also required, and usually forgotten:** a way to *change* networks and a way to *reset*. Menu → Wi-Fi re-enters the portal. Long-press the crown for 10 s during boot = factory reset (confirm on screen). Both are five lines of code and both come up the first time you take the device somewhere new.

---

## 9. FIRMWARE ARCHITECTURE

**Toolchain:** PlatformIO + Arduino-ESP32 framework. Not the Arduino IDE (no real project structure, no dependency pinning, poor diffs). Not bare ESP-IDF (you'd spend a week on things U8g2 and ArduinoJson hand you). PlatformIO gives you `platformio.ini` with pinned library versions, multiple build environments, and a git-friendly layout — that's the sweet spot for a student-built product.

Your proposed module list is basically right. Here's the version I'd build, with the two additions that matter (an event bus and a separate network task):

```
mooks-firmware/
├── platformio.ini              ; pinned versions, envs: mule / device / sim
├── include/
│   └── config.h                ; pins, timings, thresholds — ONE place
├── src/
│   ├── main.cpp                ; ~40 lines: init, spawn tasks, loop()
│   │
│   ├── core/
│   │   ├── EventBus.{h,cpp}    ; FreeRTOS queue of small POD events
│   │   ├── Log.h               ; LOG_I/LOG_W/LOG_E, compiled out in release
│   │   └── Clock.{h,cpp}       ; SNTP + "is the drop stale?"
│   │
│   ├── hal/
│   │   ├── Display.{h,cpp}     ; U8g2 wrapper; owns the buffer, nothing else touches it
│   │   ├── Encoder.{h,cpp}     ; ISR + quadrature table + button FSM
│   │   ├── Battery.{h,cpp}     ; ADC read, median-of-5, → 4 states
│   │   └── Power.{h,cpp}       ; light/deep sleep, wake config, timeouts
│   │
│   ├── net/
│   │   ├── WifiService.{h,cpp} ; connect/retry/backoff; owns NVS creds
│   │   ├── ApiClient.{h,cpp}   ; HTTPS GET + ETag + streaming JSON parse
│   │   └── Provisioning.{h,cpp}; SoftAP + captive portal + QR payload
│   │
│   ├── data/
│   │   ├── Models.h            ; fixed-size PODs. No String. No vector.
│   │   ├── Store.{h,cpp}       ; NVS: creds, settings, saves, tag affinity
│   │   └── Cache.{h,cpp}       ; LittleFS: last 2 drops
│   │
│   ├── ui/
│   │   ├── Screen.h            ; onEnter/onExit/onRotate/onPress/onLongPress/render
│   │   ├── Router.{h,cpp}      ; screen stack, transitions
│   │   ├── Theme.h             ; fonts, margins, grey levels — the design system
│   │   └── screens/            ; Boot, Today, Detail, Handoff, Saved, Menu, Setup
│   │
│   └── app/
│       ├── AppState.h          ; the three orthogonal state machines (§9.3)
│       └── App.{h,cpp}         ; wires events → state → router
└── test/                       ; native unit tests: ranking, truncation, FSM
```

### 9.1 The five rules that keep this from becoming spaghetti

1. **The UI task never blocks.** No `HTTPClient` call, no `WiFi.begin()`, no `delay()` longer than 5 ms on the render path. Ever.
2. **Networking lives in its own FreeRTOS task** and communicates *only* by posting events to the bus (`DROP_UPDATED`, `NET_FAILED`, `NET_ONLINE`). This is the single most important architectural decision in the firmware, and it's what makes "the screen stays responsive while Wi-Fi is dying" possible.
3. **Render only when dirty.** A `bool dirty` flag; `render()` at up to 30 Hz but only when something changed. Saves power and makes animation timing explicit.
4. **No dynamic allocation after boot.** `char title[19]`, not `String`. `Item items[8]`, not `std::vector`. Heap fragmentation on a device that runs for weeks is a real failure mode, and TLS already wants 30–45 KB of contiguous heap.
5. **One owner per peripheral.** Only `Display` touches U8g2. Only `Encoder` touches the ISR. If two modules need the same thing, they're the same module.

### 9.2 Encoder handling — do it right the first time

Polling with `delay()` is why hobby encoders feel bad. Use:

- **Interrupt on both edges of A and B**, feeding a 16-entry quadrature transition lookup table indexed by `(prev_state << 2) | new_state`. Emits −1, 0, or +1. Invalid transitions produce 0 instead of a phantom step.
- **Hardware RC filter** (10 kΩ + 100 nF per channel) — removes contact bounce before it reaches the GPIO.
- **Accumulate detents in the ISR, consume them in the UI task.** Never render from an ISR.
- **Button FSM** with three outputs, decided by timing: press <500 ms = `SELECT`, ≥500 ms = `BACK`, ≥10 s at boot = `FACTORY_RESET`. Fire `BACK` **on threshold crossing, not on release** — the user should feel the long-press register while still holding, which is what makes long-press feel deliberate rather than laggy.
- **Wake:** the switch goes to an RTC-capable GPIO (GPIO0–5 on the C3) as a deep-sleep wake source. Rotation *cannot* wake the device (quadrature needs a running CPU), so the interaction is "press to wake" — which is fine, and matches every watch crown.

### 9.3 State machine — split it into three

Your current chain (`BOOT → CONNECTING → READY → BROWSING → DETAIL` + a pile of error states) has a structural flaw: **it makes connectivity a screen.** That means a user with bad Wi-Fi stares at "CONNECTING" while a perfectly good cached drop sits in flash three feet away.

Replace one flat machine with three orthogonal ones:

```
POWER        DEEP_SLEEP → WAKING → ACTIVE → DIMMING → (DEEP_SLEEP)
                                     ↑
                                  CHARGING (a modifier, not a state)

NET          OFFLINE ⇄ CONNECTING ⇄ ONLINE ⇄ SYNCING ⇄ FAILED
             ↑ this is a STATUS FLAG rendered as a 6px glyph.
               It NEVER owns the screen. It NEVER blocks the UI.

UI           BOOT → TODAY ⇄ DETAIL ⇄ HANDOFF
                      ↕
                     MENU → SAVED / WIFI / ABOUT
                      ↕
                     SETUP  (only when no credentials exist)
```

The governing principle: **cached content renders in under 300 ms of wake, always.** Network results arrive later and update in place. Errors are 2-second toasts over live content, never dead-end screens with an OK button. There is no state in which MOOKS shows the user nothing useful.

Boot sequence that follows from this:

```
 press crown
   → 120 ms: wordmark fades in (greyscale makes this look expensive)
   → 300 ms: TODAY renders from cache, glyph shows ⋯ (connecting)
   → background: Wi-Fi + conditional GET
   → 2–5 s:  either glyph → ✓ and content refreshes in place,
             or glyph → offline and nothing else changes
```

The user never waits. That's the whole point.

### 9.4 Text handling — a contract, not a runtime problem

Do **not** write a word-wrap/ellipsis engine on the device. Instead, enforce string lengths in the **backend schema** (§10) and treat over-length text as a *content bug caught at build time*. The device renders what it's given, at fixed positions, and cannot break its own layout.

This is a real engineering position worth defending in an interview: *the server does the editing, the device does the rendering.*

### 9.5 OLED longevity — the risk nobody plans for

A static UI on an OLED burns in. Your header, your glyphs, and your list chevrons are at fixed pixels for the device's whole life. Mitigations, all cheap:

- **Screen timeout: 45 s** of no input → fade out → light sleep. **3 min** → deep sleep.
- **Contrast at ~50%**, not maximum. It's plenty in a dark-panel design and roughly halves both burn-in and current.
- **Dark-dominant layout** — lit pixels are the exception. Which is also the aesthetic you want.
- **1 px layout jitter** every 30 s of continuous on-time (imperceptible, spreads wear).
- **No permanent chrome.** The wordmark appears at boot, then never again. Your enclosure already says MOOKS; the screen doesn't need to.


---

## 10. BACKEND ARCHITECTURE

### 10.1 V1: no server at all

Your instinct to avoid scraping TikTok is correct — and I'd go further. **For V1, don't build an API. Build a content pipeline that outputs static files.**

```
   Google Sheet (or Notion DB)        ← you edit here, 10 min/day
        │  columns match the schema exactly, with length validation
        ↓
   GitHub Action (nightly + on-demand)
        │  fetch sheet → validate → truncate-check → build JSON → bump version
        ↓
   Cloudflare Pages / GitHub Pages    ← free, HTTPS, global CDN, ETag support
        │
        ├── /v1/manifest.json     {schema, latest_drop_id, fw_version, etag}
        └── /v1/drops/2026-09-12.json
        ↓
   ESP32-C3:  GET manifest (If-None-Match) → 304? stop. → else GET drop → cache
```

Why this is the *right* architecture and not a cop-out:

- **Zero cost, zero servers, zero downtime, zero attack surface.** No secret to leak from a device you hand to strangers.
- **Conditional GET with `If-None-Match`** means the common case is a 304 with a ~200-byte response. That's your battery budget protected by a correctly-used HTTP header, which is a more sophisticated answer than "I built a REST API."
- **The validation step in CI is the thing that saves the project.** It enforces `title ≤ 18 chars` at build time, so a content mistake can never reach a device and break the layout.
- It's honest about scale. You have one user. A Kubernetes cluster would be a lie.

**V1.5, when you need per-device state:** one Cloudflare Worker or a small FastAPI app.

```
GET  /v1/drop?city=jkt&d=2026-09-12     → today's drop (ETag)
GET  /v1/item/{id}                       → full detail
POST /v1/saves      { device, item_id }  → sync saves
GET  /v1/link/{short}                    → 302 to maps/article  (the QR target)
GET  /v1/fw/latest                       → OTA manifest
```

Auth: a per-device random token in NVS, `Authorization: Bearer`. HTTPS with the root CA pinned in firmware (not `setInsecure()` — pinning is three lines and it's the difference between "I used HTTPS" and "I understand TLS"). No user accounts, no PII, no OAuth. **You do not need authentication complexity for a read-mostly food app.**

### 10.2 JSON schema — with the length contract visible

```json
{
  "schema": 1,
  "drop_id": "2026-09-12",
  "city": "jkt",
  "expires": "2026-09-13T04:00:00Z",
  "items": [
    {
      "id": "mt-001",
      "title": "Matcha Tiramisu",        // ≤ 18 chars — HARD LIMIT, CI-enforced
      "kind": "dish",                    // dish | drink | place | oddity
      "delta": 238,                      // int %, may be negative
      "hook": "Everyone's ordering it.", // ≤ 32 chars — the one-liner
      "why":  "Matcha's bitterness cuts the mascarpone. That's the whole trick.",
                                         // ≤ 96 chars — the payoff
      "place": "Kopi Nako",              // ≤ 20 chars, optional
      "link":  "a7f3",                   // short code → /v1/link/a7f3 → QR
      "tags":  ["matcha", "dessert", "viral"]
    }
  ]
}
```

Design notes:

- **`delta` is an integer percentage, and it must be defensible.** If you can't source a real number, don't print a fake one — use a 3-level glyph (`rising / steady / peaking`) instead. Inventing "↑238%" is the one thing in this project that could read as dishonest to a reviewer, and it's the first thing a sharp interviewer will ask about. Either cite the signal or drop the digits.
- **`hook` vs `why` is the whole content design.** `hook` earns the press; `why` rewards it. If an item has no interesting `why`, it doesn't belong in the drop.
- **`link` is a 4-char short code** specifically so the QR stays at version 1–2 (21–25 modules) and renders crisply at 2 px/module on a 128 px display. Pixel budget driving URL design — that's the kind of constraint chain worth writing about.
- **5 items per drop.** Not 20. See §12.

### 10.3 Cache

| What | Where | Size | Policy |
|---|---|---|---|
| Wi-Fi creds, device token, settings | NVS | <1 KB | Persistent |
| Last 2 drops | LittleFS, 2 files | ~2 KB each | LRU, overwrite oldest |
| Saved items (max 30) | NVS blob | ~6 KB | FIFO eviction at 30, user can delete |
| Tag affinity counters (12 tags) | NVS | 48 B | Incremented on save |

**Offline is a first-class mode, not an error.** Concretely: if the cached drop is <36 h old, render it normally with a small offline glyph. If it's older, add one dim line — `yesterday's picks` — and never hide the content. The only true dead end is "no cache and no network," which happens exactly once (before first sync) and should show the setup flow, not an error.

### 10.4 Ranking

For V1, be honest and simple:

```
score = editorial_rank            // you decided the order; own it
      − 8 × times_seen            // novelty decay, stored on-device
      + 3 × tag_affinity          // from the user's own saves
      − 40 × already_saved        // don't re-show what they kept
```

That's a linear re-rank over 5 items, computed on-device in microseconds, using a preference signal the user actually generated. It's defensible, explainable, and *finite* — and as an Intelligent Systems student, being able to say **"I deliberately did not use ML here, because with 5 items and 30 saves the model would be pure theatre"** demonstrates more judgement than shipping a neural network.

**V2 scalability path (state it, don't build it):** real trend signals from public APIs and Google Trends → a nightly batch job producing city-level drops → collaborative filtering once you have >100 devices → LLM-generated `why` copy with a human approval step (never unreviewed — a hallucinated food fact on a physical object you gave someone is a much worse failure than a bad tweet).

---

## 11. UX / INFORMATION ARCHITECTURE

### 11.1 Kill the root menu

Your current IA:

```
MOOKS. → [Trending | Discover | Cafés | Saved] → list → detail
```

Three problems:

1. **Trending and Discover are the same thing to a user.** "Food becoming popular" vs "interesting/weird food" is an editorial distinction, not a user need. Nobody wakes up and decides which of those moods they're in.
2. **Cafés can't work as a top-level category.** You have no GPS (correctly — it's a non-goal). So "Cafés" means "cafés in the city you typed during setup," which is a much weaker promise than the label implies. Reviewers will ask about this within 30 seconds.
3. **It costs the user two interactions before they see any content.** On a device whose entire value proposition is "faster and calmer than opening an app," a menu you must clear before seeing anything is the exact wrong first impression.

### 11.2 Recommended IA — content first, menu last

```
        wake (press crown)
             ↓
   ┌─────────────────────────────────┐
   │  TODAY                     1/5  │   ← lands directly on content.
   │                                 │      No menu. No categories.
   │  Matcha Tiramisu                │
   │  Everyone's ordering it.        │
   │                            ↑238 │
   └─────────────────────────────────┘
        rotate → next card (1/5 → 5/5)
        press  → DETAIL
        long   → MENU

   ┌─────────────────────────────────┐   ┌──────────────────────────┐
   │  MATCHA TIRAMISU           ↑238 │   │  MENU                    │
   │                                 │   │                          │
   │  Matcha's bitterness cuts       │   │  > Saved            12   │
   │  the mascarpone. That's         │   │    Nearby                │
   │  the whole trick.               │   │    Wi-Fi           ✓     │
   │                                 │   │    About                 │
   │  Kopi Nako      press to save   │   │                          │
   └─────────────────────────────────┘   └──────────────────────────┘
        press  → SAVE (confirm, return)
        rotate → next card's detail (stay in detail — keeps flow)
        long   → back to TODAY

   after card 5/5:
   ┌─────────────────────────────────┐
   │                                 │
   │  That's all for today.          │   ← THE most important screen
   │                                 │      in the product.
   │  4 new tomorrow, ~9am.          │
   │                                 │
   └─────────────────────────────────┘
```

Key changes and why:

| Change | Reason |
|---|---|
| Boot straight into TODAY | Zero interactions to value. The menu is for the 5% case. |
| Merge Trending + Discover into one editorial mix | One feed, mixed `kind`, so variety is a property of the drop rather than a decision you push onto the user. |
| Cafés → "Nearby", demoted into the menu, city-scoped and labelled as such | Honest about the capability. Places also appear inside TODAY as `kind: place` cards, which is where they actually get discovered. |
| Saved moves into the menu with a count | It's a destination you visit occasionally, not a peer of today's content. |
| **Press in detail = SAVE** | The most valuable action gets the easiest gesture. Long-press for back is fine because back is recoverable and saving is the thing you want to encourage. |
| **Rotate in detail = next item's detail** | Lets a user read straight through all 5 without going up and down a hierarchy. This one change roughly halves the interactions in a full session. |
| **A hard end state** | See §12. This is the product. |

### 11.3 Typography and layout on 128×96 (greyscale)

A three-tier hierarchy, expressed in grey levels rather than sizes alone — this is what the SSD1327 buys you:

```
  4 px margin all round, 6 px baseline grid

  LABEL     6–7 px caps, letterspaced, grey 40%    ("TODAY", "1/5")
  TITLE     14–16 px bold, grey 100%               (the food name)
  BODY      8–9 px regular, grey 75%               (hook / why)
  ACCENT    10 px, grey 100%, right-aligned        (the delta)
```

Rules: **left-align everything** except the accent. Never centre body text. One accent per screen. Selection is indicated by a `>` chevron or a subtle grey-15% fill bar, never by inverting the whole row (inversion lights every pixel — ugly *and* expensive). U8g2 fonts to start with: `u8g2_font_helvB14_tr` for titles, `u8g2_font_helvR08_tr` for body, `u8g2_font_micro_tr` or `u8g2_font_5x7_tr` for labels — then refine.

**Scrolling:** show 1 card at a time, not a 4-line list. On a 27 mm-wide screen, one card with real typographic hierarchy beats four cramped rows, and it makes the knob feel like it's moving *objects* rather than a cursor. Animate the card transition over ~120 ms with a 2-frame slide — with greyscale you can cross-fade, which reads as genuinely premium and costs nothing.

---

## 12. THE CORE PRODUCT LOOP

Your proposed loop — `SEE → TURN → DISCOVER → SELECT → LEARN → SAVE → COME BACK` — describes the mechanics but not the *feeling*, and it has no reason to end. Here's the version I'd defend:

### The 20-second loop

```
   ①  PICK UP        the weight registers before the screen does
   ②  PRESS          crown clicks; wordmark fades; ~300 ms
   ③  "TODAY · 5"    a promise with a number in it. Finite.
   ④  TURN, TURN     detents. one card per detent. scanning, not scrolling.
   ⑤  PRESS          one card opens. a single sentence that's actually worth reading.
   ⑥  PRESS          saved. or TURN to keep reading.
   ⑦  "That's all
       for today."   ← THE POINT. The device tells you to stop.
   ⑧  PUT DOWN       it dims itself. no notification. no badge. nothing pulls you back.
   ⑨  TOMORROW       5 new. the only reason to return is that you want to.
```

### The one addition that makes this a product: the handoff

```
   In DETAIL, turn to the last position →  "Take me there"  →  press
   ┌─────────────────────────────────┐
   │  ▓▓▓▓▓▓▓▓▓                      │   QR → mooks.id/l/a7f3
   │  ▓ ███ ▓ ▓                      │        → 302 → Google Maps / recipe
   │  ▓▓▓▓▓▓▓▓▓   scan to open       │
   │              Kopi Nako          │   Your phone does the navigating,
   └─────────────────────────────────┘   ordering, sharing. MOOKS doesn't try.
```

This is the highest-value feature in this entire review, and it costs **zero hardware**. It resolves the phone question by refusing to compete: MOOKS's job is the *decision*, the phone's job is the *execution*. A device that knows what it isn't for reads as designed. A device that tries to do everything on a 27 mm screen reads as naive.

### Emotional target

Aim for **"a small, calm, daily gift."** Not excitement, not addiction, not utility. The feelings to engineer for, in order: *anticipation* (there's a new drop), *satisfaction* (I found one thing worth keeping), *permission to stop* (it's over, and that felt good rather than frustrating).

### What MOOKS is — pick one and commit

From your list, the answer is **a desk companion with a daily ritual.** Explicitly not: a toy (implies disposable), a novelty object (implies one week of use), a "personal food radar" (implies sensing it doesn't do), or a trend display (implies always-on, which kills your battery story). A gift is a *distribution* strategy, not a product definition.

"Desk companion with a daily ritual" is the framing that survives the question *"did you still use it a month later?"* — which is the question that decides whether this project is impressive or just cute.

### Can the concept get stronger without adding hardware?

Yes, and these are the five highest-leverage software-only moves:

1. **Finiteness** (5 items, hard end state) — turns a limitation into a philosophy.
2. **QR handoff** — resolves the phone comparison.
3. **A drop time** ("new at 9am") — creates anticipation, which is the only sustainable return mechanic without notifications.
4. **A streak that isn't a streak** — "You've kept 14 discoveries" on the About screen. Reflective, not coercive. No guilt, no fire emoji.
5. **The end-of-day card as a designed object.** Most products have nothing there. A beautiful, quiet, satisfying "that's all" screen is the most memorable thing you can build, precisely because nobody expects it.

---

## 13. INDUSTRIAL DESIGN: MAKING A CHEAP PVC BOX LOOK EXPENSIVE

Ranked by impact per unit of effort. The first three account for most of the result.

### Tier 1 — do these no matter what

**1. The custom front panel is the whole game.**

Cut a **2 mm black cast acrylic** panel to the box's front recess minus 0.3 mm. **Spray the *back* face matte black, masking only the display window.** Then bond the display behind the window with a thin black double-sided tape frame (no air gap).

Result: no visible cutout edge, no PCB, no gap, no misalignment to see. When off, the display vanishes into a continuous black surface — the "infinity black" trick every premium mono-display product uses. When on, the pixels appear to float. This single step converts the device from "drilled project box" to "product," and it costs a few dollars of acrylic. **Cut the acrylic; do not drill the shell's front face.**

**2. Add mass.** A 60 × 35 × 2 mm steel or brass plate epoxied into the base adds ~33 g and moves you from 0.66 to 0.94 g/cm³ (§1). Density is the strongest non-visual quality signal there is, and it's the one thing that lands in the first second of someone picking it up. **Keep it clear of the C3's antenna end.**

**3. Buy a real knob.** Aluminium, knurled, Ø16–18 mm, 6 mm D-shaft, set screw. It is the only surface the user touches. A plastic knob undoes everything above it on this list.

### Tier 2 — the difference between good and finished

**4. Shell finish.** Wet-sand 400 → 600 → 1000 to remove mould lines, gate marks, and gloss. Then either (a) 2–3 mist coats of matte black or graphite spray with a matte clear over, or (b) **wrap it in 3M matte black vinyl** — which requires almost no skill, is reversible, and looks better than an amateur paint job nine times out of ten. Fill sink marks with primer-filler before either.

**5. Move every screw to the bottom.** Countersink them, use black-oxide M2.5 hex-socket screws (not Phillips — hex reads as considered), and fit them with a proper driver so no head is marred. **No fastener visible from the front, top, or sides.**

**6. A 3D-printed internal chassis.** One PETG or resin frame that holds display + battery + MCU + charger as a removable cartridge, with routed wire channels. Three benefits: assembly is repeatable, nothing rattles, and — importantly for your portfolio — it photographs beautifully as an exploded view and proves you designed the *inside*.

**7. Feet.** Four 1 mm black silicone bumpers, or one full-footprint cork/felt pad. Costs nothing; the device stops sliding and stops sounding hollow on a desk.

### Tier 3 — the details people notice without knowing why

8. **30 AWG silicone wire, twisted in pairs, in channels.** Silicone-jacketed wire stays flexible and doesn't fight you. **Zero hot glue anywhere** — use Kapton tape and 3M VHB. Hot glue is the single most recognisable signature of a hobby build and reviewers spot it instantly.
9. **Branding restraint.** `MOOKS.` bottom-left of the front panel, ~6 pt, **60% grey rather than white**, laser-etched or fine-cut vinyl. On the rear label: model name, your name, a build number. Nothing else anywhere.
10. **Match the corner radii.** The panel's corners should follow the shell's inner radius. A 1 mm mismatch is visible even to people who can't name what's wrong.
11. **Chamfer the USB-C slot** 0.5 mm outward so cables seat flush and the opening doesn't look punched.
12. **Add a shallow scallop** at the knob so it looks nested rather than stuck on — one of the cheapest ways to signal deliberate design.

### Colour

Go **matte graphite/near-black**. It hides sanding imperfections, makes the OLED disappear when off, and photographs well. Save **warm off-white** for V2 when you control the surface finish — off-white is beautiful and unforgiving, and it will show every flaw in a repurposed PVC box.

### V2 form factor

Target **70 × 45 × 18 mm** with a custom PCB and a 3D-printed or CNC'd shell. That's a 30% volume reduction, and "V1 → V2 got 30% smaller because I moved from modules to a single board" is one of the strongest sentences you can put in a portfolio.

---

## 14. PRODUCT DIFFERENTIATION: "WHY NOT JUST USE MY PHONE?"

You must have a crisp answer, because it's the first question you'll be asked. Weak answers to avoid: *"it's more tactile"* (so is a fidget spinner), *"it's less distracting"* (Screen Time is free), *"it's cute"* (that's a feature, not a reason).

### The answer

> **Your phone is optimised to never let you finish. MOOKS is optimised to let you finish.**
>
> It shows five things and then tells you it's done. It has no feed, no notifications, no badge, no autoplay, and no second thing to look at. It cannot follow you into bed, because it stays on your desk. And when it finds something you actually want, it hands it to your phone and gets out of the way.
>
> It is not a smaller phone. **It is the part of your phone you actually wanted, with the parts you didn't left out — because they physically cannot be added.**

That last clause is the defensible bit. Software self-restraint is a promise; **hardware self-restraint is a guarantee.** A single-purpose object with one knob *cannot* grow a feed, and that constraint is the product. This is the same argument that makes single-purpose e-readers and film cameras persist in a smartphone world, and it's a genuinely researched design position, not a rationalisation.

### Three honest counter-arguments you should raise yourself

Pre-empting these is more impressive than being caught by them:

1. **"An app with a 5-item limit would do the same thing for free."** True — mostly. The physical object contributes *presence* (it's on your desk, visible, so the ritual has a physical trigger a notification-free app can't get) and *exclusivity of attention* (you cannot switch tabs on MOOKS). Say the honest version: *"the object is what makes the constraint stick."*
2. **"The content is curated by you, so it's just your taste."** Also true for V1, and the right answer is to own it: MOOKS is *edited*, not algorithmic, and that's a positioning choice — a magazine, not a feed. Which is a nice bridge to the name (below).
3. **"It's another thing to charge."** Answered by §7: once a month. Which is only true if you actually build the sleep architecture — so the engineering *is* the product argument.

### On the name

Two things you should know, because a reviewer might:

- **"Mook" is mildly derogatory American slang** (a foolish or inept person, from Italian-American usage). In an English-speaking room, some people will hear that first. Worth a deliberate decision, not an accident.
- **But "mook" also means a magazine-book hybrid** (magazine + book), a Japanese publishing format: a curated, finite, editorially-selected volume. **That is *exactly* your product.** If you lean into that etymology, the name stops being a random syllable and becomes the thesis: *MOOKS is a mook — a small, edited, finite volume of discoveries, published daily.*

That's a much stronger brand story than "small device, big food discoveries," which is a slogan any device could wear. Consider a tagline closer to: **"Five things. Then you're done."**

One practical note: the trailing period in `MOOKS.` is a nice typographic device on the object, but drop it in URLs, filenames, and search — keep the wordmark stylised and the product name plain.

---

## 15. V1 / V1.5 / V2 / NEVER

### V1 — must have (this is the whole scope; protect it)

| | |
|---|---|
| Hardware | C3 SuperMini · 1.3" or 1.32" OLED · EC11 + aluminium knob · 700 mAh protected LiPo · TP4057 + Schottky · rear slide switch · acrylic front panel · printed chassis · ballast plate |
| Firmware | Rotate/press/long-press · TODAY → DETAIL → SAVE · end-of-day card · cache-first render · deep sleep + press-to-wake · battery states · SoftAP+QR provisioning · offline mode |
| Backend | Sheet → CI → static JSON on a CDN · conditional GET · length validation |
| Content | 5 items/day, hand-curated, for **one city** |
| Deliverables | Working device · case study · 8 user tests · photos |

### V1.5 — should have (only after V1 is in someone else's hands)

QR handoff + link redirector · saves synced to a web page · HTTP OTA · a real API for personalisation · tag-affinity re-ranking · a second city · greyscale UI refinement + card transitions · BLE provisioning **if** you write your own app.

### V2 — later (the "what's next" slide, not this semester)

Custom PCB with ESP32-C3-MINI-1 + BQ25185 + buck · 70 × 45 × 18 mm shell · real trend signals · LLM-drafted `why` copy **with human approval** · a companion app · **an accelerometer** — the single sensor genuinely worth adding, because wake-on-pickup removes the last interaction from the loop and makes the object feel alive. Add it only when nothing else is broken.

### Never

Camera · microphone · speaker · touchscreen · GPS · cellular · Raspberry Pi · local LLM · computer vision · direct social scraping from the device · RGB lighting · multiple buttons · a second screen · a battery percentage · a required mobile app · user accounts · a haptic motor (in a rigid PVC box it would rattle rather than tap — needs a properly damped custom shell first) · a status LED · infinite content.

---

## 16. RISK REGISTER

| # | Risk | P | Impact | Mitigation |
|---|---|---|---|---|
| 1 | **Content decay** — nobody updates the JSON; device shows stale food | **High** | **Fatal** | Treat the pipeline as a deliverable. 10-minute daily editing workflow in a Sheet. Batch 30 days of content *before* the demo. Show an explicit "yesterday's picks" state so staleness is honest rather than hidden. |
| 2 | **No answer to "why not my phone"** in the room | Med | **Fatal** | §14. Rehearse it in two sentences. Lead the demo with the end-of-day card, not the feed. |
| 3 | **Demo failure** — unfamiliar Wi-Fi, dead battery, loose wire | **High** | High | Offline mode that always renders. Charge the night before. **Build the SwiftUI simulator (§20) as a backup demo.** Bring the charger. Bring a second assembled board if you can. |
| 4 | **3.3 V brownout on Wi-Fi TX** at low battery | **High** | Med | 100–220 µF bulk cap + 10 µF ceramic at the board. Disable radio below 3.5 V. Measure with a scope if you can borrow one. |
| 5 | **C3 SuperMini antenna underperforms** | Med | High | Test range at S1, before any mechanical work. ≥10 mm metal keep-out. If it's bad, swap to a board with a u.FL connector or an external antenna — cheap to fix early, expensive after the chassis is printed. |
| 6 | **Cracking the PVC while drilling** | **High** | Med | Don't cut the front face at all (§13). Use step drills at low RPM for side cutouts, backed by scrap wood. **Buy two enclosures.** |
| 7 | **Depth stack doesn't close** (0.6 mm margin) | Med | Med | No pin headers anywhere. Verify §2.4 with a cardboard mock-up and calipers *before* printing the chassis. |
| 8 | **Encoder wire fatigue** — 5 hand-soldered joints flexing on every open | Med | Med | Strain-relieve with VHB 5 mm from the joint. Route with slack. Use a JST connector between shell halves so you can open it without stressing wires. |
| 9 | **OLED glass cracks** during assembly | Med | High | Handle by the PCB edges only. Bond to the panel with tape, never pressure. Buy a spare display *with your first order* — shipping time is your real enemy. |
| 10 | **Charge termination corrupted by load sharing** | Med | Low | Fixed by the Schottky topology (§6). Verify by charging with the device switched off and confirming it terminates. |
| 11 | **Scope creep** (the accelerometer, the app, the second screen…) | **High** | Med | The Never list in §15 is a contract with yourself. Re-read it weekly. |
| 12 | **OLED burn-in** over months of a static UI | Med | Low | §9.5. Also makes the aesthetic better. |
| 13 | **Fake trend numbers challenged in review** | Med | Med | Either source `delta` honestly or replace it with a 3-level glyph (§10.2). Don't print invented precision. |
| 14 | **LiPo thermal/mechanical incident** | Low | **Severe** | Protected cell only. Printed pocket, no compression, no screws through it. 350 mA charge. Never charge unattended overnight during the build phase. Don't put a swollen cell back in the box — retire it. |
| 15 | **Only one person ever tests it (you)** | **High** | High | 8 users is in the V1 scope for a reason. Your own opinion of your own interaction model is worth almost nothing, and reviewers know that. |


---

## 17. BUILD ORDER

Ordered by **dependency**, not by date. Each stage has an exit test — do not proceed until it passes. The single most important rule: **the experience is finished in software before you cut a single piece of plastic.**

### S0 · Paper (before you spend anything)

Draw all 8 screens at 128×96, **1:1 scale**, on paper or in Figma. Print them. Cut them into cards. Hand the deck to 3 people and have them "turn a knob" (a bottle cap) while you flip cards.

- **Exit test:** 3 of 3 people understand `rotate = browse` and `press = select` with no explanation, and at least 2 discover long-press-for-back when asked to "go back."
- **Why first:** paper is where you'll discover that 4 lines of text don't fit and that "Trending vs Discover" confuses people. Discovering that on paper costs an hour; discovering it after assembly costs a rebuild.

### S1 · Bench mule — display up

C3 + OLED on a breadboard. I²C scan (expect `0x3C`). Get U8g2 drawing. Identify the controller empirically (§3.1). **Also: measure Wi-Fi range at your actual usage distance, and measure the enclosure's walls with calipers.**

- **Exit test:** "MOOKS." renders in your chosen font; you can state with certainty which controller and which interface you have; you know your actual wall thickness.

### S2 · The whole experience, on the bench, with fake data ← **the critical milestone**

Encoder driver (ISR + table + RC filter). Screen base class + router. All screens navigable. `drop.json` compiled in as a hardcoded string. No Wi-Fi, no battery, no box.

- **Exit test:** you can run the entire 20-second loop from §12 on a breadboard, and it already feels good. **If it doesn't feel good here, no amount of enclosure work will save it.**
- **This is where you should spend the most time.** Everything after this is plumbing.

### S3 · Content and network

Build the Sheet → CI → static JSON pipeline. HTTPS GET with ETag. LittleFS cache. Offline mode. Then **write 30 days of real content** — do it now, while you still have energy, not the night before the demo.

- **Exit test:** pull the router's plug mid-session and the device keeps working with cached content, showing an offline glyph, with no crash and no blank screen.

### S4 · Provisioning

SoftAP + captive portal + QR on screen. Menu → Wi-Fi. Factory reset.

- **Exit test:** a person who has never seen the device gets it onto *their* Wi-Fi, unassisted, in under 3 minutes.

### S5 · Power

Battery + TP4057 + Schottky + bulk cap + switch, still on the bench. **Measure current in every state with a multimeter** (or a USB power meter and a 100 Ω shunt). Implement sleep, wake, battery states.

- **Exit test:** measured deep sleep < 100 µA; device survives a 4-hour continuous browse; it charges to termination while switched off; it runs while plugged in; the battery-low ladder in §7 works when you fake the ADC values.
- **Do not proceed to mechanical work until these numbers are real.** They determine whether your product claim is "weeks" or "hours."

### S6 · Mechanical

Cardboard mock-up of the depth stack first. Then: print the chassis, laser-cut and back-mask the acrylic panel, cut the shell's side apertures, fit the ballast, fit the knob, assemble.

- **Exit test:** it closes without forcing, nothing rattles when shaken, the knob has no wobble, no wire is under tension, and the front face shows only screen + knob + wordmark.

### S7 · Polish pass

Screen timeout, dim/fade, boot animation, burn-in mitigations, card transitions, the end-of-day card, error toasts.

- **Exit test:** you use it yourself for **7 consecutive days** without touching the code. Log every annoyance in a notes file. This log is portfolio material.

### S8 · User testing (do not skip, do not shortcut)

**8 people, 15 minutes each.** Three tasks: (1) find something you'd try, (2) save it, (3) get back to the start. **Say nothing.** Film hands only, with permission. Record: time to first discovery, whether they found long-press unaided, where they hesitated, and — the money question — *"would you keep this on your desk?"*

- **Exit test:** ≥6 of 8 complete all three tasks without help, and you have a written list of the top 5 frictions.

### S9 · Iterate

Fix the **top 3** frictions only. Re-test with 3 new people. **Document the before/after** — this comparison is the single most valuable artefact in the whole project for an Academy application, because it's the part almost nobody does.

### S10 · Story

Product photos on a plain background with one hard light. Exploded chassis render. A 30-second video of the loop. A written case study structured as problem → insight → constraint → decision → test → change → result. The SwiftUI simulator (§20).

**Ordering rules, stated plainly:** S2 before S6 (experience before enclosure). S5 before S6 (electrical truth before you commit geometry). S3's content writing before S7 (the boring work while you're fresh). S8 before S9, always, and never in the same week as your deadline.

---

## 18. PROCUREMENT

Exact search strings and the specs that matter. **Buy two of every fragile or cheap item** — shipping time is the dominant risk in a student build.

| Part | Search string | Must-have specs | Qty |
|---|---|---|---|
| **Display (recommended)** | `1.32 inch OLED module 128x96 SSD1327 16 gray SPI` | Module ~34.3 × 30.5 mm, active 26.86 × 20.14 mm, 7-pin, **greyscale**, 3.3 V | 2 |
| **Display (fallback/mule)** | `1.3 inch OLED 128x64 I2C SH1106 4pin white` | 4-pin = I²C, address 0x3C, 3.3 V tolerant | 2 |
| MCU | `ESP32-C3 SuperMini development board USB-C` | **Check the LDO marking is ME6211 or equivalent LDO, not AMS1117.** Native USB, no CH340 | 2 |
| Encoder | `EC11 rotary encoder 15mm shaft push switch 20 detent vertical` | 11 mm body, **15 mm** shaft (not 20), D-shaft or knurled, 20 detents, 7 mm threaded bushing | 3 |
| **Knob** | `aluminum knurled knob 16mm 6mm D shaft potentiometer black anodized` | **Aluminium, not plastic.** Ø16–18 mm, 6 mm bore, set screw, matte black or brushed | 2 |
| Battery | `3.7V 700mAh lipo 603040 protected JST PH 2.0` | 6 × 30 × 40 mm, **integrated protection PCM**, JST-PH 2.0, ≥1 A discharge | 1 (+1 spare, stored at 3.8 V) |
| Charger | `TP4057 lithium charging module 1S with protection small` | TP4057 (SOT23-6), programmable current — target **350 mA**, board <20 × 14 mm | 3 |
| Schottky | `SS14 Schottky diode` or `1N5819` | Vf ≤0.35 V @ 100 mA, ≥1 A | 10 |
| Bulk cap | `220uF 6.3V low ESR SMD electrolytic` + `10uF 0805 X7R ceramic` | Low ESR matters more than the exact value | 5 each |
| Switch | `SS-12D00 mini slide switch SPDT 3 pin` or `MSK-12C02` | Body ≤8 × 4 × 6 mm, SPDT, ≥300 mA | 5 |
| Wire | `30AWG silicone wire 5 colors flexible` | **Silicone jacket** (stays flexible), 30 AWG, stranded | 1 set |
| Resistors | `1M ohm 0805 resistor` `10k ohm 0805` | For the divider (2 × 1 M) and the encoder RC filter (2 × 10 k) | 20 |
| Caps (filter) | `100nF 0805 ceramic capacitor` | Encoder filter + ADC filter | 20 |
| NFC | `NTAG213 NFC sticker 25mm` | NTAG213, writable, thin | 5 |
| Panel | `2mm black cast acrylic sheet A5` | **Cast**, not extruded (cast laser-cuts cleanly) | 2 sheets |
| Ballast | `steel plate 60x35x2mm` or `brass sheet 2mm` | ~30 g; brass is nicer, steel is cheaper | 1 |
| Tape | `3M VHB double sided tape 1mm` · `Kapton tape 10mm` · `black double sided tape 0.1mm` | For mounting, isolation, and display bonding respectively | 1 each |
| Fasteners | `M2.5 black oxide hex socket screw assortment 4-10mm` + `M2 self-tapping plastic screws` | Hex, black oxide | 1 set |
| Feet | `1mm black silicone bumper feet self adhesive` | — | 1 set |
| Connectors | `JST PH 2.0 2-pin` + `JST GH 1.25 7-pin` (if SSD1327) + `6-pin JST SH 1.0` | For battery, display, and the shell-to-shell umbilical | 1 set each |
| Enclosure | your VBM-X1 | **Buy two** — one is a machining sacrifice | 2 |

**Tools you'll regret not having:** digital calipers (non-negotiable), a step drill bit set, a fine file set, wet-sanding paper 400/600/1000, a temperature-controlled iron with a fine tip, flux, 0.6 mm solder, tweezers, a multimeter with µA range (or a USB power meter), and helping hands.

**Things not to buy:** a TP4056 module (bigger than the TP4057 for no benefit here), a fuel-gauge breakout, an LED, a haptic motor, a larger battery, a second display size "just to compare" — buy the two named above and commit.

---

## 19. TEST PLAN

Written as pass/fail so you can actually run it, and so the results are quotable in your case study.

### Electrical / power

| Test | Method | Pass criterion |
|---|---|---|
| Deep-sleep current | Multimeter in series on the battery lead, device asleep, POW LED removed | **< 100 µA** |
| Active current, screen on, radio off | Same, browsing cached content | < 40 mA |
| Wi-Fi fetch burst | USB power meter or scope across a 1 Ω shunt | Peak < 450 mA; no rail dip below 3.0 V |
| Brownout margin | Bench supply in place of the battery, sweep 4.2 → 3.3 V while forcing repeated fetches | No reboot above **3.5 V** |
| Rail integrity | Scope on 3.3 V during Wi-Fi TX | Ripple < 150 mV p-p |
| Battery-low ladder | Bench supply, step through the §7 thresholds | Each behaviour triggers at the right voltage, in order, once |

### Charging

| Test | Method | Pass criterion |
|---|---|---|
| Charge current | Meter in series with the cell | 300–400 mA in CC phase |
| Termination | Charge from 3.6 V to full, device **off** | Current tapers and stops; cell rests at 4.15–4.20 V |
| Charge with load | Charge with the device on and Wi-Fi fetching | Both work; cell still reaches full |
| No reverse flow | Meter on the switch branch with USB connected | No current flowing *into* the cell around the charger |
| Thermal | IR thermometer or finger-test on the charger IC and the cell after 30 min @ 350 mA | **Cell < 40 °C**, charger IC < 70 °C. Fail = reduce charge current. |
| Full cycle time | Empty → full | < 3 h |

### Radio

| Test | Method | Pass criterion |
|---|---|---|
| Range | Walk away from the AP in a normal room | Reliable fetch at ≥ 8 m through one wall |
| Assembled vs bare | Same test, board in the closed enclosure with ballast fitted | **< 6 dB degradation.** Bigger drop = the ballast or a wire is in the antenna field; move it. |
| Cold-start time | Power-on to content refreshed | < 6 s |
| Bad-network behaviour | Wrong password saved; AP powered off mid-fetch; captive-portal-style network | Never blocks the UI; never crashes; clear recovery path every time |
| Reconnect | Kill the AP for 10 min, restore it | Reconnects with backoff, no reboot needed |

### Display

| Test | Method | Pass criterion |
|---|---|---|
| Interface/controller ID | I²C scan + the 2 px offset test | Positively identified; documented in the repo README |
| Legibility | 3 people read every screen at 40 cm in normal room light | 100% correct reading, no squinting |
| Contrast in sunlight | Take it outside | Titles readable in shade; document the limit honestly |
| Frame timing | Time a full render | < 30 ms so transitions feel instant |
| Burn-in mitigations | Force 1 h continuous on | Timeout, jitter, and contrast all confirmed active |
| Alignment | Look at the assembled front face straight on and at 30° | Active area centred within **0.3 mm**; no PCB or cutout edge visible at any angle |

### Encoder

| Test | Method | Pass criterion |
|---|---|---|
| Detent accuracy | Rotate exactly 50 detents each way, 5 trials | **50/50 counts, zero phantom steps, zero direction reversals** |
| Fast rotation | Spin as fast as you physically can | No missed or spurious counts |
| Press discrimination | 20 short presses, 20 long presses | 40/40 classified correctly |
| Press-while-rotating | Deliberately press mid-rotation | No spurious selection |
| Wake | Press from deep sleep, 20 times | 20/20 wake; content on screen in < 400 ms |
| Endurance | 2,000 detents + 200 presses | No degradation, no loosening, knob still true |

### Enclosure / mechanical

| Test | Method | Pass criterion |
|---|---|---|
| Rattle | Shake hard next to your ear | Silent |
| Knob wobble | Lateral force on the knob | < 0.3 mm play; no panel flex |
| Drop | 1 m onto carpet, 3 times (accept the risk) | Nothing opens, cracks, or stops working |
| Pocket test | Carry it in a pocket for a day | No accidental wake, no scratches on the panel, no discomfort |
| Assembly repeatability | Fully disassemble and reassemble twice | < 10 min each, no damage, no wire stressed |
| Mass and density | Kitchen scale | **≥ 95 g** (≈0.9 g/cm³) |

### Battery life (the claim you'll be quoted on)

| Test | Method | Pass criterion |
|---|---|---|
| Continuous browse | Full charge → browse until shutdown, screen on, radio off | **≥ 10 h** |
| Realistic duty cycle | Normal use, logged, over 2 weeks | Extrapolates to **≥ 3 weeks** |
| Standby only | Charge, sleep, leave for 7 days untouched | **< 4%** consumed |

### Usability (§S8) — the tests that actually matter

| Metric | Target |
|---|---|
| Understands rotate + press with **zero** instruction | ≥ 7 / 8 |
| Discovers long-press-for-back unaided | ≥ 4 / 8 (if lower, add a one-time hint card — do **not** add a button) |
| Time to first "I'd try that" | < 30 s |
| Completes save-and-return unaided | ≥ 6 / 8 |
| Correctly describes what MOOKS is for, after 2 min of use | ≥ 6 / 8 |
| **"Would you keep this on your desk?"** | ≥ 5 / 8 — and record the *reasons* from everyone who says no; those quotes are the most useful data in the entire project |

---

## 20. APPLE DEVELOPER ACADEMY VALUE

### What this project already demonstrates well

| Competency | Where it shows | How to make it visible |
|---|---|---|
| **Problem identification** | The behaviour you're targeting (aimless scroll-discovery) is real and personally observed | Open with the behaviour, not the device. Show a screenshot of your own Screen Time. |
| **Product thinking** | Your non-goals list; the finiteness decision | Present the Never list. Cutting features is more impressive than adding them. |
| **Interaction design** | One control, three gestures, zero menus before content | Show the paper prototype photos *and* the final. The delta is the story. |
| **Industrial design** | Turning a $2 PVC box into a considered object | Before/after photos. The exploded chassis view. |
| **Embedded engineering** | Power path, sleep architecture, ISR-based encoder, cache-first rendering | One diagram + one number: "50 µA asleep → charge monthly." |
| **Backend & API** | Static-JSON-plus-CDN with conditional GET | Explain *why* you didn't build a server. Restraint reads as seniority. |
| **Iteration** | S8 → S9 | The before/after friction table. **This is the single most valuable slide you will have.** |
| **Storytelling** | The "mook" etymology; "five things, then you're done" | One sentence you can say without notes. |

### The gap you should close — and it's an important one

**This project has no Swift in it.** The Apple Developer Academy is fundamentally about building on Apple platforms — the Academy's own framing is about students creating apps that address personal, community, and global challenges ([Apple Newsroom](https://www.apple.com/my/newsroom/2025/03/apple-opens-fourth-apple-developer-academy-in-indonesia/)), and the Indonesian campuses run Swift-centred curricula ([Academy @ BINUS](https://developeracademy.apps.binus.ac.id/), [Academy @ UC](https://appledeveloperacademy.uc.ac.id/)). A beautiful ESP32 device with zero Apple-platform code is an odd fit for that room.

**The fix costs you a weekend and pays for itself three times over: build a SwiftUI "MOOKS Simulator."**

A macOS/iPadOS app that renders the exact 128×96 UI at 4× scale, with a draggable knob, driven by the same JSON schema.

Why this is the highest-ROI addition in this whole review:

1. **It's a genuine design tool.** You'll iterate the UI 10× faster in SwiftUI than by reflashing firmware, and you'll catch layout bugs before they reach the device.
2. **It's your demo insurance.** Risk #3 in §16 is demo failure. If the hardware dies in an interview, you open the simulator on an iPad and the demo continues. That alone justifies it.
3. **It puts Swift in the portfolio** without violating your "no mobile app dependency" non-goal — this isn't a dependency, it's a companion and a tool.
4. **It's a better story than either artefact alone:** *"I designed the interface in SwiftUI, then made the hardware match it, pixel for pixel."* That's a designer-engineer sentence, and it's exactly what the Academy is looking for.

Second, smaller recommendation: **frame the case study in Challenge Based Learning terms**, since that's the Academy's pedagogy. Big Idea → Essential Question → Challenge:

- **Big Idea:** Attention.
- **Essential Question:** *What would discovery feel like if it were designed to end?*
- **Challenge:** Build something that helps one person find one thing worth trying, then stops.

Speaking their framework fluently, unprompted, is a strong signal.

### The three things to lead with

1. **The end-of-day card.** Show the device saying "That's all for today." Nobody else's demo does this, and it makes the philosophy tangible in two seconds.
2. **The iteration table.** Eight users, five frictions, three fixes, measured improvement. This is the part almost every student portfolio is missing.
3. **The object in someone's hand.** Weight, knob, screen. Let the interviewer turn the knob before you explain anything.

### One honest caution

Do not present MOOKS as a startup or claim a market. It's a **research probe** — an object built to answer a question about attention and discovery. That framing is more credible, more interesting, and it makes "only I use it" a legitimate result rather than a failure to admit.

---

## 21. FINAL RECOMMENDED SPEC

```
╔══════════════════════════════════════════════════════════════════════════╗
║  MOOKS V1                                                                ║
║  "Five things. Then you're done."                                        ║
╚══════════════════════════════════════════════════════════════════════════╝

FORM
  Enclosure          VBM-X1 PVC, 77 × 51 × 27 mm, matte graphite
                     (wet-sanded + matte clear, or 3M matte black vinyl)
  Front panel        2 mm black CAST acrylic, back-masked, press-fit,
                     display bonded behind a 27.4 × 20.7 mm window
  Internal chassis   3D-printed PETG cartridge, routed wire channels
  Ballast            60 × 35 × 2 mm steel/brass in the base (~33 g)
  Target mass        95–105 g   →  ~0.9 g/cm³
  Front face         display + knob + "MOOKS." (6 pt, 60% grey). Nothing else.
  Fasteners          M2.5 black-oxide hex, bottom face only
  V2 target          70 × 45 × 18 mm, custom PCB

DISPLAY
  Recommended        1.32" OLED, 128 × 96, SSD1327, 16-level greyscale, SPI
                     module 34.3 × 30.5 mm · active 26.86 × 20.14 mm
  Fallback / mule    1.3" OLED, 128 × 64, SH1106, I²C @ 0x3C
                     (your current part — it IS I²C, not SPI)
  Contrast           ~50%, dark-dominant layout, 45 s timeout, 1 px jitter

MCU
  ESP32-C3 SuperMini · 22.5 × 18 × 4.5 mm · Wi-Fi 2.4 GHz · native USB-C
  VERIFY: LDO is ME6211-class (NOT AMS1117) · 5V-pin/VBUS topology
  MODIFY: desolder the POW LED · no pin headers · ≥10 mm antenna keep-out
  V2: ESP32-C3-MINI-1 on a custom 4-layer PCB

INPUT — one control, three gestures
  EC11 incremental encoder, 15 mm shaft, 20 detents, integrated switch
  Aluminium knurled knob, Ø16–18 mm, 6 mm D-shaft, set screw
  RC filter 10 kΩ + 100 nF per channel · ISR + quadrature LUT
  ROTATE = browse · PRESS = select / save · LONG PRESS (500 ms) = back
  Switch on an RTC-capable GPIO = deep-sleep wake ("press to wake")

POWER
  Cell               3.7 V, ~700 mAh, 603040, INTEGRATED PROTECTION, JST-PH
  Charger            TP4057 (SOT23-6) @ 350 mA from USB-C VBUS
  Power path         Schottky (SS14) from battery to the 5V pin
                     → runs while charging, clean charge termination
  Regulation         on-board ME6211 LDO → 3.3 V
  Decoupling         220 µF low-ESR + 10 µF ceramic at the board  ← mandatory
  Sense              2 × 1 MΩ divider + 100 nF → ADC1 (GPIO0–4)
  Switch             SS-12D00 mini slide, REAR face, service cutoff,
                     wired between battery and load (charging works when off)
  Thresholds         warn 3.60 V · radio off 3.50 V · sleep 3.45 V
  Fuel gauge         NOT used — 4 discrete states, never a percentage
  V2                 BQ25185 power-path + TPS62740 buck + NTC + USB-C ESD

RUNTIME  [ESTIMATES]
  Deep sleep         ~50 µA        → months (self-discharge limited)
  Browsing, radio off ~33 mA       → ~17 h continuous
  Per fetch          ~0.13 mAh
  Typical use        ~3.5 mAh/day  → charge roughly once a month
  Charge time        ~2.5 h @ 350 mA

CONNECTIVITY
  Wi-Fi 2.4 GHz · HTTPS with pinned root CA · BLE unused in V1
  Provisioning: SoftAP "MOOKS-setup" + captive portal,
                joined via a QR code rendered on the OLED
  NFC: passive NTAG213 under the rear label → setup URL. Optional. Zero deps.

BACKEND
  V1     Google Sheet → GitHub Action (validate + build) → static JSON on a CDN
         Conditional GET with If-None-Match · CI-enforced string length limits
  V1.5   Cloudflare Worker: /drop, /item, /saves, /link/{short}, /fw/latest
  Cache  NVS (creds, 30 saves, tag affinity) + LittleFS (last 2 drops)
  Rank   editorial − 8×seen + 3×tag_affinity − 40×saved.  No ML in V1.

FIRMWARE
  PlatformIO + Arduino-ESP32 · U8g2 · ArduinoJson (streaming + filter)
  core / hal / net / data / ui / app  — no single .ino
  Network on its own FreeRTOS task; UI task NEVER blocks
  Three orthogonal state machines: POWER · NET (a status, not a screen) · UI
  Render on dirty only · no heap allocation after boot · no String in render
  Cached content on screen in < 300 ms of wake, always

UX
  IA         TODAY (5 cards) → DETAIL → HANDOFF · MENU: Saved / Nearby /
             Wi-Fi / About.  No root menu. No Trending-vs-Discover split.
  Loop       pick up → press → 5 cards → open one → save → "That's all
             for today." → put down → return tomorrow
  Handoff    QR on screen → short link → Maps/recipe on the phone
  Content    5 hand-curated items/day, one city, hard end state
  Type       3 tiers by grey level: label 40% / body 75% / title 100%
             left-aligned, one accent, 4 px margins, one card per screen

CORE PROMISE
  It shows you five things worth eating, hands the best one to your phone,
  and then tells you it's finished.
```

---

## APPENDIX — YOUR 30 QUESTIONS, ANSWERED DIRECTLY

| # | Question | Answer |
|---|---|---|
| 1 | Is 77 × 51 × 27 viable? | Yes — and it's *too roomy*, which is its own problem. Add ballast (§1). |
| 2 | Usable internal volume? | ~72.6 × 46.6 × 22.6 mm gross; front-panel safe window **62 × 36 mm**. **[EST]** |
| 3 | Does the 35.5 × 33.7 OLED fit? | Yes, with ~1 mm vertical margin per side. Marginal but workable. |
| 4 | EC11 alongside it? | Yes — 26.5 mm of width remains; a Ø16–18 mm knob fits. |
| 5 | 400–550 mAh LiPo? | Yes, easily. You could fit 1000 mAh. |
| 6 | Battery dimensions to search? | **603040** (~700 mAh) or **503035** (~500 mAh), protected, JST-PH. |
| 7 | Is 27 mm enough depth? | Yes — 22 mm of 22.6 mm used. **But only if you use no pin headers.** |
| 8 | Stacking strategy? | Display+encoder on the top shell; battery, MCU, charger, ballast on the bottom. |
| 9 | Top shell? | Front panel, display, encoder. |
| 10 | Bottom shell? | MCU, battery, charger, switch, ballast. |
| 11 | Battery under the OLED? | Yes — two flat parts nest. Kapton between, 0.5 mm clearance. |
| 12 | ESP32 beside or under the display? | **Beside** — USB-C must reach a wall, and the antenna needs distance from battery and ballast. |
| 13 | Is the OLED too large? | Not too large — **too inefficient**: only 36% of its footprint is visible pixels. |
| 14 | Switch to a smaller OLED? | Yes: **1.32" 128×96 SSD1327** — smaller module, +50% pixels, 16 greys. |
| 15 | Rectangular vs square-ish? | For a card UI, ~4:3 beats 2:1. 128×96 is the better shape. |
| 16 | Is EC11 too large? | No. Keep it. |
| 17 | Low-profile encoder? | Not needed, and it would cost you detent feel — which is the product. |
| 18 | Physical power switch necessary? | Not strictly. Keep a **rear service cutoff** for V1; daily on/off is long-press. |
| 19 | Smallest sensible charging circuit? | TP4057 in SOT23-6 @ 350 mA. Your instinct was right. |
| 20 | Modules or custom PCB for V1? | **Modules.** Custom PCB for V2. |
| 21 | What should the PCB look like? | 66 × 41 mm, 4-layer, C3-MINI-1 + BQ25185 + buck + USB-C ESD. See §4. |
| 22 | USB-C position? | **Bottom face**, centred/slightly left. Chamfered slot. One port for both jobs. |
| 23 | Safe battery mounting? | Printed pocket, 0.5 mm clearance, VHB strip, swell allowance, no screws through it, protected cell only. |
| 24 | Heat and charging safety? | 350 mA charge, ≥100 mm² copper or thermal contact for the charger IC, cell <40 °C, NTC on the V2 PMIC. |
| 25 | Charging while Wi-Fi is active? | Works — VBUS powers the load, the charger works independently. Enabled by the Schottky (§6). |
| 26 | How should it sleep? | 45 s → fade + light sleep; 3 min → deep sleep. Wake on encoder press (RTC GPIO). |
| 27 | Realistic battery life? | ~17 h continuous browsing; **~1 month of typical use**. **[EST]** |
| 28 | Startup experience? | Press → wordmark fades in (120 ms) → cached TODAY at 300 ms → network updates in place. **Never a blocking "Connecting" screen.** |
| 29 | Provisioning without a touchscreen? | SoftAP + captive portal, entered by scanning a QR on the OLED. |
| 30 | How does the user enter credentials? | On their phone, in the captive portal. Never by rotating through an alphabet. |

---

## THE FIVE CHANGES THAT MATTER MOST

If you act on nothing else:

1. **Make the content finite** — 5 items and a hard "that's all for today." This is the product, and it's free.
2. **Add the QR handoff** — it answers "why not my phone" with zero hardware.
3. **Cut a custom acrylic front panel** instead of drilling the box, and buy an aluminium knob. These two things are 80% of the perceived quality.
4. **Fix the power path** — one Schottky diode plus a 220 µF bulk capacitor. Without them you get corrupted charging and random reboots.
5. **Build a SwiftUI simulator** — it's your design tool, your demo insurance, and the Swift in a portfolio that currently has none.

---

*Sources consulted for component dimensions and electrical characteristics: [Raystar 2.42" REH012864H](https://www.raystar-optronics.com/oled-graphic-display-module/REH012864H.html), [Raystar 1.54" REA012864A](https://www.raystar-optronics.com/oled-graphic-display-module/REA012864A.html), [Winstar 1.54" WEO012864A](https://www.winstar.com.tw/products/oled-module/graphic-oled-display/spi-oled-128x64.html), [Waveshare 1.32" SSD1327 module](https://www.waveshare.com/1.32inch-oled-module.htm), [Waveshare 1.5" OLED module wiki](https://www.waveshare.com/wiki/1.5inch_OLED_Module), [mischianti.org ESP32-C3 SuperMini pinout & specs](https://mischianti.org/esp32-c3-super-mini-high-resolution-pinout-datasheet-and-specs/), [Arduino Forum — SuperMini LDO & battery discussion](https://forum.arduino.cc/t/charging-lithium-ion-battery-using-the-usb-port-on-esp32-c3-supermini-with-tp4056-and-powering-the-esp32-with-the-battery-when-not-connected-via-usb/1302012/9), [ALPS EC11 datasheet (Mouser)](https://www.mouser.com/datasheet/2/15/EC11-1370808.pdf), [TP4057 datasheet](https://mm.digikey.com/Volume0/opasdata/d220001/medias/docus/5010/TP4057.pdf), [TOPPWR charger IC listing](http://toppwr.com/eproduct), [TP4056/TP4057/MCP73831 comparison](https://budgetlightforum.com/t/differences-between-tp4056-tp4057-and-mcp73831-2-controllers-for-charging/15577), [Apple Newsroom — Developer Academy Indonesia](https://www.apple.com/my/newsroom/2025/03/apple-opens-fourth-apple-developer-academy-in-indonesia/). Content from these sources was paraphrased and summarised for compliance with licensing restrictions; enclosure interior dimensions and all runtime figures are my own estimates and are labelled as such.*
