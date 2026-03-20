import SwiftUI

// DESIGN_SPEC: "Minimal × Energetic"
// No box-shadow. Background color hierarchy for depth: surface → surface2 → white
// Only 1 looping animation: streak flame pulse (2s)
// Interaction: transition only (0.12s tap, 0.15s hover)

// MARK: - Spacing

enum AppSpacing {
    /// Icon-text gap
    static let xs: CGFloat = 4
    /// 8px
    static let sm: CGFloat = 8
    /// Card inner padding (small), card gap
    static let md: CGFloat = 12
    /// Section inner padding
    static let lg: CGFloat = 16
    /// Card inner padding (standard)
    static let xl: CGFloat = 20
    /// Screen horizontal margin
    static let xxl: CGFloat = 24
    /// 32px
    static let xxxl: CGFloat = 32
    /// Section gap
    static let huge: CGFloat = 40
}

// MARK: - Border Radius

enum AppRadius {
    /// Small elements (badges, chips)
    static let sm: CGFloat = 12

    /// Medium elements (practice mode cards)
    static let md: CGFloat = 12

    /// Large elements (cards)
    static let lg: CGFloat = 16

    /// Extra large (streak banner, mission card)
    static let xl: CGFloat = 20

    /// 2XL for hero cards
    static let xxl: CGFloat = 20

    /// Pill shape (buttons, tabs)
    static let pill: CGFloat = 999
}

// MARK: - Animations

enum AppAnimation {
    /// Streak flame pulse — the ONLY looping animation
    static let pulse = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)

    /// Page load: section fade-up
    static let fadeUp = Animation.easeOut(duration: 0.3)

    /// Tap shrink: scale(0.98)
    static let tap = Animation.easeOut(duration: 0.12)

    /// Hover/state change
    static let hover = Animation.easeOut(duration: 0.15)

    /// Legacy aliases
    static let spring = Animation.easeOut(duration: 0.15)
    static let springBouncy = Animation.easeOut(duration: 0.15)
    static let springPop = Animation.easeOut(duration: 0.12)
    static let quick = Animation.easeOut(duration: 0.12)
    static let easeOut = Animation.easeOut(duration: 0.15)
    static let slow = Animation.easeOut(duration: 0.3)

    /// Staggered fade-up for lists
    static func stagger(index: Int, base: Double = 0.1) -> Animation {
        .easeOut(duration: 0.3).delay(Double(index) * base)
    }
}

// MARK: - Shadows (Kept for backward compat, but zeroed out per spec)

enum AppShadow {
    /// No shadow — use surface color hierarchy instead
    static let sm = (color: Color.clear, radius: CGFloat(0), x: CGFloat(0), y: CGFloat(0))
    static let md = (color: Color.clear, radius: CGFloat(0), x: CGFloat(0), y: CGFloat(0))
    static let lg = (color: Color.clear, radius: CGFloat(0), x: CGFloat(0), y: CGFloat(0))

    static func colored(_ color: Color) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        (color: Color.clear, radius: 0, x: 0, y: 0)
    }
}

// MARK: - View Modifiers

/// Card style using background color hierarchy (no shadow)
struct CardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.xl

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.surface2)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }
}

/// Scale-on-press button style — does NOT block ScrollView gestures
struct ScalePressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Pill-shaped button — accent color
struct PillButtonStyle: ButtonStyle {
    let color: Color
    let textColor: Color

    init(color: Color = .appAccent, textColor: Color = .white) {
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppAnimation.tap, value: configuration.isPressed)
    }
}

/// Secondary pill button with border
struct SecondaryPillButtonStyle: ButtonStyle {
    let color: Color

    init(color: Color = .appAccent) {
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppAnimation.tap, value: configuration.isPressed)
    }
}

/// Fade-up entrance modifier (replaces pop-in)
struct PopInModifier: ViewModifier {
    let isVisible: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 16)
            .animation(.easeOut(duration: 0.3).delay(delay), value: isVisible)
    }
}

/// Tap shrink modifier (subtle, 0.98 scale)
struct BounceModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppAnimation.tap, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

/// Elevated card using white background (highest level)
struct FloatingCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppSpacing.xl)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }
}

// MARK: - View Extensions

extension View {
    func cardStyle(padding: CGFloat = AppSpacing.xl) -> some View {
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

    /// No-op for backward compat (shadows removed per spec)
    func softShadow() -> some View {
        self
    }
}
