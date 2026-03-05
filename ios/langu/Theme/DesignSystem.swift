import SwiftUI

// MARK: - Spacing (More generous for touch targets)

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
    static let huge: CGFloat = 48
}

// MARK: - Border Radius (Duolingo-style rounded corners)

enum AppRadius {
    /// Small elements (badges, small chips)
    static let sm: CGFloat = 12

    /// Medium elements (input fields, small cards)
    static let md: CGFloat = 16

    /// Large elements (cards, modals)
    static let lg: CGFloat = 20

    /// Extra large (big cards, sheets)
    static let xl: CGFloat = 24

    /// 2XL for hero cards
    static let xxl: CGFloat = 28

    /// Pill shape (buttons, tabs)
    static let pill: CGFloat = 999
}

// MARK: - Animations (Bouncy, playful)

enum AppAnimation {
    /// Standard spring - bouncy and playful
    static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    /// Bouncy spring for celebrations
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.5)

    /// Extra bouncy for rewards
    static let springPop = Animation.spring(response: 0.3, dampingFraction: 0.4)

    /// Quick ease out
    static let quick = Animation.easeOut(duration: 0.2)

    /// Smooth ease out
    static let easeOut = Animation.easeOut(duration: 0.3)

    /// Slow for background effects
    static let slow = Animation.easeInOut(duration: 0.6)

    /// Staggered animation for lists
    static func stagger(index: Int, base: Double = 0.04) -> Animation {
        .spring(response: 0.35, dampingFraction: 0.7).delay(Double(index) * base)
    }
}

// MARK: - Shadows (Soft and subtle)

enum AppShadow {
    static let sm = (color: Color.black.opacity(0.04), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    static let md = (color: Color.black.opacity(0.06), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
    static let lg = (color: Color.black.opacity(0.08), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))

    /// Colored shadow for accent elements
    static func colored(_ color: Color) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (color: color.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// MARK: - View Modifiers

/// Rounded card style with soft shadow
struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.appCardBg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .shadow(color: AppShadow.md.color, radius: AppShadow.md.radius, x: AppShadow.md.x, y: AppShadow.md.y)
    }
}

/// Pill-shaped button style
struct PillButtonStyle: ButtonStyle {
    let color: Color
    let textColor: Color

    init(color: Color = .appGreen, textColor: Color = .white) {
        self.color = color
        self.textColor = textColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundStyle(textColor)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(color)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Secondary pill button with border
struct SecondaryPillButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = .appGreen) {
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.headline())
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.2), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Pop-in animation modifier
struct PopInModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1 : 0.7)
            .opacity(isVisible ? 1 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65).delay(delay), value: isVisible)
    }
}

/// 3D press button style - uses ButtonStyle for proper scroll gesture handling
struct Press3DButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96
    var pressedOffsetY: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .offset(y: configuration.isPressed ? pressedOffsetY : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Bounce effect on tap
struct BounceModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

/// Floating card style (elevated)
struct FloatingCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.lg)
            .background(Color.appCardBg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
            .shadow(color: AppShadow.lg.color, radius: AppShadow.lg.radius, x: AppShadow.lg.x, y: AppShadow.lg.y)
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.lg) -> some View {
        modifier(CardStyle(padding: padding))
    }

    func floatingCard() -> some View {
        modifier(FloatingCardStyle())
    }

    func popIn(isVisible: Bool, delay: Double = 0) -> some View {
        modifier(PopInModifier(isVisible: isVisible, delay: delay))
    }

    func bounceOnTap() -> some View {
        modifier(BounceModifier())
    }

    /// Apply consistent corner radius with continuous style
    func roundedCorners(_ radius: CGFloat = AppRadius.lg) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Soft shadow
    func softShadow() -> some View {
        shadow(color: AppShadow.md.color, radius: AppShadow.md.radius, x: AppShadow.md.x, y: AppShadow.md.y)
    }
}
