import SwiftUI

struct LessonView: View {
    let lesson: Lesson
    @Environment(AppState.self) private var appState
    @Environment(ErrorHandlingService.self) private var errorService
    @Environment(\.modelContext) private var modelContext
    @State private var recorder = AudioRecordingService()
    @State private var assessor = SpeechAssessmentService()
    @State private var tts = TTSService()
    @State private var showRomanization = true
    @State private var showHint = false
    @State private var appeared = false

    // Progress tracking
    private let currentStep = 1
    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            navBar

            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    // Emoji & Instruction
                    emojiSection
                        .popIn(isVisible: appeared, delay: 0)

                    // Korean prompt
                    promptSection
                        .popIn(isVisible: appeared, delay: 0.05)

                    // Hint
                    hintSection
                        .popIn(isVisible: appeared, delay: 0.1)

                    // Waveform + Timer
                    recordingSection
                        .popIn(isVisible: appeared, delay: 0.15)
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
            // Preload reference audio
            Task {
                await tts.preload(lesson.korean)
            }
        }
        .onDisappear {
            tts.stop()
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

            // Progress dots
            HStack(spacing: AppSpacing.sm) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step < currentStep ? Color.appGreen : Color.appSurface)
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            // XP badge
            HStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appYellow)
                Text("+35")
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

    // MARK: - Emoji Section

    private var emojiSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text(lesson.emoji)
                .font(.system(size: 48))

            Text("Listen and repeat")
                .font(AppFont.caption())
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(Color.appGreen)
                .clipShape(Capsule())
        }
    }

    // MARK: - Prompt

    private var promptSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Listen button
            Button {
                playReferenceAudio()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if tts.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: tts.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .symbolEffect(.variableColor, isActive: tts.isPlaying)
                    }
                    Text(tts.isPlaying ? "Playing..." : "Listen")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    LinearGradient(
                        colors: [.appBlue, .appPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.appBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(tts.isLoading)

            Text(lesson.korean)
                .font(AppFont.koreanPrompt())
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)

            if showRomanization {
                Text(lesson.romanization)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appTextMuted)
                    .italic()
            }

            Button {
                withAnimation { showRomanization.toggle() }
            } label: {
                Text(showRomanization ? "Hide romanization" : "Show romanization")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appGreen)
            }

            Text(lesson.translation)
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private func playReferenceAudio() {
        if tts.isPlaying {
            tts.stop()
        } else {
            Task {
                do {
                    try await tts.speak(lesson.korean)
                } catch {
                    errorService.handle(error)
                }
            }
        }
    }

    // MARK: - Hint

    private var hintSection: some View {
        VStack {
            Button {
                withAnimation(AppAnimation.spring) { showHint.toggle() }
            } label: {
                HStack {
                    Text("💡")
                    Text("Pronunciation Hint")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.appYellow)
                    Spacer()
                    Image(systemName: showHint ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appYellow)
                }
            }

            if showHint {
                Text(lesson.hint)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.top, AppSpacing.sm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appYellowLight)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
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
                // Status text
                Text(statusText)
                    .font(AppFont.timer())
                    .foregroundStyle(recorder.isRecording ? Color.appTextPrimary : Color.appTextMuted)

                // Playback button (only show after recording)
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
            if assessor.isAssessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.appGreen)
                Text("Analyzing...")
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
            stopAndAssess()
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

    private func stopAndAssess() {
        guard let audioURL = recorder.stopRecording() else { return }
        performAssessment(audioURL: audioURL)
    }

    private func performAssessment(audioURL: URL) {
        Task {
            do {
                let result = try await assessor.assess(audioURL: audioURL, referenceText: lesson.korean)
                let feedback = assessor.buildFeedback(from: result, lesson: lesson)

                // Save practice record
                let record = PracticeRecord(
                    lessonId: lesson.id,
                    score: feedback.overallScore,
                    xpEarned: feedback.xpEarned
                )
                modelContext.insert(record)

                appState.navigateToFeedback(lesson, feedback)
            } catch {
                errorService.handle(error)
            }
        }
    }
}
