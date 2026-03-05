import SwiftUI

struct FeedbackView: View {
    let lesson: Lesson
    let feedback: LessonFeedback
    @Environment(AppState.self) private var appState
    @State private var appeared = false
    @State private var animatedScore = 0
    @State private var showStars = false
    @State private var starRotation: Double = 0
    @State private var barProgress: [CGFloat] = [0, 0, 0, 0, 0]

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Score Card
                scoreCard
                    .popIn(isVisible: appeared, delay: 0)

                // Recognition Comparison
                if feedback.recognizedText != nil {
                    recognitionComparisonCard
                        .popIn(isVisible: appeared, delay: 0.05)
                }

                // Word-level Feedback
                if !feedback.words.isEmpty {
                    wordLevelFeedbackCard
                        .popIn(isVisible: appeared, delay: 0.08)
                }

                // Detailed Scores
                detailedScoresCard
                    .popIn(isVisible: appeared, delay: 0.1)

                // Feedback Details
                feedbackDetailsSection
                    .popIn(isVisible: appeared, delay: 0.2)

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
            // Emoji - larger with shadow
            Text(feedback.emoji)
                .font(.system(size: 64))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Stars - larger
            HStack(spacing: AppSpacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < feedback.starCount ? "star.fill" : "star")
                        .font(.system(size: 32))
                        .foregroundStyle(index < feedback.starCount ? Color.appYellow : Color.appSurface)
                        .shadow(
                            color: index < feedback.starCount ? Color.appYellow.opacity(0.4) : .clear,
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                        .rotationEffect(.degrees(showStars && index < feedback.starCount ? starRotation : 0))
                        .scaleEffect(showStars && index < feedback.starCount ? 1 : 0.3)
                        .animation(
                            AppAnimation.springBouncy.delay(Double(index) * 0.15),
                            value: showStars
                        )
                }
            }

            // Animated Score - in colored circle
            ZStack {
                Circle()
                    .fill(Color.scoreColor(for: feedback.overallScore).opacity(0.12))
                    .frame(width: 100, height: 100)

                Text("\(animatedScore)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.scoreColor(for: feedback.overallScore))
            }

            // Message
            Text(feedback.message)
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)

            // XP Badge - larger pill
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appYellow)
                Text("+\(feedback.xpEarned) XP")
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

    // MARK: - Recognition Comparison

    private var recognitionComparisonCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: feedback.isExactMatch ? "checkmark.circle.fill" : "waveform.badge.magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(feedback.isExactMatch ? Color.appGreen : Color.appBlue)
                Text("Speech Recognition")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }

            VStack(spacing: AppSpacing.sm) {
                // Reference text
                HStack(spacing: AppSpacing.sm) {
                    Text("Target")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextMuted)
                        .frame(width: 50, alignment: .leading)
                    Text(feedback.referenceText)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color.appTextPrimary)
                    Spacer()
                }

                // Recognized text
                HStack(spacing: AppSpacing.sm) {
                    Text("Yours")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextMuted)
                        .frame(width: 50, alignment: .leading)
                    Text(feedback.recognizedText ?? "-")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(feedback.isExactMatch ? Color.appGreen : Color.appOrange)
                    Spacer()
                    if feedback.isExactMatch {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.appGreen)
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(Color.appSurface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
    }

    // MARK: - Word-level Feedback

    private var wordLevelFeedbackCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "text.word.spacing")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appPurple)
                Text("Word-by-Word")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
            }

            // Word chips in a flow layout
            FlowLayout(spacing: AppSpacing.sm) {
                ForEach(feedback.words) { word in
                    WordChip(word: word)
                }
            }

            // Legend
            HStack(spacing: AppSpacing.lg) {
                LegendItem(color: .appGreen, label: "Good")
                LegendItem(color: .appYellow, label: "OK")
                LegendItem(color: .appRed, label: "Needs work")
            }
            .padding(.top, AppSpacing.xs)
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

            ForEach(Array(feedback.scores.enumerated()), id: \.element.id) { index, score in
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

    // MARK: - Feedback Details

    private var feedbackDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Feedback")
                .font(AppFont.headline())
                .foregroundStyle(Color.appTextPrimary)

            ForEach(Array(feedback.details.enumerated()), id: \.element.id) { index, detail in
                FeedbackDetailCard(detail: detail)
                    .popIn(isVisible: appeared, delay: 0.25 + Double(index) * 0.05)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                HapticFeedback.light.play()
                appState.navigateHome()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.navigateToLesson(lesson)
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Retry")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(Color.appGreenLight.opacity(0.5))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.appGreen.opacity(0.3), lineWidth: 2))
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
                        colors: [.appGreen, .appGreenDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.appGreen.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PillButtonStyle())
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Score count-up
        let target = feedback.overallScore
        let duration = 1.2
        let steps = 30
        let interval = duration / Double(steps)

        for step in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * interval) {
                let progress = Double(step) / Double(steps)
                // Ease-out curve
                let eased = 1 - pow(1 - progress, 3)
                animatedScore = Int(eased * Double(target))
            }
        }

        // Stars
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showStars = true
        }

        // Star rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false).delay(0.5)) {
            starRotation = 360
        }

        // Score bars
        for i in 0..<feedback.scores.count {
            let targetValue = CGFloat(feedback.scores[i].value) / 100.0
            withAnimation(.easeOut(duration: 0.8).delay(0.3 + Double(i) * 0.1)) {
                if i < barProgress.count {
                    barProgress[i] = targetValue
                }
            }
        }
    }
}

// MARK: - Score Bar Row

struct ScoreBarRow: View {
    let score: ScoreAxis
    let progress: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                // Icon in colored circle
                ZStack {
                    Circle()
                        .fill(Color.scoreColor(for: score.value).opacity(0.15))
                        .frame(width: 28, height: 28)

                    Image(systemName: score.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.scoreColor(for: score.value))
                }

                Text(score.label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appTextPrimary)

                Text(score.koreanLabel)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextMuted)

                Spacer()

                Text("\(score.value)")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.scoreColor(for: score.value))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSurface)
                        .frame(height: 10)

                    Capsule()
                        .fill(Color.scoreColor(for: score.value))
                        .frame(width: max(10, geo.size.width * progress), height: 10)
                }
            }
            .frame(height: 10)
        }
    }
}

// MARK: - Feedback Detail Card

struct FeedbackDetailCard: View {
    let detail: FeedbackDetail

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.lg) {
            // Emoji in colored circle
            ZStack {
                Circle()
                    .fill(Color(hex: detail.type.bgColorHex))
                    .frame(width: 40, height: 40)

                Text(detail.type.emoji)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(detail.type.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: detail.type.borderColorHex))

                Text(detail.message)
                    .font(AppFont.body())
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.lg)
        .background(Color(hex: detail.type.bgColorHex).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .strokeBorder(Color(hex: detail.type.borderColorHex).opacity(0.2), lineWidth: 1.5)
        )
    }
}

// MARK: - Word Chip

struct WordChip: View {
    let word: WordFeedback

    private var chipColor: Color {
        if word.errorType != .none {
            return .appRed
        } else if word.accuracyScore >= 80 {
            return .appGreen
        } else if word.accuracyScore >= 60 {
            return .appYellow
        } else {
            return .appRed
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(word.word)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(chipColor)

            if word.errorType == .none {
                Text("\(word.accuracyScore)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(chipColor.opacity(0.8))
            } else {
                Image(systemName: errorIcon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(chipColor)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(chipColor.opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(chipColor.opacity(0.3), lineWidth: 1)
        )
    }

    private var errorIcon: String {
        switch word.errorType {
        case .none: return "checkmark"
        case .mispronunciation: return "exclamationmark.triangle.fill"
        case .omission: return "minus.circle.fill"
        case .insertion: return "plus.circle.fill"
        }
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.appTextMuted)
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> ArrangementResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        let totalHeight = currentY + lineHeight
        return ArrangementResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }

    private struct ArrangementResult {
        let size: CGSize
        let positions: [CGPoint]
        let sizes: [CGSize]
    }
}
