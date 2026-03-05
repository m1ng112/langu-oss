import Foundation

struct ScoreAxis: Identifiable {
    let id = UUID()
    let label: String
    let koreanLabel: String
    let value: Int
    let icon: String
}

struct FeedbackDetail: Identifiable {
    let id = UUID()
    let type: DetailType
    let message: String

    enum DetailType: String {
        case excellent
        case good
        case tip

        var emoji: String {
            switch self {
            case .excellent: return "🌟"
            case .good: return "👍"
            case .tip: return "💡"
            }
        }

        var title: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .tip: return "Tip"
            }
        }

        var bgColorHex: String {
            switch self {
            case .excellent: return "DCFCE7"
            case .good: return "DBEAFE"
            case .tip: return "FEF3C7"
            }
        }

        var borderColorHex: String {
            switch self {
            case .excellent: return "22C55E"
            case .good: return "3B82F6"
            case .tip: return "F59E0B"
            }
        }
    }
}

struct WordFeedback: Identifiable {
    let id = UUID()
    let word: String
    let accuracyScore: Int
    let errorType: ErrorType

    enum ErrorType: String {
        case none
        case mispronunciation
        case omission
        case insertion
    }

    var isGood: Bool { accuracyScore >= 80 && errorType == .none }
    var needsWork: Bool { accuracyScore < 60 || errorType != .none }
}

struct LessonFeedback: Identifiable {
    let id = UUID()
    let overallScore: Int
    let emoji: String
    let message: String
    let xpEarned: Int
    let scores: [ScoreAxis]
    let details: [FeedbackDetail]
    let recognizedText: String?
    let referenceText: String
    let words: [WordFeedback]

    var starCount: Int {
        switch overallScore {
        case 90...100: return 3
        case 70..<90: return 2
        case 50..<70: return 1
        default: return 0
        }
    }

    /// Whether the recognized text matches the reference (case-insensitive, trimmed)
    var isExactMatch: Bool {
        guard let recognized = recognizedText else { return false }
        return recognized.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == referenceText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// Words that need improvement
    var wordsNeedingWork: [WordFeedback] {
        words.filter { $0.needsWork }
    }
}
