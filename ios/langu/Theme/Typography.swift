import SwiftUI

// DESIGN_SPEC: Syne (headings/numbers/labels) + DM Sans (body/UI)
// Forbidden: Inter, Roboto, Arial, system-ui, Space Grotesk, Nunito

enum AppFont {
    // MARK: - Display Font (Syne)
    /// Headings, numbers, labels
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .black, .heavy: return .custom("Syne-ExtraBold", size: size)
        case .bold: return .custom("Syne-Bold", size: size)
        case .semibold: return .custom("Syne-SemiBold", size: size)
        case .medium: return .custom("Syne-Medium", size: size)
        default: return .custom("Syne-Regular", size: size)
        }
    }

    // MARK: - Body Font (DM Sans)
    /// Body text, UI elements
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold, .heavy, .black: return .custom("DMSans-Bold", size: size)
        case .semibold: return .custom("DMSans-SemiBold", size: size)
        case .medium: return .custom("DMSans-Medium", size: size)
        default: return .custom("DMSans-Regular", size: size)
        }
    }

    // MARK: - Size Scale
    static let sizeXs: CGFloat = 10    // Caption, badge
    static let sizeSm: CGFloat = 11    // Section label (UPPERCASE)
    static let sizeBase: CGFloat = 13  // Body, list item
    static let sizeMd: CGFloat = 14    // Card title
    static let sizeLg: CGFloat = 16    // Emphasized text
    static let sizeXl: CGFloat = 20    // Card heading
    static let size2xl: CGFloat = 24   // Number display
    static let size3xl: CGFloat = 28   // Username, large heading

    // MARK: - Preset Styles

    /// Large titles (Syne, 28px, black)
    static func title() -> Font { display(size3xl, weight: .black) }

    /// Section headers (Syne, 20px, bold)
    static func headline() -> Font { display(sizeXl, weight: .bold) }

    /// Body text (DM Sans, 13px, regular)
    static func body() -> Font { body(sizeBase) }

    /// Caption text (DM Sans, 10px, medium)
    static func caption() -> Font { body(sizeXs, weight: .medium) }

    /// Timer/number display (Syne, 24px, black)
    static func timer() -> Font { display(size2xl, weight: .black) }

    /// Korean prompt text (Syne, 20px, black)
    static func koreanPrompt() -> Font { display(sizeXl, weight: .black) }

    /// Large score display (Syne, 48px, black)
    static func scoreDisplay() -> Font { display(48, weight: .black) }

    /// Section label (Syne, 10px, bold, meant for UPPERCASE)
    static func sectionLabel() -> Font { display(sizeXs, weight: .bold) }

    /// Card title (DM Sans, 14px, medium)
    static func cardTitle() -> Font { body(sizeMd, weight: .medium) }

    // MARK: - Legacy Aliases
    static func nunito(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        body(size, weight: weight)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        display(size, weight: weight)
    }
}
