import SwiftUI

enum PracticeMode: String, CaseIterable {
    case full = "Full"
    case sentence = "Each Sentence"
}

struct StoryPracticeView: View {
    let story: Story
    @Environment(AppState.self) private var appState
    @Environment(ErrorHandlingService.self) private var errorService
    @State private var recorder = AudioRecordingService()
    @State private var assessor = SpeechAssessmentService()
    @State private var tts = TTSService()
    @State private var practiceMode: PracticeMode = .full
    @State private var currentSentenceIndex = 0
    @State private var sentenceScores: [Int?]
    @State private var fullScore: Int?
    @State private var appeared = false

    init(story: Story) {
        self.story = story
        _sentenceScores = State(initialValue: Array(repeating: nil, count: story.sentences.count))
    }

    private var currentSentence: StorySentence {
        story.sentences[currentSentenceIndex]
    }

    private var progress: Double {
        if practiceMode == .full {
            return fullScore != nil ? 1.0 : 0.0
        }
        let completed = sentenceScores.compactMap { $0 }.count
        return Double(completed) / Double(story.sentences.count)
    }

    private var isComplete: Bool {
        if practiceMode == .full {
            return fullScore != nil
        }
        return sentenceScores.allSatisfy { $0 != nil }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Nav bar
            navBar

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Story header (compact, horizontal)
                    storyHeader
                        .popIn(isVisible: appeared, delay: 0)

                    // Mode toggle
                    modeToggle
                        .popIn(isVisible: appeared, delay: 0.03)

                    // Content based on mode
                    if practiceMode == .full {
                        // Full mode: show full text and record all at once
                        fullModePracticeSection
                            .popIn(isVisible: appeared, delay: 0.08)
                    } else {
                        // Sentence mode: show current sentence
                        currentSentenceSection
                            .popIn(isVisible: appeared, delay: 0.08)

                        // Sentence progress
                        sentenceProgressSection
                            .popIn(isVisible: appeared, delay: 0.12)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, 140)
            }

            // Record button
            recordButtonSection
        }
        .background(Color.appBg)
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation { appeared = true }
            Task {
                await tts.preload(currentSentence.korean)
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
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Spacer()

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSurface)
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.appGreen)
                        .frame(width: geo.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, AppSpacing.xl)

            Spacer()

            // Sentence counter
            Text("\(currentSentenceIndex + 1)/\(story.sentences.count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.md)
    }

    // MARK: - Story Header

    private var storyHeader: some View {
        HStack(spacing: AppSpacing.lg) {
            Text(story.emoji)
                .font(.system(size: 40))
                .frame(width: 56, height: 56)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(story.titleKorean)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text(story.title)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)

                HStack(spacing: AppSpacing.sm) {
                    HStack(spacing: 2) {
                        ForEach(0..<story.difficulty.stars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: story.difficulty.color))
                        }
                    }
                    Text("\(story.sentences.count) sentences")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.appTextMuted)
                }
            }

            Spacer()
        }
        .padding(AppSpacing.md)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            ForEach(PracticeMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(AppAnimation.spring) {
                        practiceMode = mode
                    }
                    HapticFeedback.light.play()
                } label: {
                    Text(mode.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(practiceMode == mode ? .white : Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            practiceMode == mode
                                ? Color.appGreen
                                : Color.clear
                        )
                }
            }
        }
        .background(Color.appSurface)
        .clipShape(Capsule())
    }

    // MARK: - Full Mode Practice Section

    private var fullModePracticeSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Listen to full story button
            Button {
                playFullStory()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if tts.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: tts.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(tts.isPlaying ? "Stop" : "Listen to Full Story")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(
                    LinearGradient(
                        colors: [.appBlue, .appPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(tts.isLoading)

            // Full text display
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(story.fullText)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineSpacing(8)

                Divider()

                Text(story.fullRomanization)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextMuted)
                    .italic()
                    .lineSpacing(4)

                Divider()

                Text(story.fullTranslation)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineSpacing(4)
            }
            .padding(AppSpacing.lg)
            .background(Color.appCardBg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))

            // Score display if completed
            if let score = fullScore {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.scoreColor(for: score))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Score")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appTextMuted)
                        Text("\(score)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.scoreColor(for: score))
                    }

                    Spacer()

                    Button {
                        withAnimation(AppAnimation.spring) {
                            fullScore = nil
                        }
                    } label: {
                        Text("Try Again")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.appGreen)
                            .padding(.horizontal, AppSpacing.lg)
                            .padding(.vertical, AppSpacing.sm)
                            .background(Color.appGreenLight.opacity(0.5))
                            .clipShape(Capsule())
                    }
                }
                .padding(AppSpacing.lg)
                .background(Color.scoreColor(for: score).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            }
        }
    }

    private func playFullStory() {
        if tts.isPlaying {
            tts.stop()
        } else {
            Task {
                do {
                    try await tts.speak(story.fullText)
                } catch {
                    errorService.handle(error)
                }
            }
        }
    }

    // MARK: - Current Sentence Section

    private var currentSentenceSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Listen button
            Button {
                playCurrentSentence()
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
            }
            .disabled(tts.isLoading)

            // Korean text
            Text(currentSentence.korean)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.appTextPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            // Romanization
            Text(currentSentence.romanization)
                .font(.system(size: 14))
                .foregroundStyle(Color.appTextMuted)
                .italic()
                .multilineTextAlignment(.center)

            // Translation
            Text(currentSentence.translation)
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)

            // Score badge if completed
            if let score = sentenceScores[currentSentenceIndex] {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.scoreColor(for: score))
                    Text("Score: \(score)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.scoreColor(for: score))
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.sm)
                .background(Color.scoreColor(for: score).opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(AppSpacing.xl)
        .cardStyle()
    }

    private func playCurrentSentence() {
        if tts.isPlaying {
            tts.stop()
        } else {
            Task {
                do {
                    try await tts.speak(currentSentence.korean)
                } catch {
                    errorService.handle(error)
                }
            }
        }
    }

    // MARK: - Sentence Progress

    private var sentenceProgressSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Sentences")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                Text("Tap to select")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.appTextMuted)
            }

            // Horizontal scroll for sentences
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(Array(story.sentences.enumerated()), id: \.element.id) { index, _ in
                        SentenceDot(
                            index: index,
                            score: sentenceScores[index],
                            isCurrent: index == currentSentenceIndex
                        ) {
                            withAnimation(AppAnimation.spring) {
                                currentSentenceIndex = index
                            }
                            Task {
                                await tts.preload(story.sentences[index].korean)
                            }
                        }
                    }
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
    }

    // MARK: - Record Button Section

    private var recordButtonSection: some View {
        VStack(spacing: AppSpacing.sm) {
            if assessor.isAssessing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.appGreen)
                Text("Analyzing...")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            } else if isComplete {
                completeButton
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

    private var completeButton: some View {
        Button {
            showResults()
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                Text("View Results")
            }
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.vertical, AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [.appGreen, .appGreenDark],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color.appGreen.opacity(0.3), radius: 8, x: 0, y: 4)
        }
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

        Task {
            do {
                if practiceMode == .full {
                    // Full mode: assess against full text
                    let result = try await assessor.assess(
                        audioURL: audioURL,
                        referenceText: story.fullText
                    )

                    withAnimation(AppAnimation.spring) {
                        fullScore = result.overallScore
                    }
                } else {
                    // Sentence mode: assess current sentence
                    let result = try await assessor.assess(
                        audioURL: audioURL,
                        referenceText: currentSentence.korean
                    )

                    withAnimation(AppAnimation.spring) {
                        sentenceScores[currentSentenceIndex] = result.overallScore
                    }

                    // Auto-advance to next sentence after a short delay
                    if currentSentenceIndex < story.sentences.count - 1 {
                        try? await Task.sleep(nanoseconds: 800_000_000)
                        withAnimation(AppAnimation.spring) {
                            currentSentenceIndex += 1
                        }
                        await tts.preload(story.sentences[currentSentenceIndex].korean)
                    }
                }
            } catch {
                errorService.handle(error)
            }
        }
    }

    private func showResults() {
        let finalScore: Int
        let scoreAxes: [ScoreAxis]
        let details: [FeedbackDetail]

        if practiceMode == .full {
            finalScore = fullScore ?? 0
            scoreAxes = [
                ScoreAxis(label: "Overall", koreanLabel: "종합", value: finalScore, icon: "chart.bar.fill"),
            ]
            details = generateFullModeDetails(score: finalScore)
        } else {
            let scores = sentenceScores.compactMap { $0 }
            finalScore = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
            scoreAxes = [
                ScoreAxis(label: "Average", koreanLabel: "평균", value: finalScore, icon: "chart.bar.fill"),
                ScoreAxis(label: "Best", koreanLabel: "최고", value: scores.max() ?? 0, icon: "arrow.up.circle.fill"),
                ScoreAxis(label: "Lowest", koreanLabel: "최저", value: scores.min() ?? 0, icon: "arrow.down.circle.fill"),
            ]
            details = generateStoryDetails(scores: scores)
        }

        let feedback = LessonFeedback(
            overallScore: finalScore,
            emoji: finalScore >= 90 ? "🎉" : finalScore >= 70 ? "😊" : finalScore >= 50 ? "💪" : "🔄",
            message: "You completed \"\(story.title)\"!",
            xpEarned: finalScore >= 90 ? 100 : finalScore >= 70 ? 75 : 50,
            scores: scoreAxes,
            details: details,
            recognizedText: nil,
            referenceText: story.fullText,
            words: []
        )

        // Create a dummy lesson for navigation
        let dummyLesson = Lesson(
            id: -story.id,
            unitId: 0,
            order: 0,
            emoji: story.emoji,
            title: story.title,
            korean: story.titleKorean,
            romanization: "",
            translation: story.title,
            difficulty: story.difficulty == .beginner ? .beginner : story.difficulty == .intermediate ? .intermediate : .advanced,
            hint: ""
        )

        appState.navigateToFeedback(dummyLesson, feedback)
    }

    private func generateStoryDetails(scores: [Int]) -> [FeedbackDetail] {
        var details: [FeedbackDetail] = []

        let avgScore = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count

        if avgScore >= 85 {
            details.append(FeedbackDetail(
                type: .excellent,
                message: "Excellent reading! Your pronunciation across all sentences was very consistent."
            ))
        }

        let goodSentences = scores.enumerated().filter { $0.element >= 80 }.count
        if goodSentences > 0 {
            details.append(FeedbackDetail(
                type: .good,
                message: "You scored 80+ on \(goodSentences) out of \(scores.count) sentences."
            ))
        }

        let needsWork = scores.enumerated().filter { $0.element < 70 }
        if !needsWork.isEmpty {
            let sentenceNumbers = needsWork.map { "\($0.offset + 1)" }.joined(separator: ", ")
            details.append(FeedbackDetail(
                type: .tip,
                message: "Try practicing sentences \(sentenceNumbers) again for improvement."
            ))
        }

        if details.isEmpty {
            details.append(FeedbackDetail(
                type: .good,
                message: "Good effort! Keep practicing to improve your reading fluency."
            ))
        }

        return details
    }

    private func generateFullModeDetails(score: Int) -> [FeedbackDetail] {
        var details: [FeedbackDetail] = []

        if score >= 90 {
            details.append(FeedbackDetail(
                type: .excellent,
                message: "Outstanding! You read the entire story with excellent pronunciation."
            ))
        } else if score >= 80 {
            details.append(FeedbackDetail(
                type: .excellent,
                message: "Great job reading through the full story!"
            ))
        }

        if score >= 70 {
            details.append(FeedbackDetail(
                type: .good,
                message: "Your pacing and rhythm were natural throughout the story."
            ))
        }

        if score < 80 {
            details.append(FeedbackDetail(
                type: .tip,
                message: "Try the 'Each Sentence' mode to practice difficult parts individually."
            ))
        }

        if details.isEmpty {
            details.append(FeedbackDetail(
                type: .good,
                message: "Keep practicing! Reading longer texts helps build fluency."
            ))
        }

        return details
    }
}

// MARK: - Sentence Dot

struct SentenceDot: View {
    let index: Int
    let score: Int?
    let isCurrent: Bool
    let onTap: () -> Void

    private var dotColor: Color {
        if let score = score {
            return Color.scoreColor(for: score)
        }
        return isCurrent ? .appBlue : .appSurface
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(dotColor.opacity(score != nil ? 1 : 0.5))
                    .frame(width: 44, height: 44)

                if let score = score {
                    Text("\(score)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                } else {
                    Text("\(index + 1)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(isCurrent ? .white : Color.appTextMuted)
                }
            }
            .overlay(
                Circle()
                    .strokeBorder(isCurrent ? Color.appBlue : .clear, lineWidth: 2.5)
                    .frame(width: 50, height: 50)
            )
        }
        .buttonStyle(.plain)
    }
}
