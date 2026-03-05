import SwiftUI
import AVFoundation

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var microphoneGranted = false

    private let totalPages = 3

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .font(AppFont.body())
                        .foregroundColor(.appTextSecondary)
                        .padding()
                    }
                }
                .frame(height: 50)

                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)

                    HowItWorksPage()
                        .tag(1)

                    MicrophonePage(isGranted: $microphoneGranted)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.appGreen : Color.appTextMuted.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.vertical, 20)

                // Bottom button
                Button(action: handleNextAction) {
                    Text(buttonTitle)
                        .font(AppFont.headline())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.appGreen)
                        .cornerRadius(AppRadius.lg)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.bottom, 40)
            }
        }
    }

    private var buttonTitle: String {
        switch currentPage {
        case 0: return "Get Started"
        case 1: return "Continue"
        case 2: return microphoneGranted ? "Start Learning" : "Enable Microphone"
        default: return "Next"
        }
    }

    private func handleNextAction() {
        if currentPage < totalPages - 1 {
            withAnimation {
                currentPage += 1
            }
        } else if currentPage == totalPages - 1 {
            if microphoneGranted {
                completeOnboarding()
            } else {
                requestMicrophonePermission()
            }
        }
    }

    private func requestMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                microphoneGranted = granted
                if granted {
                    completeOnboarding()
                }
            }
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Welcome Page

private struct WelcomePage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon / illustration
            ZStack {
                Circle()
                    .fill(Color.appGreenLight)
                    .frame(width: 160, height: 160)

                Text("🇰🇷")
                    .font(.system(size: 80))
            }
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Welcome to Langu")
                    .font(AppFont.title())
                    .foregroundColor(.appTextPrimary)

                Text("Master Korean pronunciation\nwith AI-powered feedback")
                    .font(AppFont.body())
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1.0 : 0)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - How It Works Page

private struct HowItWorksPage: View {
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("How It Works")
                .font(AppFont.title())
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 24) {
                StepRow(
                    number: 1,
                    icon: "text.book.closed.fill",
                    title: "Choose a Phrase",
                    description: "Pick from curated Korean phrases",
                    delay: 0.1,
                    appeared: appeared
                )

                StepRow(
                    number: 2,
                    icon: "mic.fill",
                    title: "Record Your Voice",
                    description: "Speak the phrase into your microphone",
                    delay: 0.2,
                    appeared: appeared
                )

                StepRow(
                    number: 3,
                    icon: "star.fill",
                    title: "Get Instant Feedback",
                    description: "AI analyzes your pronunciation",
                    delay: 0.3,
                    appeared: appeared
                )
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }
}

private struct StepRow: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    let delay: Double
    let appeared: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.appGreenLight)
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.appGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.headline())
                    .foregroundColor(.appTextPrimary)

                Text(description)
                    .font(AppFont.caption())
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.appCardBg)
        .cornerRadius(AppRadius.md)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .offset(x: appeared ? 0 : 50)
        .opacity(appeared ? 1.0 : 0)
        .animation(.spring(response: 0.5).delay(delay), value: appeared)
    }
}

// MARK: - Microphone Page

private struct MicrophonePage: View {
    @Binding var isGranted: Bool
    @State private var appeared = false
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Microphone illustration
            ZStack {
                // Pulse effect
                Circle()
                    .fill(Color.appGreen.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .opacity(isPulsing ? 0 : 0.5)

                Circle()
                    .fill(Color.appGreenLight)
                    .frame(width: 140, height: 140)

                Image(systemName: isGranted ? "checkmark.circle.fill" : "mic.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.appGreen)
            }
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1.0 : 0)

            VStack(spacing: 12) {
                Text(isGranted ? "You're All Set!" : "Microphone Access")
                    .font(AppFont.title())
                    .foregroundColor(.appTextPrimary)

                Text(isGranted
                     ? "Your microphone is ready.\nLet's start learning Korean!"
                     : "We need microphone access to\nhear and assess your pronunciation")
                    .font(AppFont.body())
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1.0 : 0)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, AppSpacing.xl)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
            // Start pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
            // Check current permission status
            checkMicrophonePermission()
        }
    }

    private func checkMicrophonePermission() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            isGranted = true
        default:
            isGranted = false
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
