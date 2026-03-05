import Foundation

struct Story: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let titleKorean: String
    let emoji: String
    let difficulty: Difficulty
    let sentences: [StorySentence]

    enum Difficulty: String, CaseIterable, Codable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var stars: Int {
            switch self {
            case .beginner: return 1
            case .intermediate: return 2
            case .advanced: return 3
            }
        }

        var color: String {
            switch self {
            case .beginner: return "22C55E"     // Green
            case .intermediate: return "F59E0B" // Yellow
            case .advanced: return "EF4444"     // Red
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            switch value.lowercased() {
            case "beginner": self = .beginner
            case "intermediate": self = .intermediate
            case "advanced": self = .advanced
            default:
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Unknown difficulty: \(value)"
                )
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .beginner: try container.encode("beginner")
            case .intermediate: try container.encode("intermediate")
            case .advanced: try container.encode("advanced")
            }
        }
    }

    var wordCount: Int {
        sentences.reduce(0) { $0 + $1.wordCount }
    }

    var fullText: String {
        sentences.map { $0.korean }.joined(separator: " ")
    }

    var fullRomanization: String {
        sentences.map { $0.romanization }.joined(separator: " ")
    }

    var fullTranslation: String {
        sentences.map { $0.translation }.joined(separator: " ")
    }
}

struct StorySentence: Identifiable, Hashable, Codable {
    let id: Int
    let korean: String
    let romanization: String
    let translation: String

    var wordCount: Int {
        korean.split(separator: " ").count
    }
}

// MARK: - Practice Record

struct StoryPracticeRecord: Identifiable {
    let id = UUID()
    let storyId: Int
    let sentenceScores: [Int]
    let completedAt: Date

    var averageScore: Int {
        guard !sentenceScores.isEmpty else { return 0 }
        return sentenceScores.reduce(0, +) / sentenceScores.count
    }
}
