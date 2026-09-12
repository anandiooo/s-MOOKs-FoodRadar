#pragma once
// Every tunable in one file. If a number appears in two places, one of them is wrong.

// ─────────────────────────────────────────────────────────────────────────────
//  PIN MAP  —  ESP32-C3 SuperMini
// ─────────────────────────────────────────────────────────────────────────────
//
//  READ THIS BEFORE WIRING. Two constraints drive every choice below:
//
//  1. STRAPPING PINS: GPIO2, GPIO8 and GPIO9 are sampled at reset to decide boot
//     mode. GPIO9 is the boot/download strap. An encoder is a mechanical device
//     that can be sitting in ANY state at power-on, so putting an encoder channel
//     on a strapping pin means the device sometimes refuses to boot — an
//     intermittent fault that looks like a dead board. Never do it.
//
//  2. DEEP-SLEEP WAKE: only GPIO0...GPIO5 are RTC-capable on the C3, so only those
//     can wake the chip from deep sleep. The encoder switch must live in that range.
//
//  Result: encoder on 0/1/3, battery sense on 4, display on 5/6/7/10.

#define PIN_ENC_A        0   // RTC-capable, not a strap
#define PIN_ENC_B        1   // RTC-capable, not a strap
#define PIN_ENC_SW       3   // RTC-capable → this is the deep-sleep wake source
#define PIN_BATT_SENSE   4   // ADC1_CH4. ADC2 is unusable while Wi-Fi is up.

#define PIN_OLED_DC      5
#define PIN_OLED_SCK     6
#define PIN_OLED_MOSI    7
#define PIN_OLED_CS     10
// Display RESET is deliberately NOT wired to a GPIO. Use a 10k pull-up to 3V3 and
// a 100nF cap to GND on the module's RES pin: the RC gives a clean power-on reset,
// frees a GPIO, and removes one wire from a hand-built assembly.
#define PIN_OLED_RST    U8X8_PIN_NONE

// ─────────────────────────────────────────────────────────────────────────────
//  DISPLAY
// ─────────────────────────────────────────────────────────────────────────────
#define DISPLAY_W       128
#define DISPLAY_H        96
// 0x00...0xFF. ~50% is plenty on a dark layout and roughly halves both current
// draw and burn-in rate. Full brightness is never the right answer here.
#define DISPLAY_CONTRAST 0x80

// ─────────────────────────────────────────────────────────────────────────────
//  INPUT
// ─────────────────────────────────────────────────────────────────────────────
#define ENC_LONG_PRESS_MS      500   // fires on threshold crossing, not on release
#define ENC_FACTORY_RESET_MS 10000   // held during boot
#define ENC_DEBOUNCE_MS          5
// Detents per UI step. EC11 is usually 20 detents/rev with 2 edges each; if the UI
// moves two items per click, set this to 2 rather than changing the driver.
#define ENC_STEPS_PER_ITEM       1

// ─────────────────────────────────────────────────────────────────────────────
//  POWER  (review §7)
// ─────────────────────────────────────────────────────────────────────────────
#define SCREEN_TIMEOUT_MS        45000UL   // → fade, light sleep
#define DEEP_SLEEP_TIMEOUT_MS   180000UL   // → deep sleep
#define BURN_IN_JITTER_MS        30000UL   // 1px layout shift while on

// Battery voltage thresholds, millivolts. Derived in review §6: with a Schottky in
// the battery path and the ME6211's dropout, the 3.3V rail can no longer support
// Wi-Fi TX bursts below roughly 3.5V.
#define BATT_FULL_MV             4100
#define BATT_GOOD_MV             3850
#define BATT_WARN_MV             3600   // show the warning card once
#define BATT_RADIO_OFF_MV        3500   // cached content only from here down
#define BATT_SLEEP_MV            3450   // refuse to stay awake
#define BATT_RESUME_MV           3600   // must charge past this to wake again

// 2 x 1MΩ divider → the ADC sees half the cell voltage.
#define BATT_DIVIDER_RATIO       2.0f
#define BATT_ADC_SAMPLES         5      // median, not mean — rejects Wi-Fi spikes

// ─────────────────────────────────────────────────────────────────────────────
//  NETWORK
// ─────────────────────────────────────────────────────────────────────────────
#define API_ORIGIN            "https://mooks.pages.dev"
#define API_MANIFEST_PATH     "/v1/manifest.json"
#define API_DROPS_PATH        "/v1/drops/"
#define HTTP_TIMEOUT_MS       8000
#define WIFI_CONNECT_TIMEOUT_MS 10000
#define WIFI_MAX_ATTEMPTS     3
#define PROVISION_AP_SSID     "MOOKS-setup"   // keep SHORT: it goes in a QR code

// How stale a cached drop may be before the UI admits it (review §10.3).
#define DROP_STALE_AFTER_MS   (36UL * 3600UL * 1000UL)

// ─────────────────────────────────────────────────────────────────────────────
//  STORAGE LIMITS  —  fixed sizes, so nothing allocates after boot
// ─────────────────────────────────────────────────────────────────────────────
#define MAX_ITEMS_PER_DROP    5
#define MAX_SAVED_ITEMS      30
#define MAX_TAG_AFFINITY     12

// Field capacities. These come from mooks-content/contract.json, which is itself
// derived from measured renders in mooks-sim. Do not "improve" them here — change
// the contract, re-run the simulator, then propagate.
#define LEN_ID            12
#define LEN_TITLE_LINE    21   // 20 chars + NUL
#define LEN_BODY_LINE     21
#define LEN_PLACE         21
#define LEN_ACCENT         9
#define LEN_LINK           5
#define MAX_TITLE_LINES    2
#define MAX_HOOK_LINES     2
#define MAX_WHY_LINES      3

// ─────────────────────────────────────────────────────────────────────────────
//  RANKING  (review §10.4) — a linear re-rank over five items. No ML in V1.
// ─────────────────────────────────────────────────────────────────────────────
#define RANK_SEEN_PENALTY      8
#define RANK_AFFINITY_WEIGHT   3
#define RANK_SAVED_PENALTY    40
