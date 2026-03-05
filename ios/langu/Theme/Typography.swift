import SwiftUI

enum AppFont {
    // Nunito for body text
    static func nunito(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold: return .custom("Nunito-Bold", size: size)
        case .semibold: return .custom("Nunito-SemiBold", size: size)
        case .heavy, .black: return .custom("Nunito-ExtraBold", size: size)
        case .medium: return .custom("Nunito-Medium", size: size)
        case .light: return .custom("Nunito-Light", size: size)
        default: return .custom("Nunito-Regular", size: size)
        }
    }

    // DM Mono for timer/code
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .medium, .semibold, .bold: return .custom("DMMono-Medium", size: size)
        case .light: return .custom("DMMono-Light", size: size)
        default: return .custom("DMMono-Regular", size: size)
        }
    }

    // Fallback system fonts (used if custom fonts not installed)
    static func title() -> Font { .system(size: 24, weight: .bold, design: .rounded) }
    static func headline() -> Font { .system(size: 18, weight: .semibold, design: .rounded) }
    static func body() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func caption() -> Font { .system(size: 13, weight: .medium, design: .rounded) }
    static func timer() -> Font { .system(size: 16, weight: .medium, design: .monospaced) }
    static func koreanPrompt() -> Font { .system(size: 22, weight: .heavy, design: .default) }
    static func scoreDisplay() -> Font { .system(size: 48, weight: .bold, design: .rounded) }
}
