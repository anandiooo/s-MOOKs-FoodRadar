#include "Encoder.h"
#include "../core/EventBus.h"
#include "config.h"
#include <driver/gpio.h>
#include <esp_sleep.h>

Encoder encoder;

QueueHandle_t EventBus::_q = nullptr;

namespace {

// Quadrature transition table.
//
// Index = (previous_state << 2) | new_state, where state = (A << 1) | B.
// A valid single step yields +1 or -1. An IMPOSSIBLE transition (both channels
// appearing to change at once, which is what bounce and missed interrupts look
// like) yields 0 instead of a guessed direction.
//
// That last property is the whole point: a naive "if A changed, check B" reader
// invents a step whenever it is confused, which is exactly why cheap knobs jump
// backwards. This table refuses to guess.
constexpr int8_t QUAD_LUT[16] = {
     0, -1, +1,  0,
    +1,  0,  0, -1,
    -1,  0,  0, +1,
     0, +1, -1,  0
};

volatile uint8_t  g_prevState = 0;
volatile int32_t  g_subSteps  = 0;   // raw quadrature edges
volatile int32_t  g_detents   = 0;   // whole detents, ready for the UI

// An EC11 emits 4 edges per detent. Accumulate and divide so one physical click is
// exactly one UI step regardless of how the interrupts land.
constexpr int8_t EDGES_PER_DETENT = 4;

} // namespace

void IRAM_ATTR Encoder::onQuadratureEdge() {
    const uint8_t a = (uint8_t)gpio_get_level((gpio_num_t)PIN_ENC_A);
    const uint8_t b = (uint8_t)gpio_get_level((gpio_num_t)PIN_ENC_B);
    const uint8_t state = (uint8_t)((a << 1) | b);

    const int8_t step = QUAD_LUT[(g_prevState << 2) | state];
    g_prevState = state;
    if (step == 0) return;          // invalid transition — refuse to guess

    g_subSteps += step;
    if (g_subSteps >= EDGES_PER_DETENT) {
        g_subSteps -= EDGES_PER_DETENT;
        g_detents++;
    } else if (g_subSteps <= -EDGES_PER_DETENT) {
        g_subSteps += EDGES_PER_DETENT;
        g_detents--;
    }
}

void Encoder::begin() {
    pinMode(PIN_ENC_A, INPUT_PULLUP);
    pinMode(PIN_ENC_B, INPUT_PULLUP);
    pinMode(PIN_ENC_SW, INPUT_PULLUP);

    g_prevState = (uint8_t)((digitalRead(PIN_ENC_A) << 1) | digitalRead(PIN_ENC_B));
    g_subSteps = 0;
    g_detents = 0;

    attachInterrupt(digitalPinToInterrupt(PIN_ENC_A), onQuadratureEdge, CHANGE);
    attachInterrupt(digitalPinToInterrupt(PIN_ENC_B), onQuadratureEdge, CHANGE);

    _lastLevel = digitalRead(PIN_ENC_SW);
}

int32_t Encoder::takeDelta() {
    noInterrupts();
    const int32_t d = g_detents;
    g_detents = 0;
    interrupts();
    return d / ENC_STEPS_PER_ITEM;
}

bool Encoder::isPressed() const {
    return digitalRead(PIN_ENC_SW) == LOW;
}

void Encoder::poll() {
    // Rotation
    const int32_t d = takeDelta();
    if (d != 0) EventBus::post(Ev::Rotate, d);

    // Button
    const uint32_t now = millis();
    const bool level = digitalRead(PIN_ENC_SW);

    if (level != _lastLevel && (now - _lastChangeAt) >= ENC_DEBOUNCE_MS) {
        _lastChangeAt = now;
        _lastLevel = level;

        if (level == LOW) {              // pressed
            _pressedAt = now;
            _longFired = false;
        } else {                         // released
            if (!_longFired) EventBus::post(Ev::Press);
        }
    }

    // Long press fires ON THRESHOLD CROSSING, while the button is still held —
    // not on release. The user feels it register mid-hold, which is what makes a
    // long press feel deliberate instead of laggy.
    if (level == LOW && !_longFired && (now - _pressedAt) >= ENC_LONG_PRESS_MS) {
        _longFired = true;
        EventBus::post(Ev::LongPress);
    }
}

bool Encoder::enableWakeOnPress() {
    // Only GPIO0..GPIO5 are RTC-capable on the ESP32-C3; PIN_ENC_SW is chosen to
    // sit inside that range (see config.h).
    static_assert(PIN_ENC_SW >= 0 && PIN_ENC_SW <= 5,
                  "Deep-sleep wake requires an RTC-capable GPIO (0-5) on ESP32-C3");
    gpio_pullup_en((gpio_num_t)PIN_ENC_SW);
    return esp_deep_sleep_enable_gpio_wakeup(1ULL << PIN_ENC_SW,
                                             ESP_GPIO_WAKEUP_GPIO_LOW) == ESP_OK;
}
