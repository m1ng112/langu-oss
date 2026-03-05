import SwiftUI

struct StreakBadge: View {
    let streak: Int
    @State private var isPulsing = false
    @State private var showMilestone = false

    private var streakTier: StreakTier {
        StreakTier.from(days: streak)
    }

    private var isMilestone: Bool {
        [7, 14, 30, 50, 100, 365].contains(streak)
    }

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            // Flame icon with tier color
            ZStack {
                // Glow effect for higher tiers
                if streakTier.ordinal >= 2 {
                    Text("🔥")
                        .font(.system(size: 20))
                        .blur(radius: 8)
                        .opacity(isPulsing ? 0.8 : 0.4)
                }

                Text(streakTier.emoji)
                    .font(.system(size: 18))
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
            }

            Text("\(streak)")
                .font(AppFont.headline())
                .foregroundStyle(streakTier.textColor)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.sm)
        .background(streakTier.backgroundColor)
        .clipShape(Capsule())
        .shadow(
            color: streak > 0 ? streakTier.textColor.opacity(0.2) : .clear,
            radius: 8,
            x: 0,
            y: 4
        )
        .overlay {
            if isMilestone && showMilestone {
                MilestoneOverlay(streak: streak)
            }
        }
        .onAppear {
            if streak > 0 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
            if isMilestone {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showMilestone = true
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilityLabels.streakBadge(days: streak))
    }
}

// MARK: - Streak Tier

enum StreakTier {
    case none       // 0 days
    case starter    // 1-6 days - orange flame
    case weekly     // 7-13 days - blue flame
    case biweekly   // 14-29 days - purple flame
    case monthly    // 30-99 days - rainbow/gold
    case legendary  // 100+ days - special

    var emoji: String {
        switch self {
        case .none: return "🔥"
        case .starter: return "🔥"
        case .weekly: return "🔵"
        case .biweekly: return "🟣"
        case .monthly: return "⭐"
        case .legendary: return "💎"
        }
    }

    var textColor: Color {
        switch self {
        case .none: return .appTextMuted
        case .starter: return .appOrange
        case .weekly: return .appBlue
        case .biweekly: return .appPurple
        case .monthly: return .appYellow
        case .legendary: return Color(hex: "10B981") // Emerald
        }
    }

    var backgroundColor: Color {
        switch self {
        case .none: return Color.appSurface
        case .starter: return Color.appYellowLight
        case .weekly: return Color.appBlue.opacity(0.15)
        case .biweekly: return Color.appPurple.opacity(0.15)
        case .monthly: return Color.appYellow.opacity(0.2)
        case .legendary: return Color(hex: "10B981").opacity(0.15)
        }
    }

    var ordinal: Int {
        switch self {
        case .none: return 0
        case .starter: return 1
        case .weekly: return 2
        case .biweekly: return 3
        case .monthly: return 4
        case .legendary: return 5
        }
    }

    static func from(days: Int) -> StreakTier {
        switch days {
        case 0: return .none
        case 1...6: return .starter
        case 7...13: return .weekly
        case 14...29: return .biweekly
        case 30...99: return .monthly
        default: return .legendary
        }
    }
}

// MARK: - Milestone Overlay

private struct MilestoneOverlay: View {
    let streak: Int
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.5

    private var milestoneMessage: String {
        switch streak {
        case 7: return "1 Week! 🎉"
        case 14: return "2 Weeks! 🔥"
        case 30: return "1 Month! 🏆"
        case 50: return "50 Days! ⭐"
        case 100: return "100 Days! 💎"
        case 365: return "1 Year! 👑"
        default: return "Milestone!"
        }
    }

    var body: some View {
        if isVisible {
            Text(milestoneMessage)
                .font(AppFont.caption())
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.appGreen)
                .cornerRadius(AppRadius.sm)
                .scaleEffect(scale)
                .offset(y: -40)
                .transition(.scale.combined(with: .opacity))
        }
    }

    init(streak: Int) {
        self.streak = streak
        _isVisible = State(initialValue: false)
    }

    var body2: some View {
        EmptyView()
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isVisible = true
                    scale = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakBadge(streak: 0)
        StreakBadge(streak: 3)
        StreakBadge(streak: 7)
        StreakBadge(streak: 14)
        StreakBadge(streak: 30)
        StreakBadge(streak: 100)
    }
    .padding()
    .background(Color.appBg)
}
