import SwiftUI

struct AchievementBadge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    let unlockedDate: Date?

    @State private var isGlowing = false

    private var displayEmoji: String {
        isUnlocked ? achievement.emoji : "🔒"
    }

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Badge Circle
            ZStack {
                // Glow effect for unlocked rare+ achievements
                if isUnlocked && achievement.rarity.ordinal >= 2 {
                    Circle()
                        .fill(achievement.rarity.glowColor)
                        .blur(radius: 12)
                        .scaleEffect(isGlowing ? 1.2 : 1.0)
                }

                // Background circle
                Circle()
                    .fill(
                        isUnlocked
                            ? achievement.rarity.color.opacity(0.2)
                            : Color.appSurface
                    )

                // Border
                Circle()
                    .strokeBorder(
                        isUnlocked
                            ? achievement.rarity.color
                            : Color.appTextMuted.opacity(0.3),
                        lineWidth: isUnlocked ? 3 : 1.5
                    )

                // Progress ring for locked achievements
                if !isUnlocked && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            achievement.rarity.color,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                // Emoji
                Text(displayEmoji)
                    .font(.system(size: 28))
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1 : 0.5)
            }
            .frame(width: 68, height: 68)
            .shadow(
                color: isUnlocked ? achievement.rarity.color.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )

            // Title
            Text(achievement.title)
                .font(AppFont.caption())
                .foregroundStyle(isUnlocked ? Color.appTextPrimary : Color.appTextMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)

            // Rarity indicator
            if isUnlocked {
                Text(achievement.rarity.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(achievement.rarity.color)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 3)
                    .background(achievement.rarity.color.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .frame(width: 88)
        .padding(.vertical, AppSpacing.sm)
        .onAppear {
            if isUnlocked && achievement.rarity.ordinal >= 2 {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
        }
    }
}

// MARK: - Large Badge (for detail view)

struct AchievementBadgeLarge: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let progress: Double
    let progressText: String
    let unlockedDate: Date?

    @State private var isGlowing = false
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Badge
            ZStack {
                // Animated glow for legendary
                if isUnlocked && achievement.rarity == .legendary {
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.appYellow, .appOrange, .appPurple, .appBlue, .appYellow],
                                center: .center
                            )
                        )
                        .blur(radius: 20)
                        .scaleEffect(1.3)
                        .rotationEffect(.degrees(rotation))
                        .opacity(0.6)
                }

                // Glow
                if isUnlocked && achievement.rarity.ordinal >= 2 {
                    Circle()
                        .fill(achievement.rarity.glowColor)
                        .blur(radius: 20)
                        .scaleEffect(isGlowing ? 1.3 : 1.1)
                }

                // Background
                Circle()
                    .fill(
                        isUnlocked
                            ? achievement.rarity.color.opacity(0.2)
                            : Color.appSurface
                    )

                // Border
                Circle()
                    .strokeBorder(
                        isUnlocked
                            ? achievement.rarity.color
                            : Color.appTextMuted.opacity(0.3),
                        lineWidth: isUnlocked ? 4 : 2
                    )

                // Progress ring
                if !isUnlocked && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            achievement.rarity.color,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                // Emoji
                Text(isUnlocked ? achievement.emoji : "🔒")
                    .font(.system(size: 56))
                    .grayscale(isUnlocked ? 0 : 1)
                    .opacity(isUnlocked ? 1 : 0.5)
            }
            .frame(width: 120, height: 120)

            // Title & Korean
            VStack(spacing: AppSpacing.xs) {
                Text(achievement.title)
                    .font(AppFont.headline())
                    .foregroundStyle(isUnlocked ? Color.appTextPrimary : Color.appTextMuted)

                Text(achievement.koreanTitle)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appTextSecondary)
            }

            // Description
            Text(achievement.description)
                .font(AppFont.caption())
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            // Rarity & XP
            HStack(spacing: AppSpacing.lg) {
                // Rarity badge
                HStack(spacing: AppSpacing.xs) {
                    Circle()
                        .fill(achievement.rarity.color)
                        .frame(width: 8, height: 8)
                    Text(achievement.rarity.rawValue)
                        .font(AppFont.caption())
                        .foregroundStyle(achievement.rarity.color)
                }

                // XP reward
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appYellow)
                    Text("+\(achievement.xpReward) XP")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            // Progress or unlock date
            if isUnlocked, let date = unlockedDate {
                Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextMuted)
            } else if progress > 0 {
                VStack(spacing: AppSpacing.sm) {
                    // Progress bar - capsule style
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.appSurface)
                            Capsule()
                                .fill(achievement.rarity.color)
                                .frame(width: max(10, geometry.size.width * progress))
                        }
                    }
                    .frame(height: 10)
                    .frame(maxWidth: 200)

                    Text(progressText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextMuted)
                }
            }
        }
        .padding(AppSpacing.xl)
        .onAppear {
            if isUnlocked {
                if achievement.rarity.ordinal >= 2 {
                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                        isGlowing = true
                    }
                }
                if achievement.rarity == .legendary {
                    withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
        }
    }
}

// MARK: - Rarity Ordinal

private extension AchievementRarity {
    var ordinal: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            AchievementBadge(achievement: .firstLesson, isUnlocked: true, progress: 1.0, unlockedDate: .now)
            AchievementBadge(achievement: .weekStreak, isUnlocked: false, progress: 0.5, unlockedDate: nil)
            AchievementBadge(achievement: .hundredLessons, isUnlocked: true, progress: 1.0, unlockedDate: .now)
        }

        AchievementBadgeLarge(
            achievement: .quarterStreak,
            isUnlocked: true,
            progress: 1.0,
            progressText: "90/90",
            unlockedDate: .now
        )
    }
    .padding()
    .background(Color.appBg)
}
