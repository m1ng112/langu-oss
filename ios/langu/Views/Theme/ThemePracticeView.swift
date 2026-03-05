import SwiftUI

struct ThemePracticeView: View {
    let theme: Theme
    @Environment(AppState.self) private var appState
    @Environment(ErrorHandlingService.self) private var errorService
    @Environment(\.modelContext) private var modelContext
    @State private var recorder = AudioRecordingService()
    @State private var assessor = SpeechAssessmentService()
    @State private var evaluator = ThemeEvaluationService()
    @State private var appeared = false
    @State private var showExamples = false

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            navBar

            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    // Theme info
                    themeInfoSection
                        .popIn(isVisible: appeared, delay: 0)

                    // Instructions
                    instructionSection
                        .popIn(isVisible: appeared, delay: 0.05)

                    // Example sentences
                    examplesSection
                        .popIn(isVisible: appeared, delay: 0.1)

                    // Keywords
                    keywordsSection
                        .popIn(isVisible: appeared, delay: 0.15)

                    // Waveform + Timer
                    recordingSection
                        .popIn(isVisible: appeared, delay: 0.2)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.xxl)
                .padding(.bottom, 120)
            }

            // Record button
            recordButtonSection
        }
        .background(Color.appBg)
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation { appeared = true }
        }
        .onDisappear {
            recorder.cleanup()
        }
    }

    // MARK: - Nav Bar

    private var navBar: some View {
        HStack {
            Button {
                appState.navigateHome()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Spacer()

            Text("Free Talk")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)

            Spacer()

            // XP badge
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appYellow)
                Text("+40")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(Color.appYellowLight)
            .clipShape(Capsule())
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Theme Info

    private var themeInfoSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text(theme.emoji)
                .font(.system(size: 48))

            Text(theme.koreanName)
                .font(AppFont.koreanPrompt())
                .foregroundStyle(Color.appTextPrimary)

            Text(theme.name)
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)

            Text("Speak freely")
                .font(AppFont.caption())
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.appPurple)
                .clipShape(Capsule())
        }
    }

    // MARK: - Instructions

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appBlue)
                Text("What to do")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Text(theme.description)
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)

            Text("Speak for at least \(theme.minDurationSeconds) seconds")
                .font(AppFont.caption())
                .foregroundStyle(Color.appTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color.appBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .strokeBorder(Color.appBlue.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Examples

    private var examplesSection: some View {
        VStack {
            Button {
                withAnimation(AppAnimation.spring) { showExamples.toggle() }
            } label: {
                HStack {
                    Text("💡")
                    Text("Example Sentences")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.appYellow)
                    Spacer()
                    Image(systemName: showExamples ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appYellow)
                }
            }

            if showExamples {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(theme.exampleSentences, id: \.self) { sentence in
                        HStack(spacing: AppSpacing.sm) {
                            Circle()
                                .fill(Color.appYellow)
                                .frame(width: 6, height: 6)
                            Text(sentence)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.appTextPrimary)
                        }
                    }
                }
                .padding(.top, AppSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appYellowLight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    // MARK: - Keywords

    private var keywordsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appPurple)
                Text("Key Vocabulary")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }

            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(theme.keywords, id: \.self) { keyword in
                    Text(keyword)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.appPurple)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.appPurple.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.appPurple.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
    }

    // MARK: - Recording Section

    private var recordingSection: some View {
        VStack(spacing: AppSpacing.lg) {
            WaveformView(
                isRecording: recorder.isRecording,
                audioLevels: recorder.audioLevels
            )
            .padding(.horizontal, AppSpacing.sm)

            HStack(spacing: AppSpacing.lg) {
                Text(statusText)
                    .font(AppFont.timer())
                    .foregroundStyle(recorder.isRecording ? Color.appTextPrimary : Color.appTextMuted)

                if recorder.canPlayback && !recorder.isRecording {
                    Button {
                        recorder.togglePlayback()
                        HapticFeedback.light.play()
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: recorder.isPlaying ? "stop.fill" : "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text(recorder.isPlaying ? "Stop" : "Play")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.appGreen)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.appGreenLight.opacity(0.5))
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(AppSpacing.xl)
        .cardStyle()
    }

    private var statusText: String {
        if recorder.isRecording {
            return recorder.formattedTime
        } else if recorder.isPlaying {
            return recorder.formattedPlaybackTime
        } else if recorder.canPlayback {
            return "Ready to submit"
        } else {
            return "Tap to record"
        }
    }

    // MARK: - Record Button

    private var recordButtonSection: some View {
        VStack(spacing: AppSpacing.sm) {
            if assessor.isAssessing || evaluator.isEvaluating {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.appPurple)
                Text(assessor.isAssessing ? "Recognizing speech..." : "Evaluating response...")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            } else {
                RecordButton(isRecording: recorder.isRecording) {
                    handleRecordTap()
                }
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(Color.appCardBg.shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: -4))
    }

    // MARK: - Actions

    private func handleRecordTap() {
        if recorder.isRecording {
            stopAndEvaluate()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        Task {
            let granted = await recorder.requestPermission()
            guard granted else {
                errorService.handle(AppError.audio(.permissionDenied))
                return
            }
            do {
                try recorder.startRecording()
            } catch {
                errorService.handle(AppError.audio(.recordingFailed))
            }
        }
    }

    private func stopAndEvaluate() {
        guard let audioURL = recorder.stopRecording() else { return }
        performEvaluation(audioURL: audioURL)
    }

    private func performEvaluation(audioURL: URL) {
        Task {
            do {
                // Step 1: Speech recognition (get recognizedText via existing assess endpoint)
                let assessResult = try await assessor.assess(audioURL: audioURL, referenceText: "")

                guard let recognizedText = assessResult.recognizedText,
                      !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    errorService.handle(SpeechAssessmentService.AssessmentError.noSpeechDetected)
                    return
                }

                // Step 2: Theme evaluation via LLM (Haiku)
                let evaluation = try await evaluator.evaluate(recognizedText: recognizedText, theme: theme)

                // Save practice record
                let record = PracticeRecord(
                    lessonId: 1000 + (ContentLoader.themes.firstIndex(where: { $0.id == theme.id }) ?? 0),
                    score: evaluation.overallScore,
                    xpEarned: evaluation.xpEarned
                )
                modelContext.insert(record)

                appState.navigateToThemeFeedback(theme, evaluation)
            } catch {
                errorService.handle(error)
            }
        }
    }
}
