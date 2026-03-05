import Foundation
import SwiftUI

@Observable
final class AchievementService {
    private let userDefaultsKey = "unlockedAchievements"

    private(set) var unlockedAchievements: [UnlockedAchievement] = []
    var recentlyUnlocked: Achievement?
    var showUnlockAnimation = false

    init() {
        loadUnlockedAchievements()
    }

    // MARK: - Public API

    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedAchievements.contains { $0.achievementId == achievement.rawValue }
    }

    func unlockedDate(for achievement: Achievement) -> Date? {
        unlockedAchievements.first { $0.achievementId == achievement.rawValue }?.unlockedAt
    }

    func checkAndUnlock(records: [PracticeRecord]) {
        let stats = UserStats.from(records: records)
        var newlyUnlocked: [Achievement] = []

        for achievement in Achievement.allCases where !isUnlocked(achievement) {
            if shouldUnlock(achievement, stats: stats, records: records) {
                unlock(achievement)
                newlyUnlocked.append(achievement)
            }
        }

        // Show animation for highest rarity unlocked
        if let best = newlyUnlocked.max(by: { $0.rarity.ordinal < $1.rarity.ordinal }) {
            showUnlockNotification(best)
        }
    }

    func progress(for achievement: Achievement, stats: UserStats, records: [PracticeRecord]) -> Double {
        let (current, target) = progressValues(for: achievement, stats: stats, records: records)
        guard target > 0 else { return 0 }
        return min(1.0, Double(current) / Double(target))
    }

    func progressText(for achievement: Achievement, stats: UserStats, records: [PracticeRecord]) -> String {
        let (current, target) = progressValues(for: achievement, stats: stats, records: records)
        return "\(min(current, target))/\(target)"
    }

    var unlockedCount: Int {
        unlockedAchievements.count
    }

    var totalCount: Int {
        Achievement.allCases.count
    }

    // MARK: - Private Methods

    private func shouldUnlock(_ achievement: Achievement, stats: UserStats, records: [PracticeRecord]) -> Bool {
        switch achievement {
        // First Steps
        case .firstLesson:
            return stats.completedLessons >= 1
        case .firstPerfect:
            return records.contains { $0.score >= 90 }

        // Lesson Milestones
        case .tenLessons:
            return records.count >= 10
        case .twentyFiveLessons:
            return records.count >= 25
        case .fiftyLessons:
            return records.count >= 50
        case .hundredLessons:
            return records.count >= 100

        // Streak Milestones
        case .weekStreak:
            return stats.streak >= 7
        case .twoWeekStreak:
            return stats.streak >= 14
        case .monthStreak:
            return stats.streak >= 30
        case .quarterStreak:
            return stats.streak >= 90

        // XP Milestones
        case .xp100:
            return stats.totalXP >= 100
        case .xp500:
            return stats.totalXP >= 500
        case .xp1000:
            return stats.totalXP >= 1000
        case .xp5000:
            return stats.totalXP >= 5000

        // Skill Mastery
        case .unitComplete:
            return hasCompletedAnyUnit(records: records)
        case .allUnitsComplete:
            return hasCompletedAllUnits(records: records)
        case .perfectWeek:
            return hasPerfectWeek(records: records)

        // Special
        case .earlyBird:
            return hasEarlyBirdSession(records: records)
        case .nightOwl:
            return hasNightOwlSession(records: records)
        case .weekendWarrior:
            return hasWeekendWarriorStatus(records: records)
        }
    }

    private func progressValues(for achievement: Achievement, stats: UserStats, records: [PracticeRecord]) -> (current: Int, target: Int) {
        switch achievement {
        case .firstLesson:
            return (stats.completedLessons, 1)
        case .firstPerfect:
            let perfectCount = records.filter { $0.score >= 90 }.count
            return (min(perfectCount, 1), 1)
        case .tenLessons:
            return (records.count, 10)
        case .twentyFiveLessons:
            return (records.count, 25)
        case .fiftyLessons:
            return (records.count, 50)
        case .hundredLessons:
            return (records.count, 100)
        case .weekStreak:
            return (stats.streak, 7)
        case .twoWeekStreak:
            return (stats.streak, 14)
        case .monthStreak:
            return (stats.streak, 30)
        case .quarterStreak:
            return (stats.streak, 90)
        case .xp100:
            return (stats.totalXP, 100)
        case .xp500:
            return (stats.totalXP, 500)
        case .xp1000:
            return (stats.totalXP, 1000)
        case .xp5000:
            return (stats.totalXP, 5000)
        case .unitComplete:
            return (completedUnitCount(records: records), 1)
        case .allUnitsComplete:
            return (completedUnitCount(records: records), ContentLoader.units.count)
        case .perfectWeek, .earlyBird, .nightOwl, .weekendWarrior:
            // These are special achievements without linear progress
            return (isUnlocked(achievement) ? 1 : 0, 1)
        }
    }

    private func unlock(_ achievement: Achievement) {
        let record = UnlockedAchievement(
            achievementId: achievement.rawValue,
            unlockedAt: .now
        )
        unlockedAchievements.append(record)
        saveUnlockedAchievements()
    }

    private func showUnlockNotification(_ achievement: Achievement) {
        recentlyUnlocked = achievement
        withAnimation(.spring(response: 0.5)) {
            showUnlockAnimation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            withAnimation {
                self?.showUnlockAnimation = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.recentlyUnlocked = nil
            }
        }
    }

    // MARK: - Special Achievement Checks

    private func hasCompletedAnyUnit(records: [PracticeRecord]) -> Bool {
        completedUnitCount(records: records) >= 1
    }

    private func hasCompletedAllUnits(records: [PracticeRecord]) -> Bool {
        completedUnitCount(records: records) >= ContentLoader.units.count
    }

    private func completedUnitCount(records: [PracticeRecord]) -> Int {
        let completedLessonIds = Set(records.map(\.lessonId))
        return ContentLoader.units.filter { unit in
            unit.lessons.allSatisfy { lesson in
                completedLessonIds.contains(lesson.id)
            }
        }.count
    }

    private func hasPerfectWeek(records: [PracticeRecord]) -> Bool {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: .now)!
        let recentRecords = records.filter { $0.date >= oneWeekAgo }

        // Must have at least 7 records in the past week, all 90%+
        guard recentRecords.count >= 7 else { return false }
        return recentRecords.allSatisfy { $0.score >= 90 }
    }

    private func hasEarlyBirdSession(records: [PracticeRecord]) -> Bool {
        let calendar = Calendar.current
        return records.contains { record in
            let hour = calendar.component(.hour, from: record.date)
            return hour < 8
        }
    }

    private func hasNightOwlSession(records: [PracticeRecord]) -> Bool {
        let calendar = Calendar.current
        return records.contains { record in
            let hour = calendar.component(.hour, from: record.date)
            return hour >= 22
        }
    }

    private func hasWeekendWarriorStatus(records: [PracticeRecord]) -> Bool {
        let calendar = Calendar.current

        // Check last 4 weekends
        var weekendCount = 0
        for weeksAgo in 0..<4 {
            let saturdayOffset = -(calendar.component(.weekday, from: .now) - 7) - (weeksAgo * 7)
            guard let saturday = calendar.date(byAdding: .day, value: saturdayOffset, to: .now),
                  let sunday = calendar.date(byAdding: .day, value: 1, to: saturday) else {
                continue
            }

            let hasWeekendPractice = records.contains { record in
                calendar.isDate(record.date, inSameDayAs: saturday) ||
                calendar.isDate(record.date, inSameDayAs: sunday)
            }

            if hasWeekendPractice {
                weekendCount += 1
            }
        }

        return weekendCount >= 4
    }

    // MARK: - Persistence

    private func loadUnlockedAchievements() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let achievements = try? JSONDecoder().decode([UnlockedAchievement].self, from: data) else {
            return
        }
        unlockedAchievements = achievements
    }

    private func saveUnlockedAchievements() {
        guard let data = try? JSONEncoder().encode(unlockedAchievements) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
}

// MARK: - Rarity Ordinal Extension

private extension AchievementRarity {
    var ordinal: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 4
        }
    }
}
