import SwiftUI

struct ErrorBanner: View {
    @Environment(ErrorHandlingService.self) private var errorService

    var body: some View {
        if errorService.showingError, let error = errorService.currentError {
            VStack {
                Spacer()

                HStack(spacing: AppSpacing.md) {
                    // Icon
                    Image(systemName: error.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    // Message
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Error")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))

                        Text(error.localizedDescription)
                            .font(AppFont.body())
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Action button
                    if let action = error.recoveryAction {
                        Button {
                            errorService.performRecovery()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 12))
                                Text(action.title)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }

                    // Dismiss button
                    Button {
                        errorService.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(AppSpacing.sm)
                    }
                }
                .padding(AppSpacing.lg)
                .background(Color.appRed)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, 120) // Above tab bar
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.spring(response: 0.3), value: errorService.showingError)
        }
    }
}

// MARK: - Error Toast (Compact version)

struct ErrorToast: View {
    let message: String
    let icon: String
    let action: (() -> Void)?
    let onDismiss: () -> Void

    @State private var isVisible = true

    var body: some View {
        if isVisible {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)

                Text(message)
                    .font(AppFont.caption())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                if action != nil {
                    Button {
                        action?()
                    } label: {
                        Text("Retry")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                Button {
                    withAnimation {
                        isVisible = false
                    }
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.appRed.opacity(0.9))
            .clipShape(Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    let message: String

    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Custom spinner
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.appGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }

            Text(message)
                .font(AppFont.caption())
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(AppSpacing.xl)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Skeleton Loading Views

struct SkeletonView: View {
    @State private var animating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.appSurface, Color.appSurface.opacity(0.5), Color.appSurface],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(Rectangle())
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: animating ? 300 : -300)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    animating = true
                }
            }
    }
}

struct LessonCardSkeleton: View {
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            SkeletonView()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                SkeletonView()
                    .frame(width: 120, height: 16)

                SkeletonView()
                    .frame(width: 80, height: 14)
            }

            Spacer()

            SkeletonView()
                .frame(width: 50, height: 24)
                .clipShape(Capsule())
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

struct StatCardSkeleton: View {
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            SkeletonView()
                .frame(width: 24, height: 24)

            SkeletonView()
                .frame(width: 40, height: 20)

            SkeletonView()
                .frame(width: 30, height: 14)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.appTextMuted)

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.headline())
                    .foregroundStyle(Color.appTextPrimary)

                Text(message)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppFont.headline())
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appGreen)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(AppSpacing.xxl)
    }
}

#Preview {
    ZStack {
        Color.appBg
            .ignoresSafeArea()

        VStack(spacing: 20) {
            LessonCardSkeleton()

            HStack(spacing: 12) {
                StatCardSkeleton()
                StatCardSkeleton()
                StatCardSkeleton()
            }

            EmptyStateView(
                icon: "book.closed",
                title: "No Lessons Yet",
                message: "Complete your first lesson to see your progress here.",
                actionTitle: "Start Learning",
                action: {}
            )

            LoadingOverlay(message: "Analyzing...")
        }
        .padding()
    }
}
