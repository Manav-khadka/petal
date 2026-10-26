import Foundation

public struct NoteColor: Codable, Sendable, Hashable, Identifiable {
    public var id: String {
        if let customInkHex = customInkHex {
            return "\(hex)_\(customInkHex)"
        }
        return hex
    }

    public let hex: String
    public let name: String?
    public let isCustom: Bool
    public let customInkHex: String?

    public init(
        hex: String,
        name: String? = nil,
        isCustom: Bool = false,
        customInkHex: String? = nil
    ) {
        self.hex = NoteColor.normalize(hex: hex)
        self.name = name
        self.isCustom = isCustom
        self.customInkHex = customInkHex.map { NoteColor.normalize(hex: $0) }
    }

    enum CodingKeys: String, CodingKey {
        case hex
        case name
        case isCustom
        case customInkHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hex = NoteColor.normalize(hex: try container.decode(String.self, forKey: .hex))
        name = try container.decodeIfPresent(String.self, forKey: .name)
        isCustom = try container.decodeIfPresent(Bool.self, forKey: .isCustom) ?? false
        if let customInk = try container.decodeIfPresent(String.self, forKey: .customInkHex) {
            customInkHex = NoteColor.normalize(hex: customInk)
        } else {
            customInkHex = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hex, forKey: .hex)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(isCustom, forKey: .isCustom)
        try container.encodeIfPresent(customInkHex, forKey: .customInkHex)
    }

    public static let butter = NoteColor(hex: "#FFF3B0", name: "Butter")
    public static let blush = NoteColor(hex: "#FFD6E0", name: "Blush")
    public static let mint = NoteColor(hex: "#CFF3E1", name: "Mint")
    public static let sky = NoteColor(hex: "#CDE7FF", name: "Sky")
    public static let lavender = NoteColor(hex: "#E3D8FF", name: "Lavender")
    public static let peach = NoteColor(hex: "#FFDDC1", name: "Peach")

    public static let presets: [NoteColor] = [
        .butter,
        .blush,
        .mint,
        .sky,
        .lavender,
        .peach
    ]

    public static func normalize(hex: String) -> String {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted).uppercased()
        if clean.count == 6 {
            return "#\(clean)"
        }
        return "#FFF3B0"
    }

    public var rgb: (red: Double, green: Double, blue: Double) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard clean.count == 6, let value = Int(clean, radix: 16) else {
            return (1.0, 0.95, 0.69)
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        return (r, g, b)
    }

    /// Computes relative luminance according to WCAG 2.1
    public var relativeLuminance: Double {
        func channelLuminance(_ val: Double) -> Double {
            val <= 0.03928 ? val / 12.92 : pow((val + 0.055) / 1.055, 2.4)
        }
        let (r, g, b) = rgb
        return 0.2126 * channelLuminance(r) + 0.7152 * channelLuminance(g) + 0.0722 * channelLuminance(b)
    }

    /// Whether text on this color should be dark
    public var requiresDarkText: Bool {
        if let customInk = customInkHex {
            let inkColor = NoteColor(hex: customInk)
            return inkColor.relativeLuminance < 0.5
        }
        return relativeLuminance > 0.4
    }

    /// Deep graphite ink for light backgrounds (#1C1D21), crisp white for dark backgrounds (#F7F7F9), or custom chosen ink
    public var inkHex: String {
        if let customInk = customInkHex {
            return NoteColor.normalize(hex: customInk)
        }
        return requiresDarkText ? "#1C1D21" : "#F7F7F9"
    }

    /// Secondary ink for subtitles, placeholders, and subtle borders
    public var secondaryInkHex: String {
        requiresDarkText ? "#595B65" : "#AEB0B8"
    }

    /// Tertiary ink for very subtle indicators
    public var tertiaryInkHex: String {
        requiresDarkText ? "#8C8E99" : "#72747D"
    }

    /// Softened color for dark mode (muted pastel on charcoal)
    public var darkThemeHex: String {
        let (r, g, b) = rgb
        // Blend towards charcoal (0.16, 0.17, 0.20)
        let softenedR = Int((r * 0.45 + 0.16 * 0.55) * 255.0)
        let softenedG = Int((g * 0.45 + 0.17 * 0.55) * 255.0)
        let softenedB = Int((b * 0.45 + 0.20 * 0.55) * 255.0)
        return String(format: "#%02X%02X%02X", softenedR, softenedG, softenedB)
    }
}
