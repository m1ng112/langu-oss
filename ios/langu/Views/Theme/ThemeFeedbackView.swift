import SwiftUI

struct ThemeFeedbackView: View {
    let theme: Theme
    let evaluation: ThemeEvaluation
    @Environment(AppState.self) private var appState
    @State private var appeared = false
    @State private var animatedScore = 0
    @State private var showStars = false
    @State private var starRotation: Double = 0
    @State private var barProgress: [CGFloat] = [0, 0, 0, 0]

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Score Card
                scoreCard
                    .popIn(isVisible: appeared, delay: 0)

                // Recognized Text
                recognizedTextCard
                    .popIn(isVisible: appeared, delay: 0.05)

                // Keywords Used
                keywordsCard
                    .popIn(isVisible: appeared, delay: 0.08)

                // Detailed Scores
                detailedScoresCard
                    .popIn(isVisible: appeared, delay: 0.1)

                // AI Feedback
                if !evaluation.feedback.isEmpty {
                    aiFeedbackCard
                        .popIn(isVisible: appeared, delay: 0.15)
                }

                // Feedback Details
                feedbackDetailsSection
                    .popIn(isVisible: appeared, delay: 0.2)

                // Suggested Vocabulary
                if !evaluation.suggestedVocabulary.isEmpty {
                    suggestedVocabCard
                        .popIn(isVisible: appeared, delay: 0.25)
                }

                // Action Buttons
                actionButtons
                    .popIn(isVisible: appeared, delay: 0.3)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.xxl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.appBg)
        .navigationBarBackButtonHidden()
        .onAppear {
            withAnimation { appeared = true }
            startAnimations()
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: AppSpacing.lg) {
            Text(evaluation.emoji)
                .font(.system(size: 64))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            HStack(spacing: AppSpacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < evaluation.starCount ? "star.fill" : "star")
                        .font(.system(size: 32))
                        .foregroundStyle(index < evaluation.starCount ? Color.appYellow : Color.appSurface)
                        .shadow(
                            color: index < evaluation.starCount ? Color.appYellow.opacity(0.4) : .clear,
                            radius: 6, x: 0, y: 3
                        )
                        .rotationEffect(.degrees(showStars && index < evaluation.starCount ? starRotation : 0))
                        .scaleEffect(showStars && index < evaluation.starCount ? 1 : 0.3)
                        .animation(
                            AppAnimation.springBouncy.delay(Double(index) * 0.15),
                            value: showStars
                        )
                }
            }

            ZStack {
                Circle()
                    .fill(Color.scoreColor(for: evaluation.overallScore).opacity(0.12))
                    .frame(width: 100, height: 100)

                Text("\(animatedScore)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.scoreColor(for: evaluation.overallScore))
            }

            Text(theme.koreanName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.appTextPrimary)

            Text("Free Talk Evaluation")
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appYellow)
                Text("+\(evaluation.xpEarned) XP")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appYellow)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(Color.appYellowLight)
            .clipShape(Capsule())
            .shadow(color: Color.appYellow.opacity(0.2), radius: 6, x: 0, y: 3)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxl)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous))
        .shadow(color: AppShadow.md.color, radius: AppShadow.md.radius, x: AppShadow.md.x, y: AppShadow.md.y)
    }

    // MARK: - Recognized Text

    private var recognizedTextCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appBlue)
                Text("What You Said")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Text(evaluation.recognizedText)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.appTextPrimary)
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSurface.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
    }

    // MARK: - Keywords

    private var keywordsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appPurple)
                Text("Keywords Used")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                Text("\(evaluation.usedKeywords.count)/\(theme.keywords.count)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPurple)
            }

            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(theme.keywords, id: \.self) { keyword in
                    let isUsed = evaluation.usedKeywords.contains(keyword)
                    HStack(spacing: 4) {
                        Text(keyword)
                            .font(.system(size: 15, weight: .medium))
                        if isUsed {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                        }
                    }
                    .foregroundStyle(isUsed ? Color.appGreen : Color.appTextMuted)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(isUsed ? Color.appGreen.opacity(0.1) : Color.appSurface.opacity(0.5))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(isUsed ? Color.appGreen.opacity(0.3) : Color.appSurface, lineWidth: 1)
                    )
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
    }

    // MARK: - Detailed Scores

    private var detailedScoresCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Detailed Scores")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            ForEach(Array(evaluation.scores.enumerated()), id: \.element.id) { index, score in
                ScoreBarRow(
                    score: score,
                    progress: index < barProgress.count ? barProgress[index] : 0
                )
            }
        }
        .padding(AppSpacing.xl)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
    }

    // MARK: - AI Feedback

    private var aiFeedbackCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appPurple)
                Text("AI Feedback")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Text(evaluation.feedback)
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(
                colors: [Color.appPurple.opacity(0.06), Color.appBlue.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.appPurple.opacity(0.2), Color.appBlue.opacity(0.2)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Feedback Details

    private var feedbackDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Tips")
                .font(AppFont.headline())
                .foregroundStyle(Color.appTextPrimary)

            ForEach(Array(evaluation.details.enumerated()), id: \.element.id) { index, detail in
                FeedbackDetailCard(detail: detail)
                    .popIn(isVisible: appeared, delay: 0.25 + Double(index) * 0.05)
            }
        }
    }

    // MARK: - Suggested Vocabulary

    private var suggestedVocabCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appYellow)
                Text("Try Using These Next Time")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }

            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(evaluation.suggestedVocabulary, id: \.self) { word in
                    Text(word)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.appOrange)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(Color.appOrange.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.appOrange.opacity(0.3), lineWidth: 1)
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                HapticFeedback.light.play()
                appState.navigateHome()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.navigateToThemePractice(theme)
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Retry")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appPurple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(Color.appPurple.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.appPurple.opacity(0.3), lineWidth: 2))
            }
            .buttonStyle(SecondaryPillButtonStyle())

            Button {
                HapticFeedback.medium.play()
                appState.navigateHome()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Text("Done")
                    Image(systemName: "checkmark")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(
                    LinearGradient(
                        colors: [.appPurple, .appBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.appPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PillButtonStyle())
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        let target = evaluation.overallScore
        let duration = 1.2
        let steps = 30
        let interval = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * interval) {
                let progress = Double(step) / Double(steps)
                let eased = 1 - pow(1 - progress, 3)
                animatedScore = Int(eased * Double(target))
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showStars = true
        }

        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false).delay(0.5)) {
            starRotation = 360
        }

        for i in 0..<evaluation.scores.count {
            let targetValue = CGFloat(evaluation.scores[i].value) / 100.0
            withAnimation(.easeOut(duration: 0.8).delay(0.3 + Double(i) * 0.1)) {
                if i < barProgress.count {
                    barProgress[i] = targetValue
                }
            }
        }
    }
}
