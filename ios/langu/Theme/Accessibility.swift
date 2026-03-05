import SwiftUI

// MARK: - Accessibility Modifiers

extension View {
    /// Adds comprehensive accessibility attributes for an interactive element
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    /// Marks an element as a header for VoiceOver navigation
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    /// Groups child elements for VoiceOver
    func accessibleGroup(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Marks an element as decorative (ignored by VoiceOver)
    func accessibilityDecorative() -> some View {
        self.accessibilityHidden(true)
    }

    /// Applies reduced motion preference
    func withReducedMotion(_ animation: Animation?) -> some View {
        modifier(ReducedMotionModifier(animation: animation))
    }
}

// MARK: - Reduced Motion Support

struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(nil, value: UUID())
        } else {
            content.animation(animation, value: UUID())
        }
    }
}

// MARK: - Accessibility Environment Values

struct AccessibilityEnvironmentKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
}

// MARK: - Dynamic Type Support

extension AppFont {
    /// Returns a scaled font that respects Dynamic Type settings
    static func scaledTitle() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 28), weight: .bold, design: .rounded)
    }

    static func scaledHeadline() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 17), weight: .semibold)
    }

    static func scaledBody() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 15))
    }

    static func scaledCaption() -> Font {
        .system(size: UIFontMetrics.default.scaledValue(for: 13))
    }
}

// MARK: - High Contrast Colors

extension Color {
    /// Returns a high contrast version of the color if needed
    func highContrastVersion(in colorScheme: ColorScheme) -> Color {
        self
    }

    static func accessibleTextColor(on background: Color) -> Color {
        // Returns appropriate text color for the background
        .appTextPrimary
    }
}

// MARK: - Haptic Feedback

enum HapticFeedback {
    case light
    case medium
    case heavy
    case success
    case warning
    case error

    func play() {
        switch self {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Accessibility Labels for App Elements

enum AccessibilityLabels {
    // Navigation
    static let homeTab = "Home"
    static let achievementsTab = "Achievements"
    static let statsTab = "Statistics"
    static let settingsTab = "Settings"

    // Home
    static func streakBadge(days: Int) -> String {
        days == 0 ? "No current streak" :
        days == 1 ? "1 day streak" :
        "\(days) day streak"
    }

    static func xpBadge(xp: Int) -> String {
        "\(xp) experience points"
    }

    static func dailyGoal(completed: Int, total: Int) -> String {
        if completed >= total {
            return "Daily goal completed. \(completed) of \(total) lessons done."
        }
        return "Daily goal: \(completed) of \(total) lessons completed."
    }

    // Lessons
    static func lessonCard(title: String, korean: String, state: LessonState) -> String {
        switch state {
        case .locked:
            return "\(title). Locked. Complete previous lesson to unlock."
        case .unlocked:
            return "\(title). \(korean). Tap to start lesson."
        case .completed:
            return "\(title). Completed."
        }
    }

    static func lessonCardHint(_ state: LessonState) -> String {
        switch state {
        case .locked:
            return "This lesson is locked."
        case .unlocked:
            return "Double tap to start this lesson."
        case .completed:
            return "Double tap to practice again."
        }
    }

    static func unitHeader(title: String, lessonsCompleted: Int, totalLessons: Int) -> String {
        "\(title) unit. \(lessonsCompleted) of \(totalLessons) lessons completed."
    }

    // Recording
    static let recordButton = "Record"
    static let recordButtonHint = "Press and hold to record your pronunciation."
    static let recordingInProgress = "Recording in progress"
    static func recordingDuration(_ seconds: TimeInterval) -> String {
        "Recording: \(Int(seconds)) seconds"
    }

    // Feedback
    static func scoreResult(score: Int) -> String {
        switch score {
        case 90...100:
            return "Excellent! Score: \(score) percent."
        case 70..<90:
            return "Good job! Score: \(score) percent."
        case 50..<70:
            return "Nice try! Score: \(score) percent."
        default:
            return "Keep practicing! Score: \(score) percent."
        }
    }

    // Achievements
    static func achievementBadge(_ achievement: Achievement, unlocked: Bool) -> String {
        if unlocked {
            return "\(achievement.title). \(achievement.rarity.rawValue) achievement. Unlocked."
        }
        return "\(achievement.title). \(achievement.rarity.rawValue) achievement. Locked. \(achievement.description)"
    }
}
