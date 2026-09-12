// A 4-bit greyscale framebuffer matching the recommended panel exactly.
//
// 128 x 96 pixels, 16 grey levels (0 = off/black, 15 = full brightness).
// That is 6144 bytes packed on device (128*96/2) — trivial on the ESP32-C3's SRAM.
//
// Every drawing primitive here has a direct equivalent in u8g2, so layout code
// written against this API ports to firmware almost line for line.

public struct FrameBuffer {
    public static let width = 128
    public static let height = 96

    public private(set) var width: Int
    public private(set) var height: Int
    public private(set) var pixels: [UInt8] // one byte per pixel, value 0...15

    public init(width: Int = FrameBuffer.width, height: Int = FrameBuffer.height) {
        self.width = width
        self.height = height
        self.pixels = [UInt8](repeating: 0, count: width * height)
    }

    // MARK: - Pixels

    public mutating func clear(_ grey: UInt8 = 0) {
        for i in 0..<pixels.count { pixels[i] = min(grey, 15) }
    }

    public mutating func set(_ x: Int, _ y: Int, _ grey: UInt8) {
        guard x >= 0, x < width, y >= 0, y < height else { return }
        pixels[y * width + x] = min(grey, 15)
    }

    public func get(_ x: Int, _ y: Int) -> UInt8 {
        guard x >= 0, x < width, y >= 0, y < height else { return 0 }
        return pixels[y * width + x]
    }

    // MARK: - Shapes

    public mutating func fillRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ grey: UInt8) {
        guard w > 0, h > 0 else { return }
        for yy in y..<(y + h) {
            for xx in x..<(x + w) { set(xx, yy, grey) }
        }
    }

    public mutating func strokeRect(_ x: Int, _ y: Int, _ w: Int, _ h: Int, _ grey: UInt8) {
        guard w > 0, h > 0 else { return }
        hLine(x, y, w, grey)
        hLine(x, y + h - 1, w, grey)
        vLine(x, y, h, grey)
        vLine(x + w - 1, y, h, grey)
    }

    public mutating func hLine(_ x: Int, _ y: Int, _ w: Int, _ grey: UInt8) {
        guard w > 0 else { return }
        for xx in x..<(x + w) { set(xx, y, grey) }
    }

    public mutating func vLine(_ x: Int, _ y: Int, _ h: Int, _ grey: UInt8) {
        guard h > 0 else { return }
        for yy in y..<(y + h) { set(x, yy, grey) }
    }

    /// A 1px dotted rule — used for quiet separators. Lit pixel count matters on OLED.
    public mutating func dottedHLine(_ x: Int, _ y: Int, _ w: Int, _ grey: UInt8, step: Int = 2) {
        var xx = x
        while xx < x + w {
            set(xx, y, grey)
            xx += step
        }
    }

    // MARK: - Text

    /// Draws `text` with its top-left at (x, y). Returns the advance width in pixels.
    @discardableResult
    public mutating func text(
        _ text: String,
        x: Int,
        y: Int,
        grey: UInt8 = 15,
        scale: Int = 1,
        tracking: Int = 0
    ) -> Int {
        var cursor = x
        for ch in text {
            let cols = Font5x7.columns(for: ch)
            for (ci, col) in cols.enumerated() {
                for row in 0..<Font5x7.glyphHeight where (col >> UInt8(row)) & 1 == 1 {
                    // Scale by drawing a scale x scale block per source pixel.
                    let px = cursor + ci * scale
                    let py = y + row * scale
                    if scale == 1 {
                        set(px, py, grey)
                    } else {
                        fillRect(px, py, scale, scale, grey)
                    }
                }
            }
            cursor += Font5x7.advance * scale + tracking
        }
        return cursor - x
    }

    public static func textWidth(_ text: String, scale: Int = 1, tracking: Int = 0) -> Int {
        guard !text.isEmpty else { return 0 }
        let n = text.count
        // Last glyph does not need trailing tracking or inter-glyph space.
        return n * (Font5x7.advance * scale + tracking) - (scale + tracking)
    }

    @discardableResult
    public mutating func textRight(
        _ string: String,
        right: Int,
        y: Int,
        grey: UInt8 = 15,
        scale: Int = 1,
        tracking: Int = 0
    ) -> Int {
        let w = FrameBuffer.textWidth(string, scale: scale, tracking: tracking)
        return text(string, x: right - w, y: y, grey: grey, scale: scale, tracking: tracking)
    }

    @discardableResult
    public mutating func textCentered(
        _ string: String,
        y: Int,
        grey: UInt8 = 15,
        scale: Int = 1,
        tracking: Int = 0
    ) -> Int {
        let w = FrameBuffer.textWidth(string, scale: scale, tracking: tracking)
        return text(string, x: (width - w) / 2, y: y, grey: grey, scale: scale, tracking: tracking)
    }

    // MARK: - Glyphs the font does not cover

    /// Trend arrow. `up == false` draws it inverted. Occupies 5x7 like a glyph.
    public mutating func arrow(x: Int, y: Int, up: Bool, grey: UInt8 = 15) {
        if up {
            set(x + 2, y, grey)
            hLine(x + 1, y + 1, 3, grey)
            hLine(x, y + 2, 5, grey)
            vLine(x + 2, y + 3, 4, grey)
        } else {
            vLine(x + 2, y, 4, grey)
            hLine(x, y + 4, 5, grey)
            hLine(x + 1, y + 5, 3, grey)
            set(x + 2, y + 6, grey)
        }
    }

    /// A flat "steady" glyph for items with no defensible trend number.
    public mutating func steady(x: Int, y: Int, grey: UInt8 = 15) {
        hLine(x, y + 2, 5, grey)
        hLine(x, y + 4, 5, grey)
    }

    /// Selection chevron.
    public mutating func chevron(x: Int, y: Int, grey: UInt8 = 15) {
        set(x, y, grey)
        set(x + 1, y + 1, grey)
        set(x + 2, y + 2, grey)
        set(x + 1, y + 3, grey)
        set(x, y + 4, grey)
    }

    /// Battery glyph, 11x6. `level` 0...4.
    public mutating func battery(x: Int, y: Int, level: Int, grey: UInt8 = 15) {
        strokeRect(x, y, 10, 6, grey)
        vLine(x + 10, y + 2, 2, grey)
        let filled = max(0, min(4, level))
        if filled > 0 { fillRect(x + 2, y + 2, filled * 2 - 1, 2, grey) }
    }

    /// Wi-Fi glyph, 7x6 — three arcs. Drawn dim; only shown when state is notable.
    public mutating func wifi(x: Int, y: Int, bars: Int, grey: UInt8 = 15) {
        set(x + 3, y + 5, grey)
        if bars >= 1 { hLine(x + 2, y + 3, 3, grey) }
        if bars >= 2 { hLine(x + 1, y + 1, 5, grey) }
    }

    /// Small "no connection" mark, 7x7.
    public mutating func offlineMark(x: Int, y: Int, grey: UInt8 = 15) {
        for i in 0..<7 {
            set(x + i, y + i, grey)
            set(x + 6 - i, y + i, grey)
        }
    }

    // MARK: - QR placeholder
    //
    // NOT a real QR code. This draws the correct *geometry* — a 25x25 module
    // (QR version 2) symbol at 2px per module = 50x50px — so you can confirm the
    // layout works and that the payload budget in review §8/§12 is realistic.
    // The firmware will generate real symbols; keep payloads short enough to stay
    // at version 1-2 or the modules drop below 2px and phones stop reading them.
    public mutating func qrPlaceholder(x: Int, y: Int, modules: Int = 25, moduleSize: Int = 2, grey: UInt8 = 15) {
        // Quiet zone is required in reality; we draw the symbol only.
        var seed: UInt64 = 0x4D4F4F4B53 // "MOOKS"
        func next() -> UInt64 {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return (seed >> 33)
        }
        func isFinder(_ mx: Int, _ my: Int) -> Bool {
            let inTL = mx < 7 && my < 7
            let inTR = mx >= modules - 7 && my < 7
            let inBL = mx < 7 && my >= modules - 7
            return inTL || inTR || inBL
        }
        for my in 0..<modules {
            for mx in 0..<modules {
                var on: Bool
                if isFinder(mx, my) {
                    // 7x7 finder: filled ring + 3x3 core.
                    let lx = mx < 7 ? mx : mx - (modules - 7)
                    let ly = my < 7 ? my : my - (modules - 7)
                    let ring = lx == 0 || lx == 6 || ly == 0 || ly == 6
                    let core = lx >= 2 && lx <= 4 && ly >= 2 && ly <= 4
                    on = ring || core
                } else if my == 6 || mx == 6 {
                    on = (mx + my) % 2 == 0 // timing patterns
                } else {
                    on = next() % 2 == 0
                }
                if on {
                    fillRect(x + mx * moduleSize, y + my * moduleSize, moduleSize, moduleSize, grey)
                }
            }
        }
    }

    // MARK: - Debug

    /// Terminal preview. Lets layout be checked without opening an image.
    public func asciiPreview(border: Bool = true) -> String {
        let ramp = Array(" .,:;-=+*coO#%@█")
        var out = ""
        if border { out += "┌" + String(repeating: "─", count: width) + "┐\n" }
        for y in 0..<height {
            if border { out += "│" }
            for x in 0..<width {
                let v = Int(get(x, y))
                out.append(ramp[min(v, ramp.count - 1)])
            }
            if border { out += "│" }
            out += "\n"
        }
        if border { out += "└" + String(repeating: "─", count: width) + "┘" }
        return out
    }

    /// Fraction of pixels that are lit, and the mean grey level.
    /// OLED current scales with both, so this is a power proxy — see review §7.
    public var litStats: (fraction: Double, meanGrey: Double) {
        var lit = 0
        var sum = 0
        for p in pixels where p > 0 {
            lit += 1
            sum += Int(p)
        }
        let total = Double(pixels.count)
        return (Double(lit) / total, lit == 0 ? 0 : Double(sum) / Double(lit))
    }
}
