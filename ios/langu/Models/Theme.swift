import Foundation

struct Theme: Identifiable, Hashable, Codable {
    let id: String
    let emoji: String
    let name: String
    let koreanName: String
    let description: String
    let keywords: [String]
    let difficulty: Lesson.Difficulty
    let minDurationSeconds: Int
    let exampleSentences: [String]
}
