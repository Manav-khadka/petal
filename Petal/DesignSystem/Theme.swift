import PetalKit
import SwiftUI

public enum PetalTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case paper = "Paper"

    public var id: String {
        rawValue
    }
}

public enum Spacing {
    public static let xxs: CGFloat = 2
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32
}

public enum PetalColor {
    public static let butter = Color(hex: "#FFF3B0")
    public static let blush = Color(hex: "#FFD6E0")
    public static let mint = Color(hex: "#CFF3E1")
    public static let sky = Color(hex: "#CDE7FF")
    public static let lavender = Color(hex: "#E3D8FF")
    public static let peach = Color(hex: "#FFDDC1")

    public static let charcoal = Color(hex: "#1E1F24")
    public static let darkCard = Color(hex: "#282A30")
    public static let darkBorder = Color(hex: "#383B44")

    public static func resolve(noteColor: NoteColor, theme: PetalTheme) -> Color {
        switch theme {
        case .light:
            return Color(hex: noteColor.hex)
        case .dark:
            return Color(hex: noteColor.darkThemeHex)
        case .paper:
            return Color(hex: noteColor.hex).opacity(0.92)
        }
    }

    public static func textColor(for noteColor: NoteColor, theme: PetalTheme) -> Color {
        if theme == .dark {
            let softened = NoteColor(hex: noteColor.darkThemeHex)
            return Color(hex: softened.inkHex)
        }
        return Color(hex: noteColor.inkHex)
    }

    public static func secondaryTextColor(for noteColor: NoteColor, theme: PetalTheme) -> Color {
        if theme == .dark {
            let softened = NoteColor(hex: noteColor.darkThemeHex)
            return Color(hex: softened.secondaryInkHex)
        }
        return Color(hex: noteColor.secondaryInkHex)
    }

    public static func nsTextColor(for noteColor: NoteColor, theme: PetalTheme) -> NSColor {
        if theme == .dark {
            let softened = NoteColor(hex: noteColor.darkThemeHex)
            return NSColor(hex: softened.inkHex)
        }
        return NSColor(hex: noteColor.inkHex)
    }

    public static func nsSecondaryTextColor(for noteColor: NoteColor, theme: PetalTheme) -> NSColor {
        if theme == .dark {
            let softened = NoteColor(hex: noteColor.darkThemeHex)
            return NSColor(hex: softened.secondaryInkHex)
        }
        return NSColor(hex: noteColor.secondaryInkHex)
    }
}

public extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let r, g, b: UInt64
        switch clean.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 243, 176) // Default Butter
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

public extension NSColor {
    convenience init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&int)
        let r, g, b: UInt64
        switch clean.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (28, 29, 33)
        }
        self.init(
            srgbRed: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: 1.0
        )
    }
}

public struct NoteShadowModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
    }
}

public extension View {
    func noteCardShadow() -> some View {
        modifier(NoteShadowModifier())
    }
}
