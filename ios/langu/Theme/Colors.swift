import SwiftUI

// DESIGN_SPEC: "Minimal × Energetic" color system
// Accent is #ff4c2b only. No purple gradients.

extension Color {
    // MARK: - Brand Colors
    /// CTA, streak, XP bar, active state
    static let appAccent = Color(hex: "ff4c2b")
    /// Gradient pair with accent
    static let accentWarm = Color(hex: "ff8c42")
    /// Light accent background
    static let accentLight = Color(hex: "fff1ee")

    // MARK: - Semantic Colors
    // appGreen is provided by asset catalog (AppGreen.colorset)
    /// SRS today, warning
    static let appGold = Color(hex: "f5a623")
    /// Info, vocabulary
    static let appBlue = Color(hex: "2f6bff")

    // MARK: - Legacy Aliases (for backward compatibility)
    static let appYellow = Color.appGold
    static let appOrange = Color.accentWarm
    static let appRed = Color.appAccent
    static let appPurple = Color.appBlue

    // MARK: - Neutral Colors
    /// Primary text, dark surfaces
    static let ink = Color(hex: "0e0e0f")
    /// Secondary text
    static let ink2 = Color(hex: "3a3a3c")
    /// Placeholder, caption
    static let ink3 = Color(hex: "8e8e93")
    /// App background (deep parchment)
    static let surface = Color(hex: "e8dcc8")
    /// Card background, hover state (warm stone)
    static let surface2 = Color(hex: "d6c9b0")

    // appBg, appCardBg, appSurface, appGreenLight, appGreenDark,
    // appTextPrimary, appTextSecondary, appTextMuted, appYellowLight
    // are all provided by asset catalog colorsets.

    // MARK: - SRS Status Colors
    static let srsDue = Color.appAccent
    static let srsToday = Color.appGold
    static let srsSafe = Color.appGreen

    // MARK: - Score Colors
    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 90...100: return .appGreen
        case 70..<90: return .appBlue
        case 50..<70: return .appGold
        default: return .appAccent
        }
    }

    // MARK: - Hex Init
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
