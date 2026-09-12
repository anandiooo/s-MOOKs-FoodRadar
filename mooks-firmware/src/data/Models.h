#pragma once
#include <Arduino.h>
#include "config.h"

// Fixed-size PODs. No String, no std::vector, no allocation after boot.
//
// Two reasons, both real on a device that must run for weeks:
//  1. Heap fragmentation. TLS wants 30-45KB of CONTIGUOUS heap for a handshake.
//     A fragmented heap fails that allocation after days of uptime, and the
//     symptom is "it stops syncing eventually", which is miserable to debug.
//  2. These structs are the render input. Fixed layout means the render path has
//     no failure mode.
//
// Note what is NOT here: no full sentences. The backend pre-wraps text into display
// lines (mooks-content/scripts/build.mjs), so the firmware carries no word-wrap
// code and cannot break its own layout. The server edits; the device draws.

enum class Glyph : uint8_t { None = 0, Up, Down, Flat };

struct Item {
    char id[LEN_ID] = {0};
    char kindLabel[8] = {0};                            // "DISH", "PLACE", ...
    char accent[LEN_ACCENT] = {0};                      // "238%", "RISING"
    Glyph glyph = Glyph::None;

    char titleLines[MAX_TITLE_LINES][LEN_TITLE_LINE] = {{0}};
    uint8_t titleLineCount = 0;

    char hookLines[MAX_HOOK_LINES][LEN_BODY_LINE] = {{0}};
    uint8_t hookLineCount = 0;

    char whyLines[MAX_WHY_LINES][LEN_BODY_LINE] = {{0}};
    uint8_t whyLineCount = 0;

    char place[LEN_PLACE] = {0};
    char link[LEN_LINK] = {0};

    // Local state, never sent by the server.
    bool seen = false;
    bool saved = false;

    bool valid() const { return id[0] != 0; }
    bool hasPlace() const { return place[0] != 0; }
    bool hasLink() const { return link[0] != 0; }
};

struct Drop {
    char dropId[11] = {0};      // YYYY-MM-DD
    char city[4] = {0};
    char etag[24] = {0};
    uint32_t fetchedAtEpoch = 0;
    Item items[MAX_ITEMS_PER_DROP];
    uint8_t count = 0;

    bool valid() const { return count > 0 && dropId[0] != 0; }
};

// Battery is reported as four states, never a percentage. With no coulomb counting
// and a load-dependent voltage curve, any percentage shown would be wrong in a way
// users notice immediately ("it said 40% yesterday, now it says 60%").
enum class BatteryState : uint8_t { Full = 4, Good = 3, Low = 2, Critical = 1, Charging = 5 };

enum class NetState : uint8_t { Offline, Connecting, Online, Syncing, Failed };
