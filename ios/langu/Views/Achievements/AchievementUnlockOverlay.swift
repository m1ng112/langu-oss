import SwiftUI

struct AchievementUnlockOverlay: View {
    @Environment(AchievementService.self) private var achievementService
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -15
    @State private var showConfetti = false

    var body: some View {
        if achievementService.showUnlockAnimation, let achievement = achievementService.recentlyUnlocked {
            ZStack {
                // Dimmed background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .opacity(opacity)
                    .onTapGesture {
                        dismissOverlay()
                    }

                // Confetti particles
                if showConfetti {
                    ConfettiView()
                }

                // Achievement card
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    Text("Achievement Unlocked!")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(achievement.rarity.color)
                        .textCase(.uppercase)
                        .tracking(2)

                    // Badge
                    ZStack {
                        // Glow
                        Circle()
                            .fill(achievement.rarity.glowColor)
                            .blur(radius: 30)
                            .scaleEffect(1.5)

                        // Main badge
                        Circle()
                            .fill(achievement.rarity.color.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Circle()
                            .strokeBorder(achievement.rarity.color, lineWidth: 4)
                            .frame(width: 100, height: 100)

                        Text(achievement.emoji)
                            .font(.system(size: 48))
                    }
                    .frame(width: 120, height: 120)

                    // Title
                    VStack(spacing: AppSpacing.xs) {
                        Text(achievement.title)
                            .font(AppFont.headline())
                            .foregroundStyle(Color.appTextPrimary)

                        Text(achievement.koreanTitle)
                            .font(AppFont.body())
                            .foregroundStyle(Color.appTextSecondary)
                    }

                    // Description
                    Text(achievement.description)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Rewards
                    HStack(spacing: AppSpacing.lg) {
                        // Rarity
                        HStack(spacing: AppSpacing.xs) {
                            Circle()
                                .fill(achievement.rarity.color)
                                .frame(width: 8, height: 8)
                            Text(achievement.rarity.rawValue)
                                .font(AppFont.caption())
                                .foregroundStyle(achievement.rarity.color)
                        }

                        // XP
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.appYellow)
                            Text("+\(achievement.xpReward) XP")
                                .font(AppFont.caption())
                                .foregroundStyle(Color.appYellow)
                        }
                    }
                    .padding(.top, AppSpacing.sm)
                }
                .padding(AppSpacing.xxl)
                .background(Color.appCardBg)
                .cornerRadius(AppRadius.xl)
                .shadow(color: achievement.rarity.color.opacity(0.3), radius: 30, x: 0, y: 10)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1
                    rotation = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showConfetti = true
                }
            }
        }
    }

    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }
    }
}

// MARK: - Confetti View

private struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(
                            x: particle.x,
                            y: isAnimating ? geometry.size.height + 100 : particle.startY
                        )
                        .rotationEffect(.degrees(isAnimating ? particle.rotation + 360 : particle.rotation))
                        .opacity(isAnimating ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            generateParticles()
            withAnimation(.easeOut(duration: 3)) {
                isAnimating = true
            }
        }
    }

    private func generateParticles() {
        let emojis = ["🎉", "⭐", "✨", "🌟", "💫", "🎊", "🏆", "💎", "🔥", "👑"]
        particles = (0..<20).map { _ in
            ConfettiParticle(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: 20...UIScreen.main.bounds.width - 20),
                startY: CGFloat.random(in: -100...0),
                size: CGFloat.random(in: 16...32),
                rotation: Double.random(in: 0...360)
            )
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let startY: CGFloat
    let size: CGFloat
    let rotation: Double
}

#Preview {
    ZStack {
        Color.appBg
            .ignoresSafeArea()

        Text("Main Content")
            .foregroundStyle(Color.appTextPrimary)

        AchievementUnlockOverlay()
    }
    .environment(AchievementService())
}
