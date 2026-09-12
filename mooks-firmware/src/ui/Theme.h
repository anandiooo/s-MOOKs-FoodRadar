#pragma once
#include <stdint.h>

// Mirror of mooks-sim/Sources/MooksUI/Theme.swift.
//
// These two files must agree. The simulator is where you iterate the design; this
// is where it ships. If you change a coordinate here without re-rendering the
// simulator, the mockups in your portfolio stop describing the product you built.

namespace Theme {

// Grey levels, 0...15. Hierarchy comes from BRIGHTNESS, not just size — which is
// the entire reason to spend money on a 16-level SSD1327 over a 1-bit SH1106.
constexpr uint8_t GREY_PRIMARY = 15;   // titles, accents, selected row
constexpr uint8_t GREY_BODY    = 11;   // the sentence that rewards the press
constexpr uint8_t GREY_LABEL   = 6;    // section labels, counters, metadata
constexpr uint8_t GREY_QUIET   = 4;    // rules, unselected rows, hints
constexpr uint8_t GREY_DIM     = 8;    // unselected menu rows

// Geometry
constexpr int MARGIN        = 4;
constexpr int CONTENT_LEFT  = 4;
constexpr int CONTENT_RIGHT = 124;
constexpr int CONTENT_WIDTH = CONTENT_RIGHT - CONTENT_LEFT;   // 120

// Vertical anchors, measured from the simulator renders.
constexpr int HEADER_Y      = 4;
constexpr int TITLE_ZONE_Y  = 20;
constexpr int TITLE_ZONE_H  = 38;
constexpr int TITLE_LINE_H  = 16;
constexpr int HOOK_Y        = 62;
constexpr int BODY_LINE_H   = 10;
constexpr int FOOTER_Y      = 85;

// Detail screen
constexpr int DETAIL_TITLE_ZONE_Y = 14;
constexpr int DETAIL_TITLE_ZONE_H = 34;
constexpr int DETAIL_RULE_Y       = 50;
constexpr int DETAIL_WHY_Y        = 56;
constexpr int DETAIL_FOOTER_Y     = 88;

// Small-caps labels are letterspaced by one pixel.
constexpr int LABEL_TRACKING = 1;

} // namespace Theme
