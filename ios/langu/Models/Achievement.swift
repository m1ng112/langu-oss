import Foundation
import SwiftUI

// MARK: - Achievement Definition

enum Achievement: String, CaseIterable, Identifiable {
    // First Steps
    case firstLesson = "first_lesson"
    case firstPerfect = "first_perfect"

    // Lesson Milestones
    case tenLessons = "ten_lessons"
    case twentyFiveLessons = "twenty_five_lessons"
    case fiftyLessons = "fifty_lessons"
    case hundredLessons = "hundred_lessons"

    // Streak Milestones
    case weekStreak = "week_streak"
    case twoWeekStreak = "two_week_streak"
    case monthStreak = "month_streak"
    case quarterStreak = "quarter_streak"

    // XP Milestones
    case xp100 = "xp_100"
    case xp500 = "xp_500"
    case xp1000 = "xp_1000"
    case xp5000 = "xp_5000"

    // Skill Mastery
    case unitComplete = "unit_complete"
    case allUnitsComplete = "all_units_complete"
    case perfectWeek = "perfect_week"

    // Special
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case weekendWarrior = "weekend_warrior"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .firstLesson: return "First Steps"
        case .firstPerfect: return "Perfect Score"
        case .tenLessons: return "Getting Started"
        case .twentyFiveLessons: return "Committed Learner"
        case .fiftyLessons: return "Dedicated Student"
        case .hundredLessons: return "Century Club"
        case .weekStreak: return "Week Warrior"
        case .twoWeekStreak: return "Fortnight Fighter"
        case .monthStreak: return "Monthly Master"
        case .quarterStreak: return "Quarterly Champion"
        case .xp100: return "XP Hunter"
        case .xp500: return "XP Collector"
        case .xp1000: return "XP Master"
        case .xp5000: return "XP Legend"
        case .unitComplete: return "Unit Graduate"
        case .allUnitsComplete: return "Course Complete"
        case .perfectWeek: return "Perfect Week"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .weekendWarrior: return "Weekend Warrior"
        }
    }

    var koreanTitle: String {
        switch self {
        case .firstLesson: return "첫 걸음"
        case .firstPerfect: return "만점"
        case .tenLessons: return "시작"
        case .twentyFiveLessons: return "열심"
        case .fiftyLessons: return "노력"
        case .hundredLessons: return "백점"
        case .weekStreak: return "일주일"
        case .twoWeekStreak: return "2주"
        case .monthStreak: return "한달"
        case .quarterStreak: return "분기"
        case .xp100: return "XP 사냥꾼"
        case .xp500: return "XP 수집가"
        case .xp1000: return "XP 마스터"
        case .xp5000: return "XP 전설"
        case .unitComplete: return "졸업"
        case .allUnitsComplete: return "완료"
        case .perfectWeek: return "완벽한 주"
        case .earlyBird: return "아침형"
        case .nightOwl: return "올빼미"
        case .weekendWarrior: return "주말 전사"
        }
    }

    var description: String {
        switch self {
        case .firstLesson: return "Complete your first lesson"
        case .firstPerfect: return "Get a perfect score (90%+)"
        case .tenLessons: return "Complete 10 lessons"
        case .twentyFiveLessons: return "Complete 25 lessons"
        case .fiftyLessons: return "Complete 50 lessons"
        case .hundredLessons: return "Complete 100 lessons"
        case .weekStreak: return "Maintain a 7-day streak"
        case .twoWeekStreak: return "Maintain a 14-day streak"
        case .monthStreak: return "Maintain a 30-day streak"
        case .quarterStreak: return "Maintain a 90-day streak"
        case .xp100: return "Earn 100 XP"
        case .xp500: return "Earn 500 XP"
        case .xp1000: return "Earn 1,000 XP"
        case .xp5000: return "Earn 5,000 XP"
        case .unitComplete: return "Complete all lessons in a unit"
        case .allUnitsComplete: return "Complete all units"
        case .perfectWeek: return "Get 90%+ on all lessons for a week"
        case .earlyBird: return "Practice before 8 AM"
        case .nightOwl: return "Practice after 10 PM"
        case .weekendWarrior: return "Practice every weekend for a month"
        }
    }

    var emoji: String {
        switch self {
        case .firstLesson: return "🎯"
        case .firstPerfect: return "💯"
        case .tenLessons: return "📚"
        case .twentyFiveLessons: return "🎓"
        case .fiftyLessons: return "🏅"
        case .hundredLessons: return "🏆"
        case .weekStreak: return "🔥"
        case .twoWeekStreak: return "⚡"
        case .monthStreak: return "💎"
        case .quarterStreak: return "👑"
        case .xp100: return "⭐"
        case .xp500: return "🌟"
        case .xp1000: return "✨"
        case .xp5000: return "💫"
        case .unitComplete: return "📖"
        case .allUnitsComplete: return "🎊"
        case .perfectWeek: return "🌈"
        case .earlyBird: return "🌅"
        case .nightOwl: return "🦉"
        case .weekendWarrior: return "⚔️"
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstLesson, .firstPerfect:
            return .milestones
        case .tenLessons, .twentyFiveLessons, .fiftyLessons, .hundredLessons:
            return .lessons
        case .weekStreak, .twoWeekStreak, .monthStreak, .quarterStreak:
            return .streaks
        case .xp100, .xp500, .xp1000, .xp5000:
            return .xp
        case .unitComplete, .allUnitsComplete, .perfectWeek:
            return .mastery
        case .earlyBird, .nightOwl, .weekendWarrior:
            return .special
        }
    }

    var rarity: AchievementRarity {
        switch self {
        case .firstLesson, .xp100:
            return .common
        case .firstPerfect, .tenLessons, .weekStreak:
            return .uncommon
        case .twentyFiveLessons, .twoWeekStreak, .xp500, .unitComplete, .earlyBird, .nightOwl:
            return .rare
        case .fiftyLessons, .monthStreak, .xp1000, .perfectWeek, .weekendWarrior:
            return .epic
        case .hundredLessons, .quarterStreak, .xp5000, .allUnitsComplete:
            return .legendary
        }
    }

    var xpReward: Int {
        switch rarity {
        case .common: return 10
        case .uncommon: return 25
        case .rare: return 50
        case .epic: return 100
        case .legendary: return 250
        }
    }
}

// MARK: - Achievement Category

enum AchievementCategory: String, CaseIterable {
    case milestones = "Milestones"
    case lessons = "Lessons"
    case streaks = "Streaks"
    case xp = "XP"
    case mastery = "Mastery"
    case special = "Special"

    var icon: String {
        switch self {
        case .milestones: return "flag.fill"
        case .lessons: return "book.fill"
        case .streaks: return "flame.fill"
        case .xp: return "bolt.fill"
        case .mastery: return "star.fill"
        case .special: return "sparkles"
        }
    }

    var achievements: [Achievement] {
        Achievement.allCases.filter { $0.category == self }
    }
}

// MARK: - Achievement Rarity

enum AchievementRarity: String, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var color: Color {
        switch self {
        case .common: return Color(hex: "9CA3AF") // Gray
        case .uncommon: return Color(hex: "22C55E") // Green
        case .rare: return Color(hex: "3B82F6") // Blue
        case .epic: return Color(hex: "A855F7") // Purple
        case .legendary: return Color(hex: "F59E0B") // Gold
        }
    }

    var glowColor: Color {
        color.opacity(0.5)
    }
}

// MARK: - Unlocked Achievement Record

struct UnlockedAchievement: Codable, Identifiable {
    let achievementId: String
    let unlockedAt: Date

    var id: String { achievementId }

    var achievement: Achievement? {
        Achievement(rawValue: achievementId)
    }
}
