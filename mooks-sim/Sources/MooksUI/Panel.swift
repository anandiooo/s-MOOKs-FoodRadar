#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

// Front-panel layout drawings, at 10 px per mm.
//
// These are proportion checks, not manufacturing drawings — but the dimensions come
// straight from review §4, so if the composition looks wrong here it will look wrong
// in your hand. Renders both candidate layouts side by side so the choice is visual
// rather than theoretical.

public enum Panel {
    public static let pxPerMM = 10

    static func mm(_ v: Double) -> Int { Int((v * Double(pxPerMM)).rounded()) }

    // Shell (V1 = the VBM-X1 as bought)
    public static let shellW = 77.0
    public static let shellH = 51.0
    static let wall = 2.2

    /// Margin from the shell edge to the safe window, per side: wall + wall radius +
    /// corner-boss clearance. 7.5 mm on the X1 gives the 62 x 36 window of review §2.1.
    static let safeMargin = 7.5

    // Display window for the recommended 1.32" SSD1327:
    // active area 26.86 x 20.14 + 0.25 mm reveal per side.
    static let winW = 27.4
    static let winH = 20.7

    static let knobDia = 17.0

    // MARK: - Primitives

    static func circle(_ fb: inout FrameBuffer, cx: Int, cy: Int, r: Int, grey: UInt8, filled: Bool) {
        let r2 = r * r
        let inner = (r - 2) * (r - 2)
        for y in (cy - r)...(cy + r) {
            for x in (cx - r)...(cx + r) {
                let d = (x - cx) * (x - cx) + (y - cy) * (y - cy)
                if d <= r2 {
                    if filled || d >= inner { fb.set(x, y, grey) }
                }
            }
        }
    }

    /// Radial knurl ticks — reads as a machined aluminium knob even at this scale.
    static func knurl(_ fb: inout FrameBuffer, cx: Int, cy: Int, r: Int, count: Int, grey: UInt8) {
        for i in 0..<count {
            let a = Double(i) * 2.0 * 3.14159265 / Double(count)
            let x0 = Double(cx) + Double(r - 12) * cos(a)
            let y0 = Double(cy) + Double(r - 12) * sin(a)
            let x1 = Double(cx) + Double(r - 2) * cos(a)
            let y1 = Double(cy) + Double(r - 2) * sin(a)
            line(&fb, Int(x0), Int(y0), Int(x1), Int(y1), grey)
        }
    }

    static func line(_ fb: inout FrameBuffer, _ x0: Int, _ y0: Int, _ x1: Int, _ y1: Int, _ grey: UInt8) {
        let dx = abs(x1 - x0), dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        var x = x0, y = y0
        while true {
            fb.set(x, y, grey)
            if x == x1 && y == y1 { break }
            let e2 = 2 * err
            if e2 > -dy { err -= dy; x += sx }
            if e2 < dx { err += dx; y += sy }
        }
    }

    static func dashedRect(_ fb: inout FrameBuffer, _ x: Int, _ y: Int, _ w: Int, _ h: Int, _ grey: UInt8) {
        var i = 0
        while i < w { fb.set(x + i, y, grey); fb.set(x + i, y + h - 1, grey); i += 6 }
        i = 0
        while i < h { fb.set(x, y + i, grey); fb.set(x + w - 1, y + i, grey); i += 6 }
    }

    /// Composites a rendered screen into the display window at 2x.
    static func placeScreen(_ fb: inout FrameBuffer, _ screen: FrameBuffer, winX: Int, winY: Int) {
        let scale = 2
        let sw = screen.width * scale   // 256
        let sh = screen.height * scale  // 192
        let ox = winX + (mm(winW) - sw) / 2
        let oy = winY + (mm(winH) - sh) / 2
        for y in 0..<sh {
            for x in 0..<sw {
                let v = screen.get(x / scale, y / scale)
                if v > 0 { fb.set(ox + x, oy + y, v) }
            }
        }
    }

    // MARK: - Option A: front-mounted dial

    /// Fraction of the front face occupied by lit-able screen area.
    /// A phone is ~85%. Below ~15% the display reads as "a component in a box"
    /// rather than as the face of a product.
    public static func screenToFaceRatio(shellW: Double = shellW, shellH: Double = shellH) -> Double {
        (26.86 * 20.14) / (shellW * shellH)
    }

    /// True if a front-mounted dial can coexist with the display in this face.
    /// Needs window + knob + three margins inside the safe window.
    public static func dialFits(shellW: Double) -> Bool {
        let safeW = shellW - safeMargin * 2
        return safeW >= winW + knobDia + 3.0 + 4.0 + 4.0
    }

    public static func dial(screen: FrameBuffer,
                           shellW: Double = shellW,
                           shellH: Double = shellH) -> FrameBuffer {
        var fb = FrameBuffer(width: mm(shellW), height: mm(shellH))
        let safeW = shellW - safeMargin * 2
        let safeH = shellH - safeMargin * 2

        // Shell edge and the acrylic panel inset.
        fb.strokeRect(0, 0, fb.width, fb.height, 6)
        fb.strokeRect(mm(wall), mm(wall), fb.width - mm(wall) * 2, fb.height - mm(wall) * 2, 3)

        // Safe window (dashed) — nothing may cross this.
        let safeX = mm(safeMargin)
        let safeY = mm(safeMargin)
        dashedRect(&fb, safeX, safeY, mm(safeW), mm(safeH), 2)

        // Distribute the leftover width as margin | window | gap | knob | margin.
        let leftover = safeW - winW - knobDia
        let m1 = leftover * 0.28, gap = leftover * 0.38
        let winX = safeX + mm(m1)
        let winY = mm((shellH - winH) / 2) - mm(1.5) // optical raise
        fb.strokeRect(winX, winY, mm(winW), mm(winH), 5)
        placeScreen(&fb, screen, winX: winX, winY: winY)

        let knobCX = winX + mm(winW) + mm(gap) + mm(knobDia / 2)
        let knobCY = fb.height / 2
        circle(&fb, cx: knobCX, cy: knobCY, r: mm(knobDia / 2), grey: 9, filled: false)
        knurl(&fb, cx: knobCX, cy: knobCY, r: mm(knobDia / 2), count: 28, grey: 7)
        circle(&fb, cx: knobCX, cy: knobCY, r: 6, grey: 5, filled: true)

        fb.text("MOOKS.", x: winX, y: fb.height - mm(wall) - 34, grey: 6, scale: 3)
        return fb
    }

    // MARK: - Option B: side crown

    public static func crown(screen: FrameBuffer,
                            shellW: Double = shellW,
                            shellH: Double = shellH) -> FrameBuffer {
        // Extra width so the crown can protrude past the shell edge.
        var fb = FrameBuffer(width: mm(shellW) + 24, height: mm(shellH))
        let shellRight = mm(shellW)
        let safeW = shellW - safeMargin * 2
        let safeH = shellH - safeMargin * 2

        fb.strokeRect(0, 0, shellRight, fb.height, 6)
        fb.strokeRect(mm(wall), mm(wall), shellRight - mm(wall) * 2, fb.height - mm(wall) * 2, 3)

        let safeX = mm(safeMargin)
        let safeY = mm(safeMargin)
        dashedRect(&fb, safeX, safeY, mm(safeW), mm(safeH), 2)

        // Display centred on the whole face — this is what the crown buys you.
        let winX = (shellRight - mm(winW)) / 2
        let winY = mm((shellH - winH) / 2) - mm(1.5)
        fb.strokeRect(winX, winY, mm(winW), mm(winH), 5)
        placeScreen(&fb, screen, winX: winX, winY: winY)

        // Crown seen edge-on, protruding from the right wall, upper third.
        let cy = fb.height / 2 - mm(4.0)
        let ch = mm(11.0)
        fb.fillRect(shellRight - 2, cy - ch / 2, 20, ch, 8)
        var t = cy - ch / 2 + 2
        while t < cy + ch / 2 - 1 {
            fb.hLine(shellRight, t, 17, 12)
            t += 4
        }

        fb.text("MOOKS.", x: winX, y: fb.height - mm(wall) - 34, grey: 6, scale: 3)
        return fb
    }
}
