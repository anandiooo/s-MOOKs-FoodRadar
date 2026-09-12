// The MOOKS design system, expressed as numbers a firmware author can copy.
//
// Everything here has one job: make hierarchy come from *grey level* rather than from
// size alone. That is the whole reason to spend money on a 16-level SSD1327 panel
// instead of a 1-bit SH1106 (review §3.1).

public enum Theme {

    // MARK: - Grey levels (0...15)

    /// Titles, accents, the selected row. The only pixels allowed at full brightness.
    public static let greyPrimary: UInt8 = 15
    /// Body copy — the sentence that rewards the press.
    public static let greyBody: UInt8 = 11
    /// Section labels, counters, metadata. Present but never competing.
    public static let greyLabel: UInt8 = 6
    /// Rules, unselected rows, disabled states.
    public static let greyQuiet: UInt8 = 4

    // MARK: - Geometry

    public static let margin = 4
    /// Left edge of all content. Everything is left-aligned to this.
    public static let contentLeft = 4
    /// Right edge for right-aligned content.
    public static let contentRight = FrameBuffer.width - 4  // 124
    public static let contentWidth = contentRight - contentLeft // 120

    /// Baseline rhythm. All vertical positions are multiples of this where possible.
    public static let grid = 6

    // MARK: - Type scale (in this simulator's 5x7 font)

    public static let titleScale = 2          // 10 x 14 px per glyph cell
    public static let bodyScale = 1           // 5 x 7
    public static let labelTracking = 1       // letterspacing for small caps labels

    public static let titleLineHeight = 16
    public static let bodyLineHeight = 10

    // MARK: - Measured layout capacity
    //
    // These are the numbers that matter, and they were MEASURED by rendering, not
    // guessed. They are deliberately computed against a FIXED-WIDTH font so that
    // swapping to a proportional face on device (u8g2_font_helvB14_tr /
    // helvR08_tr) can only ever give you MORE room — a font change must never be
    // able to break a layout.
    //
    // NOTE: this corrects review §10.2, which guessed `why <= 96`. Measured, the
    // safe worst-case limit is 60. Use these values in the content validator.

    /// Title: 2 lines x 10 chars at 2x scale.
    public static let titleCharsPerLine = 10
    public static let titleMaxLines = 2
    public static let titleMaxChars = 18   // <= 20 with wrapping headroom

    /// Hook (the one-liner that earns the press): 2 lines x 20 chars at 1x.
    public static let hookCharsPerLine = 20
    public static let hookMaxLines = 2
    public static let hookMaxChars = 32

    /// Why (the payoff): 3 lines x 20 chars at 1x.
    public static let whyCharsPerLine = 20
    public static let whyMaxLines = 3
    public static let whyMaxChars = 60

    public static let placeMaxChars = 20

    // MARK: - Text layout

    /// Greedy word wrap. The device does NOT do this at runtime — the backend
    /// pre-wraps and the firmware renders fixed lines (review §9.4). This is the
    /// reference implementation the content validator must agree with.
    public static func wrap(_ text: String, charsPerLine: Int, maxLines: Int) -> [String] {
        var lines: [String] = []
        var current = ""
        for word in text.split(separator: " ", omittingEmptySubsequences: true) {
            let w = String(word)
            if current.isEmpty {
                current = w
            } else if current.count + 1 + w.count <= charsPerLine {
                current += " " + w
            } else {
                lines.append(current)
                current = w
            }
            // A single word longer than the line is a content bug, not a render bug.
            while current.count > charsPerLine {
                lines.append(String(current.prefix(charsPerLine)))
                current = String(current.dropFirst(charsPerLine))
            }
        }
        if !current.isEmpty { lines.append(current) }
        return Array(lines.prefix(maxLines))
    }

    /// True if the string fits without truncation. Used by the validator.
    public static func fits(_ text: String, charsPerLine: Int, maxLines: Int) -> Bool {
        let all = wrapAll(text, charsPerLine: charsPerLine)
        return all.count <= maxLines
    }

    static func wrapAll(_ text: String, charsPerLine: Int) -> [String] {
        wrap(text, charsPerLine: charsPerLine, maxLines: Int.max)
    }
}
