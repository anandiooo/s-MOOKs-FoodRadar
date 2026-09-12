// swift-tools-version:5.9
import PackageDescription

// MOOKS UI simulator.
//
// MooksUI is a pure-Swift, dependency-free rendering core that draws the MOOKS
// interface into a 128x96 4-bit greyscale framebuffer — the exact geometry of the
// recommended 1.32" SSD1327 OLED panel.
//
// It exists so the interface can be designed, reviewed and iterated before any
// hardware arrives, and so the same layout code can be imported by a SwiftUI app
// on macOS/iPadOS for the interactive simulator (see review §20).
//
//   MooksUI       — platform-independent: framebuffer, font, layout, screens
//   mooks-render  — CLI: renders every screen to PNG + ASCII for review
//   (future)      — MooksApp: SwiftUI wrapper importing MooksUI, adds a draggable crown
//
let package = Package(
    name: "mooks-sim",
    products: [
        .library(name: "MooksUI", targets: ["MooksUI"]),
        .executable(name: "mooks-render", targets: ["mooks-render"]),
    ],
    targets: [
        .target(name: "MooksUI"),
        .executableTarget(name: "mooks-render", dependencies: ["MooksUI"]),
    ]
)
