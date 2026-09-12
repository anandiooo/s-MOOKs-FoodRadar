// Every screen in MOOKS V1, at true panel resolution.
//
// Layout is FIXED — positions are constants, not the output of a runtime layout
// engine. That is deliberate: the firmware draws at these coordinates and the
// backend guarantees the text fits (review §9.4). A content mistake becomes a
// build-time validator failure, never a broken screen in someone's hand.

public enum Screens {

    // MARK: - Shared chrome

    /// The one header row: a small-caps label on the left, status on the right.
    /// Deliberately NOT the wordmark — permanent chrome burns OLED pixels and the
    /// enclosure already says MOOKS (review §9.5).
    static func header(
        _ fb: inout FrameBuffer,
        label: String,
        right: String? = nil,
        offline: Bool = false,
        battery: Int? = nil
    ) {
        fb.text(label, x: Theme.contentLeft, y: 4,
                grey: Theme.greyLabel, scale: 1, tracking: Theme.labelTracking)

        var cursor = Theme.contentRight
        if let right {
            let w = FrameBuffer.textWidth(right, scale: 1, tracking: Theme.labelTracking)
            fb.text(right, x: cursor - w, y: 4, grey: Theme.greyLabel,
                    scale: 1, tracking: Theme.labelTracking)
            cursor -= w + 6
        }
        if offline {
            fb.offlineMark(x: cursor - 7, y: 4, grey: Theme.greyLabel)
            cursor -= 12
        }
        if let battery {
            fb.battery(x: cursor - 11, y: 4, level: battery, grey: Theme.greyLabel)
        }
    }

    /// Title block: 1 or 2 lines at 2x, optically centred inside its zone.
    static func titleBlock(_ fb: inout FrameBuffer, _ title: String, zoneTop: Int, zoneHeight: Int) {
        let lines = Theme.wrap(title,
                              charsPerLine: Theme.titleCharsPerLine,
                              maxLines: Theme.titleMaxLines)
        let blockHeight = lines.count * Theme.titleLineHeight - (Theme.titleLineHeight - 14)
        var y = zoneTop + max(0, (zoneHeight - blockHeight) / 2)
        for line in lines {
            fb.text(line, x: Theme.contentLeft, y: y,
                    grey: Theme.greyPrimary, scale: Theme.titleScale)
            y += Theme.titleLineHeight
        }
    }

    /// The trend accent, right-aligned. Arrow + value, or a word for non-numeric trends.
    static func accent(_ fb: inout FrameBuffer, _ trend: Trend, y: Int) {
        guard let text = trend.accentText else { return }
        let textW = FrameBuffer.textWidth(text, scale: 1)
        let x = Theme.contentRight - textW
        fb.text(text, x: x, y: y, grey: Theme.greyPrimary, scale: 1)
        if case .percent = trend {
            fb.arrow(x: x - 8, y: y, up: trend.isUp, grey: Theme.greyPrimary)
        } else if trend == .steady {
            fb.steady(x: x - 8, y: y, grey: Theme.greyPrimary)
        } else {
            fb.arrow(x: x - 8, y: y, up: true, grey: Theme.greyPrimary)
        }
    }

    // MARK: - 01 Boot

    /// 120 ms fade-in, then gone. The only place the wordmark ever appears on screen.
    public static func boot() -> FrameBuffer {
        var fb = FrameBuffer()
        fb.textCentered("MOOKS.", y: 38, grey: Theme.greyPrimary, scale: 2)
        // A short rule as a full stop to the composition.
        fb.hLine((FrameBuffer.width - 24) / 2, 60, 24, Theme.greyQuiet)
        return fb
    }

    // MARK: - 02/03 Today — the card the whole product is built around

    public static func today(
        item: Item,
        index: Int,
        total: Int,
        offline: Bool = false,
        battery: Int? = nil
    ) -> FrameBuffer {
        var fb = FrameBuffer()
        header(&fb, label: item.kind.label, right: "\(index)/\(total)",
               offline: offline, battery: battery)

        titleBlock(&fb, item.title, zoneTop: 20, zoneHeight: 38)

        // The hook: the line that has to earn a press.
        var y = 62
        for line in Theme.wrap(item.hook,
                              charsPerLine: Theme.hookCharsPerLine,
                              maxLines: Theme.hookMaxLines) {
            fb.text(line, x: Theme.contentLeft, y: y, grey: Theme.greyBody, scale: 1)
            y += Theme.bodyLineHeight
        }

        // Footer: provenance on the left, trend on the right.
        if offline {
            fb.text("yesterday's picks", x: Theme.contentLeft, y: 85, grey: Theme.greyQuiet, scale: 1)
        } else if let place = item.place {
            fb.text(place, x: Theme.contentLeft, y: 85, grey: Theme.greyLabel, scale: 1)
        }
        accent(&fb, item.trend, y: 85)
        return fb
    }

    // MARK: - 04 Detail — the payoff

    public static func detail(item: Item) -> FrameBuffer {
        var fb = FrameBuffer()
        header(&fb, label: item.kind.label)
        accent(&fb, item.trend, y: 4)

        titleBlock(&fb, item.title, zoneTop: 14, zoneHeight: 34)

        fb.dottedHLine(Theme.contentLeft, 50, Theme.contentWidth, Theme.greyQuiet, step: 3)

        var y = 56
        for line in Theme.wrap(item.why,
                              charsPerLine: Theme.whyCharsPerLine,
                              maxLines: Theme.whyMaxLines) {
            fb.text(line, x: Theme.contentLeft, y: y, grey: Theme.greyBody, scale: 1)
            y += Theme.bodyLineHeight
        }

        // Footer holds exactly two things and they must not collide: provenance on
        // the left, the primary action on the right.
        //
        // "press to save" (76px) + a 9-char place (52px) = 128px in a 120px column.
        // That overlap was caught by rendering, not by reading the layout — which is
        // the entire argument for building this simulator before cutting acrylic.
        // The action is now a 31px affordance, so a 20-char place still fits.
        if let place = item.place {
            fb.text(place, x: Theme.contentLeft, y: 88, grey: Theme.greyLabel, scale: 1)
        }
        let actionW = FrameBuffer.textWidth("save", scale: 1)
        fb.text("save", x: Theme.contentRight - actionW, y: 88, grey: Theme.greyLabel, scale: 1)
        fb.chevron(x: Theme.contentRight - actionW - 8, y: 89, grey: Theme.greyPrimary)
        return fb
    }

    /// Shown once, on the very first session, then never again. Teaching the three
    /// gestures here is cheaper than carrying hints on every screen forever
    /// (and long-press discovery was the weak spot in the §19 usability targets).
    public static func howTo() -> FrameBuffer {
        var fb = FrameBuffer()
        header(&fb, label: "HOW IT WORKS")

        let rows = [("turn", "browse"), ("press", "choose"), ("hold", "go back")]
        var y = 26
        for (gesture, meaning) in rows {
            fb.text(gesture, x: Theme.contentLeft, y: y, grey: Theme.greyPrimary, scale: 1)
            fb.text(meaning, x: 46, y: y, grey: Theme.greyBody, scale: 1)
            y += 16
        }
        fb.text("turn to start", x: Theme.contentLeft, y: 84, grey: Theme.greyQuiet, scale: 1)
        return fb
    }

    // MARK: - 05 Save confirmation

    public static func savedConfirmation(count: Int) -> FrameBuffer {
        var fb = FrameBuffer()
        fb.textCentered("Saved.", y: 34, grey: Theme.greyPrimary, scale: 2)
        fb.textCentered("\(count) kept", y: 60, grey: Theme.greyLabel, scale: 1)
        return fb
    }

    // MARK: - 06 Handoff — the feature that answers "why not my phone?"

    public static func handoff(item: Item) -> FrameBuffer {
        var fb = FrameBuffer()
        header(&fb, label: "TAKE ME THERE")

        // 25 modules at 2px = 50x50. Keep the short-link payload small enough to
        // stay at QR version 1-2 or the modules fall below 2px (review §10.2).
        fb.qrPlaceholder(x: Theme.contentLeft, y: 22, modules: 25, moduleSize: 2,
                         grey: Theme.greyPrimary)

        let col = 62
        fb.text("SCAN TO", x: col, y: 26, grey: Theme.greyLabel, scale: 1, tracking: Theme.labelTracking)
        fb.text("OPEN", x: col, y: 36, grey: Theme.greyLabel, scale: 1, tracking: Theme.labelTracking)
        if let place = item.place {
            fb.text(place, x: col, y: 52, grey: Theme.greyPrimary, scale: 1)
        }
        fb.text("long press = back", x: Theme.contentLeft, y: 86, grey: Theme.greyQuiet, scale: 1)
        return fb
    }

    // MARK: - 07 End of day — the most important screen in the product

    public static func endOfDay(nextCount: Int, time: String) -> FrameBuffer {
        var fb = FrameBuffer()
        fb.textCentered("That's all", y: 26, grey: Theme.greyPrimary, scale: 2)
        fb.textCentered("for today.", y: 42, grey: Theme.greyPrimary, scale: 2)
        fb.textCentered("\(nextCount) new tomorrow, \(time)", y: 70, grey: Theme.greyLabel, scale: 1)
        return fb
    }

    // MARK: - 08 Menu

    public struct MenuRow {
        public let title: String
        public let meta: String?
        public init(_ title: String, _ meta: String? = nil) {
            self.title = title
            self.meta = meta
        }
    }

    public static func menu(rows: [MenuRow], selected: Int) -> FrameBuffer {
        var fb = FrameBuffer()
        header(&fb, label: "MENU")

        var y = 24
        for (i, row) in rows.enumerated() {
            let isSel = i == selected
            if isSel { fb.chevron(x: Theme.contentLeft, y: y + 1, grey: Theme.greyPrimary) }
            fb.text(row.title, x: Theme.contentLeft + 9, y: y,
                    grey: isSel ? Theme.greyPrimary : 8, scale: 1)
            if let meta = row.meta {
                fb.textRight(meta, right: Theme.contentRight, y: y,
                             grey: isSel ? Theme.greyLabel : Theme.greyQuiet, scale: 1)
            }
            y += 14
        }
        return fb
    }

    // MARK: - 09 Saved

    public static func saved(titles: [String], selected: Int, total: Int) -> FrameBuffer {
        var fb = FrameBuffer()
        header(&fb, label: "SAVED", right: "\(total)")

        var y = 22
        for (i, title) in titles.prefix(5).enumerated() {
            let isSel = i == selected
            if isSel { fb.chevron(x: Theme.contentLeft, y: y + 1, grey: Theme.greyPrimary) }
            fb.text(title, x: Theme.contentLeft + 9, y: y,
                    grey: isSel ? Theme.greyPrimary : 8, scale: 1)
            y += 12
        }
        fb.text("press to open", x: Theme.contentLeft, y: 86, grey: Theme.greyQuiet, scale: 1)
        return fb
    }

    // MARK: - 10 Wi-Fi setup — no keyboard, no app (review §8)

    public static func setupWiFi(ssid: String) -> FrameBuffer {
        var fb = FrameBuffer()
        header(&fb, label: "SET UP WI-FI")

        let qrSize = 25 * 2
        fb.qrPlaceholder(x: (FrameBuffer.width - qrSize) / 2, y: 16,
                         modules: 25, moduleSize: 2, grey: Theme.greyPrimary)

        fb.textCentered(ssid, y: 72, grey: Theme.greyPrimary, scale: 1)
        fb.textCentered("scan to join", y: 84, grey: Theme.greyLabel, scale: 1)
        return fb
    }

    // MARK: - 11 Low battery

    public static func lowBattery() -> FrameBuffer {
        var fb = FrameBuffer()
        // A deliberately oversized battery glyph: 2x the standard, drawn by hand.
        let bx = 48, by = 26
        fb.strokeRect(bx, by, 30, 16, Theme.greyLabel)
        fb.fillRect(bx + 30, by + 5, 2, 6, Theme.greyLabel)
        fb.fillRect(bx + 3, by + 3, 4, 10, Theme.greyPrimary)

        fb.textCentered("Low battery.", y: 56, grey: Theme.greyPrimary, scale: 1)
        fb.textCentered("Charge me soon.", y: 70, grey: Theme.greyLabel, scale: 1)
        return fb
    }

    // MARK: - 12 First run, no content yet

    public static func firstRun() -> FrameBuffer {
        var fb = FrameBuffer()
        fb.textCentered("MOOKS.", y: 24, grey: Theme.greyPrimary, scale: 2)
        fb.textCentered("Five things a day.", y: 52, grey: Theme.greyBody, scale: 1)
        fb.textCentered("Turn to begin.", y: 66, grey: Theme.greyLabel, scale: 1)
        return fb
    }

    // MARK: - Catalog

    public struct Entry {
        public let name: String
        public let note: String
        public let frame: FrameBuffer
    }

    public static func catalog() -> [Entry] {
        let items = Sample.drop.items
        return [
            Entry(name: "01-boot", note: "Wordmark, 120ms fade. The only time it appears on screen.",
                  frame: boot()),
            Entry(name: "02-first-run", note: "No credentials, no cache. Sets the promise in one line.",
                  frame: firstRun()),
            Entry(name: "02b-how-to", note: "Shown once, ever. Teaches all three gestures.",
                  frame: howTo()),
            Entry(name: "03-today-1", note: "Card 1/5 — dish with a sourced trend number.",
                  frame: today(item: items[0], index: 1, total: 5)),
            Entry(name: "04-today-2-oddity", note: "Card 2/5 — no number, a direction word instead.",
                  frame: today(item: items[1], index: 2, total: 5)),
            Entry(name: "05-today-3-place", note: "Card 3/5 — a place, steady. Places live in the mix, not a category.",
                  frame: today(item: items[2], index: 3, total: 5)),
            Entry(name: "06-today-offline", note: "Cached drop, offline mark, honest 'yesterday's picks'.",
                  frame: today(item: items[3], index: 4, total: 5, offline: true, battery: 2)),
            Entry(name: "07-detail", note: "The payoff sentence. Press again to save.",
                  frame: detail(item: items[0])),
            Entry(name: "08-detail-place", note: "A place, no trend digits — a 'steady' glyph instead.",
                  frame: detail(item: items[2])),
            Entry(name: "09-saved-confirm", note: "Two seconds, then back to the card.",
                  frame: savedConfirmation(count: 12)),
            Entry(name: "10-handoff", note: "MOOKS decides, the phone executes. Zero extra hardware.",
                  frame: handoff(item: items[0])),
            Entry(name: "11-end-of-day", note: "The anti-feed. Nobody else's demo has this screen.",
                  frame: endOfDay(nextCount: 5, time: "9am")),
            Entry(name: "12-menu", note: "Behind a long press. Content first, menu last.",
                  frame: menu(rows: [MenuRow("Saved", "12"), MenuRow("Nearby", "JKT"),
                                     MenuRow("Wi-Fi", "ON"), MenuRow("About")], selected: 0)),
            Entry(name: "13-saved-list", note: "A destination, not a peer of today's content.",
                  frame: saved(titles: Sample.savedTitles, selected: 1, total: 12)),
            Entry(name: "14-setup-wifi", note: "Scan to join the AP, then type the password on the phone.",
                  frame: setupWiFi(ssid: "MOOKS-setup")),
            Entry(name: "15-low-battery", note: "Calm, once, dismissable. No percentage — ever.",
                  frame: lowBattery()),
        ]
    }
}
