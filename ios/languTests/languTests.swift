//
//  languTests.swift
//  languTests
//
//  Created by Y on 2026/02/19.
//

import Testing
import Foundation
@testable import langu

// MARK: - Lesson Model Tests

@Suite("Lesson Model")
struct LessonModelTests {

    @Test("Lesson difficulty color mapping")
    func lessonDifficultyColors() {
        #expect(Lesson.Difficulty.beginner.color == "22C55E")
        #expect(Lesson.Difficulty.intermediate.color == "F59E0B")
        #expect(Lesson.Difficulty.advanced.color == "EF4444")
    }

    @Test("LessonUnit contains correct lessons")
    func unitLessonsFiltering() {
        let unit1 = ContentLoader.units.first { $0.id == 1 }!
        let lessons = unit1.lessons

        #expect(lessons.allSatisfy { $0.unitId == 1 })
        #expect(lessons.count == unit1.lessonCount)
    }

    @Test("Lessons are sorted by order within unit")
    func lessonsAreSortedByOrder() {
        for unit in ContentLoader.units {
            let lessons = unit.lessons
            for i in 1..<lessons.count {
                #expect(lessons[i].order > lessons[i - 1].order)
            }
        }
    }
}

// MARK: - UserStats Tests

@Suite("User Statistics")
struct UserStatsTests {

    @Test("Empty records return initial stats")
    func emptyRecordsReturnInitial() {
        let stats = UserStats.from(records: [])

        #expect(stats.totalXP == 0)
        #expect(stats.streak == 0)
        #expect(stats.completedLessons == 0)
        #expect(stats.averageScore == 0)
    }

    @Test("Single record calculates correctly")
    func singleRecordStats() {
        let record = PracticeRecord(lessonId: 1, score: 85, xpEarned: 35)
        let stats = UserStats.from(records: [record])

        #expect(stats.totalXP == 35)
        #expect(stats.completedLessons == 1)
        #expect(stats.averageScore == 85)
    }

    @Test("Multiple records accumulate XP")
    func multipleRecordsAccumulateXP() {
        let records = [
            PracticeRecord(lessonId: 1, score: 80, xpEarned: 30),
            PracticeRecord(lessonId: 2, score: 90, xpEarned: 50),
            PracticeRecord(lessonId: 3, score: 70, xpEarned: 20)
        ]
        let stats = UserStats.from(records: records)

        #expect(stats.totalXP == 100)
        #expect(stats.completedLessons == 3)
        #expect(stats.averageScore == 80)
    }

    @Test("Same lesson repeated counts unique lessons")
    func uniqueLessonCounting() {
        let records = [
            PracticeRecord(lessonId: 1, score: 70, xpEarned: 20),
            PracticeRecord(lessonId: 1, score: 85, xpEarned: 35),
            PracticeRecord(lessonId: 1, score: 95, xpEarned: 50)
        ]
        let stats = UserStats.from(records: records)

        #expect(stats.completedLessons == 1) // Same lesson
        #expect(stats.totalXP == 105) // All XP accumulates
    }
}

// MARK: - Achievement Tests

@Suite("Achievement System")
struct AchievementTests {

    @Test("Achievement categories are correct")
    func achievementCategories() {
        #expect(Achievement.firstLesson.category == .milestones)
        #expect(Achievement.weekStreak.category == .streaks)
        #expect(Achievement.xp100.category == .xp)
        #expect(Achievement.unitComplete.category == .mastery)
        #expect(Achievement.earlyBird.category == .special)
    }

    @Test("Achievement rarities have correct XP rewards")
    func achievementXPRewards() {
        #expect(Achievement.firstLesson.xpReward == 10) // Common
        #expect(Achievement.firstPerfect.xpReward == 25) // Uncommon
        #expect(Achievement.unitComplete.xpReward == 50) // Rare
        #expect(Achievement.monthStreak.xpReward == 100) // Epic
        #expect(Achievement.allUnitsComplete.xpReward == 250) // Legendary
    }

    @Test("All achievements have required properties")
    func achievementPropertiesExist() {
        for achievement in Achievement.allCases {
            #expect(!achievement.title.isEmpty)
            #expect(!achievement.koreanTitle.isEmpty)
            #expect(!achievement.description.isEmpty)
            #expect(!achievement.emoji.isEmpty)
        }
    }

    @Test("StreakTier mapping is correct")
    func streakTierMapping() {
        #expect(StreakTier.from(days: 0) == .none)
        #expect(StreakTier.from(days: 3) == .starter)
        #expect(StreakTier.from(days: 7) == .weekly)
        #expect(StreakTier.from(days: 14) == .biweekly)
        #expect(StreakTier.from(days: 30) == .monthly)
        #expect(StreakTier.from(days: 100) == .legendary)
    }
}

// MARK: - Lesson Progress Tests

@Suite("Lesson Progress")
struct LessonProgressTests {

    @Test("First lesson is always unlocked")
    func firstLessonUnlocked() {
        let service = LessonProgressService()
        let firstLesson = ContentLoader.lessons.first { $0.order == 1 && $0.unitId == 1 }!

        #expect(service.isUnlocked(firstLesson))
    }

    @Test("Unit 1 is always unlocked")
    func unit1AlwaysUnlocked() {
        let service = LessonProgressService()

        #expect(service.isUnitUnlocked(1))
    }

    @Test("Lesson completion updates progress")
    func lessonCompletionUpdates() {
        let service = LessonProgressService()
        let records = [
            PracticeRecord(lessonId: 1, score: 85, xpEarned: 35)
        ]

        service.updateProgress(from: records)

        let lesson1 = ContentLoader.lessons.first { $0.id == 1 }!
        #expect(service.isCompleted(lesson1))
    }

    @Test("Low score does not mark lesson complete")
    func lowScoreNotComplete() {
        let service = LessonProgressService()
        let records = [
            PracticeRecord(lessonId: 1, score: 50, xpEarned: 10) // Below 70%
        ]

        service.updateProgress(from: records)

        let lesson1 = ContentLoader.lessons.first { $0.id == 1 }!
        #expect(!service.isCompleted(lesson1))
    }

    @Test("LessonState is correct")
    func lessonStateCorrect() {
        let service = LessonProgressService()
        let records = [
            PracticeRecord(lessonId: 1, score: 85, xpEarned: 35)
        ]
        service.updateProgress(from: records)

        let lesson1 = ContentLoader.lessons.first { $0.id == 1 }!
        let lesson2 = ContentLoader.lessons.first { $0.id == 2 }!
        let lesson3 = ContentLoader.lessons.first { $0.id == 3 }!

        #expect(service.lessonState(lesson1) == .completed)
        #expect(service.lessonState(lesson2) == .unlocked)
        #expect(service.lessonState(lesson3) == .locked)
    }
}

// MARK: - Content Loader Tests

@Suite("Content Data Integrity")
struct ContentLoaderTests {

    @Test("All lessons have valid unit IDs")
    func lessonsHaveValidUnitIds() {
        let unitIds = Set(ContentLoader.units.map(\.id))
        for lesson in ContentLoader.lessons {
            #expect(unitIds.contains(lesson.unitId))
        }
    }

    @Test("All units have at least one lesson")
    func unitsHaveLessons() {
        for unit in ContentLoader.units {
            #expect(unit.lessonCount > 0)
        }
    }

    @Test("Lesson IDs are unique")
    func lessonIdsAreUnique() {
        let ids = ContentLoader.lessons.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("Unit IDs are unique")
    func unitIdsAreUnique() {
        let ids = ContentLoader.units.map(\.id)
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count)
    }

    @Test("Correct number of lessons per unit")
    func correctLessonCountPerUnit() {
        for unit in ContentLoader.units {
            let actualCount = ContentLoader.lessons.filter { $0.unitId == unit.id }.count
            #expect(actualCount == unit.lessonCount)
        }
    }
}

// MARK: - Error Handling Tests

@Suite("Error Handling")
struct ErrorHandlingTests {

    @Test("AppError has correct descriptions")
    func appErrorDescriptions() {
        let networkError = AppError.network(.noConnection)
        #expect(networkError.errorDescription?.contains("internet") == true)

        let audioError = AppError.audio(.permissionDenied)
        #expect(audioError.errorDescription?.contains("Microphone") == true)
    }

    @Test("Network errors are retryable")
    func networkErrorsRetryable() {
        #expect(AppError.network(.noConnection).isRetryable)
        #expect(AppError.network(.timeout).isRetryable)
        #expect(AppError.network(.serverError).isRetryable)
    }

    @Test("Recovery actions are correct")
    func recoveryActions() {
        #expect(AppError.network(.noConnection).recoveryAction == .checkConnection)
        #expect(AppError.audio(.permissionDenied).recoveryAction == .openSettings)
    }
}

// MARK: - LessonFeedback Tests

@Suite("Lesson Feedback")
struct LessonFeedbackTests {

    @Test("Feedback mock generation works")
    func feedbackMockGeneration() {
        let lesson = ContentLoader.lessons[0]
        let feedback = MockData.mockFeedback(for: lesson, score: 90)

        #expect(feedback.overallScore == 90)
        #expect(feedback.xpEarned == 50)
        #expect(feedback.emoji == "🎉")
    }

    @Test("Star count is correct for different scores")
    func starCountForScores() {
        let lesson = ContentLoader.lessons[0]

        let excellent = MockData.mockFeedback(for: lesson, score: 95)
        #expect(excellent.starCount == 3)

        let good = MockData.mockFeedback(for: lesson, score: 75)
        #expect(good.starCount == 2)

        let fair = MockData.mockFeedback(for: lesson, score: 55)
        #expect(fair.starCount == 1)

        let poor = MockData.mockFeedback(for: lesson, score: 40)
        #expect(poor.starCount == 0)
    }
}
