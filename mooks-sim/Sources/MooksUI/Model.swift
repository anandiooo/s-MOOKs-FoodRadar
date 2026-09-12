import Foundation

// The content model. Mirrors the JSON the device fetches (review §10.2) exactly,
// so the simulator, the validator and the firmware all agree on one shape.

public enum ItemKind: String, Codable, CaseIterable {
    case dish
    case drink
    case place
    case oddity

    /// The small caps label shown above the title.
    public var label: String {
        switch self {
        case .dish: return "DISH"
        case .drink: return "DRINK"
        case .place: return "PLACE"
        case .oddity: return "ODDITY"
        }
    }
}

/// How a trend is expressed. If you cannot source a real number, do not print one —
/// print a direction instead (review §16, risk 13).
public enum Trend: Codable, Equatable {
    case percent(Int)
    case rising
    case steady
    case peaking

    public var accentText: String? {
        switch self {
        case .percent(let p): return "\(abs(p))%"
        case .rising: return "RISING"
        case .steady: return "STEADY"
        case .peaking: return "PEAKING"
        }
    }

    public var isUp: Bool {
        switch self {
        case .percent(let p): return p >= 0
        case .rising, .peaking: return true
        case .steady: return false
        }
    }
}

public struct Item: Codable, Equatable {
    public var id: String
    public var title: String
    public var kind: ItemKind
    public var trend: Trend
    public var hook: String
    public var why: String
    public var place: String?
    public var link: String?
    public var tags: [String]

    public init(
        id: String,
        title: String,
        kind: ItemKind,
        trend: Trend,
        hook: String,
        why: String,
        place: String? = nil,
        link: String? = nil,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.kind = kind
        self.trend = trend
        self.hook = hook
        self.why = why
        self.place = place
        self.link = link
        self.tags = tags
    }
}

public struct Drop: Codable {
    public var schema: Int
    public var dropId: String
    public var city: String
    public var items: [Item]

    public init(schema: Int = 1, dropId: String, city: String, items: [Item]) {
        self.schema = schema
        self.dropId = dropId
        self.city = city
        self.items = items
    }
}

// MARK: - Sample content used by the renderer

public enum Sample {
    public static let drop = Drop(
        dropId: "2026-09-12",
        city: "jkt",
        items: [
            Item(
                id: "mt-001",
                title: "Matcha Tiramisu",
                kind: .dish,
                trend: .percent(238),
                hook: "Everyone's ordering it.",
                why: "Matcha's bitterness cuts the mascarpone. That's the trick.",
                place: "Kopi Nako",
                link: "a7f3",
                tags: ["matcha", "dessert", "viral"]
            ),
            Item(
                id: "cr-002",
                title: "Chili Oil Ice",
                kind: .oddity,
                trend: .rising,
                hook: "Yes, on ice cream.",
                why: "Heat arrives after the cold does. Sounds wrong. Isn't.",
                place: nil,
                link: "b2k9",
                tags: ["oddity", "dessert", "spicy"]
            ),
            Item(
                id: "pl-003",
                title: "Toko Kopi Ini",
                kind: .place,
                trend: .steady,
                hook: "Nine seats. One roast.",
                why: "One coffee, one way. No menu. Shuts at noon.",
                place: "Menteng",
                link: "c4m1",
                tags: ["coffee", "place", "quiet"]
            ),
            Item(
                id: "pd-004",
                title: "Pandan Butter",
                kind: .drink,
                trend: .percent(64),
                hook: "The new brown sugar.",
                why: "Grassy and sweet at once. Ask for it half sugar.",
                place: "Warung Ibu",
                link: "d8p2",
                tags: ["pandan", "drink", "local"]
            ),
            Item(
                id: "sb-005",
                title: "Salt Bread",
                kind: .dish,
                trend: .peaking,
                hook: "Already past its peak.",
                why: "Two years of queues. Now it's just very good bread.",
                place: nil,
                link: "e1s5",
                tags: ["bread", "bakery"]
            ),
        ]
    )

    public static let savedTitles = [
        "Matcha Tiramisu",
        "Toko Kopi Ini",
        "Chili Oil Ice",
        "Kaya Toast",
        "Pandan Butter",
    ]
}
