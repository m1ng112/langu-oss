import Foundation

enum MockData {
    static func mockFeedback(for lesson: Lesson, score: Int = 85) -> LessonFeedback {
        let emoji: String
        let message: String
        let xp: Int

        switch score {
        case 90...100:
            emoji = "🎉"
            message = "Outstanding pronunciation!"
            xp = 50
        case 70..<90:
            emoji = "😊"
            message = "Great effort! Keep practicing."
            xp = 35
        case 50..<70:
            emoji = "💪"
            message = "Good start! Try again for a better score."
            xp = 20
        default:
            emoji = "🔄"
            message = "Keep trying, you'll get there!"
            xp = 10
        }

        return LessonFeedback(
            overallScore: score,
            emoji: emoji,
            message: message,
            xpEarned: xp,
            scores: [
                ScoreAxis(label: "Pronunciation", koreanLabel: "발음", value: min(100, score + 5), icon: "mic.fill"),
                ScoreAxis(label: "Accuracy", koreanLabel: "정확도", value: score, icon: "target"),
                ScoreAxis(label: "Fluency", koreanLabel: "유창성", value: max(0, score - 8), icon: "waveform.path"),
                ScoreAxis(label: "Prosody", koreanLabel: "억양", value: max(0, score - 12), icon: "music.note"),
                ScoreAxis(label: "Completeness", koreanLabel: "완성도", value: min(100, score + 3), icon: "checkmark.circle.fill"),
            ],
            details: [
                FeedbackDetail(type: .excellent, message: "Your vowel sounds in '\(lesson.korean)' are very clear."),
                FeedbackDetail(type: .good, message: "Good rhythm overall. The spacing between syllables is natural."),
                FeedbackDetail(type: .tip, message: "Try to soften the consonant transitions for a more native sound."),
            ],
            recognizedText: lesson.korean,
            referenceText: lesson.korean,
            words: lesson.korean.split(separator: " ").isEmpty
                ? [WordFeedback(word: lesson.korean, accuracyScore: score, errorType: .none)]
                : lesson.korean.split(separator: " ").map { word in
                    WordFeedback(word: String(word), accuracyScore: max(50, score + Int.random(in: -15...10)), errorType: .none)
                }
        )
    }
}
