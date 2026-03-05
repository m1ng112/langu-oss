import Foundation
import SwiftData

@Model
final class PracticeRecord {
    var lessonId: Int
    var score: Int
    var xpEarned: Int
    var date: Date

    init(lessonId: Int, score: Int, xpEarned: Int, date: Date = .now) {
        self.lessonId = lessonId
        self.score = score
        self.xpEarned = xpEarned
        self.date = date
    }
}

struct UserStats {
    var totalXP: Int
    var streak: Int
    var completedLessons: Int
    var averageScore: Int

    static let initial = UserStats(totalXP: 0, streak: 0, completedLessons: 0, averageScore: 0)

    static func from(records: [PracticeRecord]) -> UserStats {
        guard !records.isEmpty else { return .initial }

        let totalXP = records.reduce(0) { $0 + $1.xpEarned }
        let uniqueLessons = Set(records.map(\.lessonId)).count
        let avgScore = records.reduce(0) { $0 + $1.score } / records.count
        let streak = calculateStreak(from: records)

        return UserStats(
            totalXP: totalXP,
            streak: streak,
            completedLessons: uniqueLessons,
            averageScore: avgScore
        )
    }

    private static func calculateStreak(from records: [PracticeRecord]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let practiceDays = Set(records.map { calendar.startOfDay(for: $0.date) }).sorted(by: >)

        guard let lastDay = practiceDays.first,
              calendar.isDate(lastDay, inSameDayAs: today) || calendar.isDate(lastDay, inSameDayAs: today.addingTimeInterval(-86400))
        else { return 0 }

        var streak = 1
        for i in 1..<practiceDays.count {
            let diff = calendar.dateComponents([.day], from: practiceDays[i], to: practiceDays[i - 1]).day ?? 0
            if diff == 1 {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}
