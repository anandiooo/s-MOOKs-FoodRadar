#pragma once
#include <Arduino.h>

// EC11 quadrature encoder + integrated push switch.
//
// Interrupt-driven with a transition lookup table. Polling an encoder in loop()
// with delay() is the reason most hobby knobs feel cheap: you miss steps when
// something else is busy, and you emit phantom steps on contact bounce.
//
// Pair this with the hardware RC filter from review §3.3 (10k series + 100nF to
// GND on each of A and B). Software debouncing alone cannot fix a bouncing contact
// as well as ~1ms of RC can, and the parts cost about two cents.

class Encoder {
public:
    void begin();

    /// Consumes and returns accumulated detents since the last call.
    /// Positive = clockwise. Called from the UI task only.
    int32_t takeDelta();

    /// Call every loop. Emits Press / LongPress via the EventBus.
    void poll();

    bool isPressed() const;

    /// Configures the switch as a deep-sleep wake source and returns whether it
    /// was accepted. Rotation cannot wake the chip — quadrature needs a running
    /// CPU — so the interaction is "press to wake", like a watch crown.
    static bool enableWakeOnPress();

private:
    static void IRAM_ATTR onQuadratureEdge();

    // Button state machine
    bool _lastLevel = true;      // active low
    uint32_t _pressedAt = 0;
    uint32_t _lastChangeAt = 0;
    bool _longFired = false;
};

extern Encoder encoder;
