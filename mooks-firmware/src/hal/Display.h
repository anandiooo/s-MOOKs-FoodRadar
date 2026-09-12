#pragma once
#include <U8g2lib.h>
#include "../ui/Theme.h"

// The only module allowed to touch u8g2.
//
// ── An honest note about greyscale ──────────────────────────────────────────────
// The SSD1327 panel is 16-level greyscale, but U8g2 drives it as 1 bit per pixel.
// So on this backend, Theme's grey levels are THRESHOLDED: >= 8 draws, < 8 does not.
// The layout is correct and the hierarchy still reads through size and position,
// but the tonal hierarchy the design depends on is not there yet.
//
// To get true 16-level greys you swap the backend for Adafruit_SSD1327 (which
// exposes 4bpp) or LVGL with an I4 colour format. That is a deliberate V1.5 task,
// not a V1 blocker: ship the layout on U8g2 first, then upgrade the renderer behind
// this same API without touching a single screen file.
//
// That is why every drawing call takes a grey level even though this backend cannot
// honour it. The API is written for the display you are going to have.

class Display {
public:
    bool begin();

    void beginFrame();
    void endFrame();                     // pushes the buffer
    void setPowerSave(bool on);          // panel off, controller alive
    void setContrast(uint8_t c);

    // Burn-in mitigation: a 1px layout shift applied to every draw call.
    // Imperceptible, and it spreads wear across the pixels that are always lit.
    void setJitter(int8_t dx, int8_t dy) { _jx = dx; _jy = dy; }

    // ── Primitives (mirrors of MooksUI/FrameBuffer.swift) ──
    void text(int x, int y, const char* s, uint8_t grey, uint8_t scale = 1, int tracking = 0);
    void textRight(int right, int y, const char* s, uint8_t grey, uint8_t scale = 1, int tracking = 0);
    void textCentered(int y, const char* s, uint8_t grey, uint8_t scale = 1, int tracking = 0);
    int  textWidth(const char* s, uint8_t scale = 1, int tracking = 0) const;

    void hLine(int x, int y, int w, uint8_t grey);
    void vLine(int x, int y, int h, uint8_t grey);
    void fillRect(int x, int y, int w, int h, uint8_t grey);
    void strokeRect(int x, int y, int w, int h, uint8_t grey);
    void dottedHLine(int x, int y, int w, uint8_t grey, int step = 3);

    // Glyphs the fonts do not cover.
    void arrow(int x, int y, bool up, uint8_t grey);
    void steady(int x, int y, uint8_t grey);
    void chevron(int x, int y, uint8_t grey);
    void battery(int x, int y, int level, uint8_t grey);
    void offlineMark(int x, int y, uint8_t grey);

    /// Renders a real QR symbol. V1 draws a placeholder box with a caption so the
    /// layout is testable; wire in a QR encoder (e.g. ricmoo/QRCode) for V1.5.
    void qr(int x, int y, const char* payload, int moduleSize = 2);

private:
    bool inkFor(uint8_t grey) const { return grey >= 8; }
    void selectFont(uint8_t scale);

    int8_t _jx = 0, _jy = 0;
};

extern Display display;
