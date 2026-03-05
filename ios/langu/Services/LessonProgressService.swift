import Foundation
import SwiftUI

@Observable
final class LessonProgressService {
    private(set) var completedLessonIds: Set<Int> = []

    // How many lessons unlock ahead of current progress (0 = only next lesson)
    private let unlockAheadCount = 0

    init() {}

    // MARK: - Public API

    func updateProgress(from records: [PracticeRecord]) {
        // A lesson is "completed" if the user has achieved >= 70% score
        let passed = records.filter { $0.score >= 70 }
        completedLessonIds = Set(passed.map(\.lessonId))
    }

    func isCompleted(_ lesson: Lesson) -> Bool {
        completedLessonIds.contains(lesson.id)
    }

    func isUnlocked(_ lesson: Lesson) -> Bool {
        // First lesson of each unit is always unlocked
        if lesson.order == 1 {
            return isUnitUnlocked(lesson.unitId)
        }

        // Check if previous lesson in same unit is completed
        let previousLesson = ContentLoader.lessons.first {
            $0.unitId == lesson.unitId && $0.order == lesson.order - 1
        }

        guard let prev = previousLesson else {
            return true // No previous lesson means unlocked
        }

        return isCompleted(prev)
    }

    func isUnitUnlocked(_ unitId: Int) -> Bool {
        // Unit 1 is always unlocked
        if unitId == 1 {
            return true
        }

        // Check if previous unit is completed
        let previousUnit = ContentLoader.units.first { $0.id == unitId - 1 }
        guard let prevUnit = previousUnit else {
            return true
        }

        return isUnitCompleted(prevUnit)
    }

    func isUnitCompleted(_ unit: LessonUnit) -> Bool {
        unit.lessons.allSatisfy { isCompleted($0) }
    }

    func lessonState(_ lesson: Lesson) -> LessonState {
        if isCompleted(lesson) {
            return .completed
        } else if isUnlocked(lesson) {
            return .unlocked
        } else {
            return .locked
        }
    }

    func unitProgress(_ unit: LessonUnit) -> (completed: Int, total: Int) {
        let completed = unit.lessons.filter { isCompleted($0) }.count
        return (completed, unit.lessons.count)
    }

    func nextLesson(in unit: LessonUnit) -> Lesson? {
        unit.lessons
            .sorted { $0.order < $1.order }
            .first { !isCompleted($0) && isUnlocked($0) }
    }

    func overallProgress() -> (completed: Int, total: Int) {
        let total = ContentLoader.lessons.count
        let completed = completedLessonIds.count
        return (completed, total)
    }

    // Get best score for a lesson
    func bestScore(for lessonId: Int, records: [PracticeRecord]) -> Int? {
        records
            .filter { $0.lessonId == lessonId }
            .max(by: { $0.score < $1.score })?
            .score
    }
}

// MARK: - Lesson State

enum LessonState {
    case locked
    case unlocked
    case completed

    var icon: String {
        switch self {
        case .locked: return "lock.fill"
        case .unlocked: return "play.fill"
        case .completed: return "checkmark"
        }
    }

    var iconColor: Color {
        switch self {
        case .locked: return .appTextMuted
        case .unlocked: return .appGreen
        case .completed: return .white
        }
    }

    var backgroundColor: Color {
        switch self {
        case .locked: return .appSurface
        case .unlocked: return .appGreenLight
        case .completed: return .appGreen
        }
    }
}
