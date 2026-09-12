#pragma once
#include <Arduino.h>

// The architectural keystone.
//
// One FreeRTOS queue of small PODs. The UI task drains it; every other task only
// ever posts to it. This is what makes "the screen stays responsive while Wi-Fi is
// dying" possible, and it is the single decision that keeps this codebase from
// becoming the usual Arduino tangle of globals and blocking calls.
//
// Rule: events are values, never pointers to heap. If an event needs to carry a
// payload, the payload lives in a module the UI task can read directly (Cache,
// Store), and the event just says "that thing changed".

enum class Ev : uint8_t {
    None = 0,

    // Input
    Rotate,        // i32 = signed detents since last event
    Press,         // short press
    LongPress,     // fired on threshold crossing, while still held
    WakeFromSleep,

    // Network — status, never a screen
    NetConnecting,
    NetOnline,
    NetOffline,
    DropUpdated,   // Cache holds a newer drop; re-render in place
    DropUnchanged, // 304. The happy path.
    NetError,      // i32 = HTTP status or negative internal code

    // Power
    BatteryChanged,   // i32 = millivolts
    ChargerAttached,
    ChargerDetached,
    ScreenTimeout,
    SleepRequest,

    // Provisioning
    ProvisionStarted,
    ProvisionSucceeded,
    ProvisionFailed,
};

struct Event {
    Ev type = Ev::None;
    int32_t i32 = 0;
};

class EventBus {
public:
    static void begin(size_t depth = 16) {
        _q = xQueueCreate(depth, sizeof(Event));
    }

    /// Safe from any task. Drops the event rather than blocking if the queue is
    /// full — a full queue means the UI is wedged, and blocking the network task
    /// would only hide that.
    static bool post(Ev type, int32_t i32 = 0) {
        if (!_q) return false;
        Event e{type, i32};
        return xQueueSend(_q, &e, 0) == pdTRUE;
    }

    /// Safe from an ISR.
    static bool postFromISR(Ev type, int32_t i32 = 0) {
        if (!_q) return false;
        Event e{type, i32};
        BaseType_t woken = pdFALSE;
        bool ok = xQueueSendFromISR(_q, &e, &woken) == pdTRUE;
        if (woken) portYIELD_FROM_ISR();
        return ok;
    }

    /// UI task only. `timeoutMs = 0` polls.
    static bool receive(Event& out, uint32_t timeoutMs) {
        if (!_q) return false;
        return xQueueReceive(_q, &out, pdMS_TO_TICKS(timeoutMs)) == pdTRUE;
    }

private:
    static QueueHandle_t _q;
};
