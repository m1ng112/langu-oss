import Foundation

struct Lesson: Identifiable, Hashable, Codable {
    let id: Int
    let unitId: Int
    let order: Int
    let emoji: String
    let title: String
    let korean: String
    let romanization: String
    let translation: String
    let difficulty: Difficulty
    let hint: String

    enum Difficulty: String, CaseIterable, Codable {
        case beginner = "초급"
        case intermediate = "중급"
        case advanced = "고급"

        var color: String {
            switch self {
            case .beginner: return "22C55E"
            case .intermediate: return "F59E0B"
            case .advanced: return "EF4444"
            }
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            switch value {
            case "beginner", "초급": self = .beginner
            case "intermediate", "중급": self = .intermediate
            case "advanced", "고급": self = .advanced
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
}

struct LessonUnit: Identifiable, Hashable, Codable {
    let id: Int
    let emoji: String
    let title: String
    let description: String
    let difficulty: Lesson.Difficulty
    let lessons: [Lesson]

    var lessonCount: Int {
        lessons.count
    }
}
