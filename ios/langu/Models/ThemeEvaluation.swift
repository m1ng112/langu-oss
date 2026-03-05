import Foundation

struct ThemeEvaluation: Identifiable {
    let id = UUID()
    let themeId: String
    let recognizedText: String
    let overallScore: Int
    let relevanceScore: Int
    let vocabularyScore: Int
    let grammarScore: Int
    let expressionScore: Int
    let feedback: String
    let details: [FeedbackDetail]
    let usedKeywords: [String]
    let suggestedVocabulary: [String]
    let xpEarned: Int

    var starCount: Int {
        switch overallScore {
        case 90...100: return 3
        case 70..<90: return 2
        case 50..<70: return 1
        default: return 0
        }
    }

    var emoji: String {
        switch overallScore {
        case 90...100: return "🎉"
        case 70..<90: return "😊"
        case 50..<70: return "💪"
        default: return "🔄"
        }
    }

    var scores: [ScoreAxis] {
        [
            ScoreAxis(label: "Relevance", koreanLabel: "관련성", value: relevanceScore, icon: "target"),
            ScoreAxis(label: "Vocabulary", koreanLabel: "어휘", value: vocabularyScore, icon: "text.book.closed.fill"),
            ScoreAxis(label: "Grammar", koreanLabel: "문법", value: grammarScore, icon: "checkmark.seal.fill"),
            ScoreAxis(label: "Expression", koreanLabel: "표현", value: expressionScore, icon: "sparkles"),
        ]
    }
}

// Make ThemeEvaluation Hashable for navigation
extension ThemeEvaluation: Hashable {
    static func == (lhs: ThemeEvaluation, rhs: ThemeEvaluation) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
