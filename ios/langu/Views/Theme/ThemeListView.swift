import SwiftUI

struct ThemeListView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Header
                headerSection
                    .popIn(isVisible: appeared, delay: 0)

                // Theme cards
                VStack(spacing: AppSpacing.md) {
                    ForEach(Array(ContentLoader.themes.enumerated()), id: \.element.id) { index, theme in
                        ThemeCard(theme: theme) {
                            appState.navigateToThemePractice(theme)
                        }
                        .popIn(isVisible: appeared, delay: 0.05 + Double(index) * 0.03)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.appBg)
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Button {
                appState.navigateHome()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Free Talk")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.appTextPrimary)
                Text("Choose a theme and speak freely")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            // Spacer for balance
            Color.clear.frame(width: 18, height: 18)
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: Theme
    let action: () -> Void

    private var difficultyColor: Color {
        switch theme.difficulty {
        case .beginner: return .appGreen
        case .intermediate: return .appYellow
        case .advanced: return .appRed
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.lg) {
                // Emoji
                ZStack {
                    Circle()
                        .fill(difficultyColor.opacity(0.15))
                        .frame(width: 52, height: 52)

                    Text(theme.emoji)
                        .font(.system(size: 26))
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(theme.name)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appTextPrimary)

                    Text(theme.koreanName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)

                    HStack(spacing: AppSpacing.sm) {
                        Text(theme.difficulty.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(difficultyColor)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(difficultyColor.opacity(0.12))
                            .clipShape(Capsule())

                        Text("\(theme.minDurationSeconds)s+")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appTextMuted)
                    }
                }

                Spacer()

                // Arrow
                ZStack {
                    Circle()
                        .fill(difficultyColor)
                        .frame(width: 32, height: 32)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(AppSpacing.lg)
            .background(Color.appCardBg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
        }
        .buttonStyle(.plain)
    }
}
