import SwiftUI

struct LessonCard: View {
    let lesson: Lesson
    let state: LessonState
    let bestScore: Int?
    let action: () -> Void

    private var isLocked: Bool {
        state == .locked
    }

    var body: some View {
        Button(action: {
            guard !isLocked else { return }
            HapticFeedback.light.play()
            action()
        }) {
            HStack(spacing: AppSpacing.lg) {
                // State indicator (round icon)
                stateIndicator

                // Info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(lesson.title)
                        .font(AppFont.headline())
                        .foregroundStyle(isLocked ? Color.appTextMuted : Color.appTextPrimary)

                    HStack(spacing: AppSpacing.sm) {
                        Text(isLocked ? "Complete previous lesson" : lesson.korean)
                            .font(AppFont.body())
                            .foregroundStyle(Color.appTextSecondary)

                        if let score = bestScore, state == .completed {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                Text("\(score)%")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Color.scoreColor(for: score))
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(Color.scoreColor(for: score).opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                // Right indicator
                rightIndicator
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.xxl)
            .background(
                ZStack {
                    if !isLocked {
                        // 3D bottom edge
                        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                            .fill(state == .completed ? Color.appGreen.opacity(0.35) : Color.black.opacity(0.08))
                            .offset(y: 4)
                    }

                    // Main surface
                    RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                        .fill(cardBackgroundColor)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .overlay(cardOverlay)
            .opacity(isLocked ? 0.7 : 1.0)
        }
        .buttonStyle(Press3DButtonStyle(pressedScale: 0.95, pressedOffsetY: 3))
        .disabled(isLocked)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AccessibilityLabels.lessonCard(title: lesson.title, korean: lesson.korean, state: state))
        .accessibilityHint(AccessibilityLabels.lessonCardHint(state))
        .accessibilityAddTraits(isLocked ? [] : .isButton)
    }

    // MARK: - Card Background

    private var cardBackgroundColor: Color {
        if isLocked {
            Color.appSurface.opacity(0.5)
        } else if state == .completed {
            Color.appGreenLight.opacity(0.3)
        } else {
            Color.appCardBg
        }
    }

    // MARK: - Card Overlay

    @ViewBuilder
    private var cardOverlay: some View {
        if state == .completed {
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(Color.appGreen.opacity(0.3), lineWidth: 2)
        }
    }

    // MARK: - State Indicator

    private var stateIndicator: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(state.backgroundColor)
                .frame(width: 64, height: 64)

            // Icon or Emoji
            if state == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            } else if state == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.appTextMuted)
            } else {
                Text(lesson.emoji)
                    .font(.system(size: 32))
            }
        }
    }

    // MARK: - Right Indicator

    @ViewBuilder
    private var rightIndicator: some View {
        if isLocked {
            // Lock badge
            Circle()
                .fill(Color.appSurface)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextMuted)
                )
        } else if state == .completed {
            // Completed badge
            Circle()
                .fill(Color.appGreen)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
        } else {
            // Play button
            Circle()
                .fill(Color.appGreen)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .offset(x: 1) // Visual centering for play icon
                )
        }
    }
}

// MARK: - Backwards Compatibility

extension LessonCard {
    init(lesson: Lesson, action: @escaping () -> Void) {
        self.lesson = lesson
        self.state = .unlocked
        self.bestScore = nil
        self.action = action
    }
}

#Preview {
    VStack(spacing: 16) {
        LessonCard(
            lesson: ContentLoader.lessons[0],
            state: .completed,
            bestScore: 92,
            action: {}
        )

        LessonCard(
            lesson: ContentLoader.lessons[1],
            state: .unlocked,
            bestScore: nil,
            action: {}
        )

        LessonCard(
            lesson: ContentLoader.lessons[2],
            state: .locked,
            bestScore: nil,
            action: {}
        )
    }
    .padding()
    .background(Color.appBg)
}
