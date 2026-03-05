import SwiftUI
import SwiftData

struct DailyGoalCard: View {
    @AppStorage("dailyGoal") private var dailyGoal = 3
    @Query private var records: [PracticeRecord]
    @State private var showCelebration = false
    @State private var hasShownCelebration = false

    private var todayLessons: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDateInToday($0.date) }.count
    }

    private var progress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todayLessons) / Double(dailyGoal))
    }

    private var isGoalComplete: Bool {
        todayLessons >= dailyGoal
    }

    private var todayXP: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDateInToday($0.date) }.reduce(0) { $0 + $1.xpEarned }
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Goal")
                        .font(AppFont.headline())
                        .foregroundColor(.appTextPrimary)

                    Text(isGoalComplete ? "Completed!" : "\(todayLessons)/\(dailyGoal) lessons")
                        .font(AppFont.caption())
                        .foregroundColor(isGoalComplete ? .appGreen : .appTextSecondary)
                }

                Spacer()

                // XP earned today - pill style
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.appYellow)

                    Text("+\(todayXP)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.appYellowLight)
                .clipShape(Capsule())
            }

            // Progress bar - more rounded
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.appSurface)
                        .frame(height: 14)

                    // Progress
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.appGreen, .appGreenDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(14, geometry.size.width * progress), height: 14)
                        .animation(AppAnimation.springBouncy, value: progress)
                }
            }
            .frame(height: 14)

            // Lesson indicators - larger circles
            HStack(spacing: AppSpacing.md) {
                ForEach(0..<dailyGoal, id: \.self) { index in
                    Circle()
                        .fill(index < todayLessons ? Color.appGreen : Color.appSurface)
                        .frame(width: 28, height: 28)
                        .overlay {
                            if index < todayLessons {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .shadow(
                            color: index < todayLessons ? AppShadow.colored(.appGreen).color : .clear,
                            radius: index < todayLessons ? 6 : 0,
                            x: 0,
                            y: 3
                        )
                        .animation(AppAnimation.stagger(index: index), value: todayLessons)
                }

                Spacer()

                if isGoalComplete {
                    Text("🎉")
                        .font(.system(size: 28))
                        .scaleEffect(showCelebration ? 1.3 : 1.0)
                        .animation(AppAnimation.springPop.repeatCount(3, autoreverses: true), value: showCelebration)
                }
            }
        }
        .padding(AppSpacing.xl)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
        .shadow(color: AppShadow.md.color, radius: AppShadow.md.radius, x: AppShadow.md.x, y: AppShadow.md.y)
        .overlay {
            if isGoalComplete && !hasShownCelebration {
                CelebrationOverlay()
                    .onAppear {
                        showCelebration = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            hasShownCelebration = true
                        }
                    }
            }
        }
        .onChange(of: isGoalComplete) { _, newValue in
            if newValue && !hasShownCelebration {
                showCelebration = true
            }
        }
    }
}

// MARK: - Celebration Overlay

private struct CelebrationOverlay: View {
    @State private var particles: [Particle] = []
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Text(particle.emoji)
                        .font(.system(size: particle.size))
                        .position(
                            x: particle.x,
                            y: isAnimating ? geometry.size.height + 50 : particle.y
                        )
                        .opacity(isAnimating ? 0 : 1)
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            generateParticles()
            withAnimation(.easeOut(duration: 2.0)) {
                isAnimating = true
            }
        }
    }

    private func generateParticles() {
        let emojis = ["🎉", "⭐", "✨", "🌟", "💫", "🎊"]
        particles = (0..<12).map { _ in
            Particle(
                emoji: emojis.randomElement()!,
                x: CGFloat.random(in: 20...350),
                y: CGFloat.random(in: -50...0),
                size: CGFloat.random(in: 16...28)
            )
        }
    }
}

private struct Particle: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
}

#Preview {
    DailyGoalCard()
        .padding()
        .background(Color.appBg)
        .modelContainer(for: PracticeRecord.self, inMemory: true)
}
