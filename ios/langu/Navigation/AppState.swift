import SwiftUI
import SwiftData

enum AppScreen: Hashable {
    case home
    case lesson(Lesson)
    case feedback(Lesson, LessonFeedback)
    case storyList
    case story(Story)
    case themeList
    case themePractice(Theme)
    case themeFeedback(Theme, ThemeEvaluation)
}

// Make LessonFeedback Hashable for navigation
extension LessonFeedback: Hashable {
    static func == (lhs: LessonFeedback, rhs: LessonFeedback) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum Tab: Int, CaseIterable {
    case home = 0
    case achievements = 1
    case stats = 2
    case settings = 3

    var title: String {
        switch self {
        case .home: return "Home"
        case .achievements: return "Badges"
        case .stats: return "Stats"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .achievements: return "trophy.fill"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

@Observable
final class AppState {
    var currentTab: Tab = .home
    var navigationPath = NavigationPath()
    var isRecording = false
    var recordingDuration: TimeInterval = 0

    func navigateToLesson(_ lesson: Lesson) {
        navigationPath.append(AppScreen.lesson(lesson))
    }

    func navigateToFeedback(_ lesson: Lesson, _ feedback: LessonFeedback) {
        navigationPath.append(AppScreen.feedback(lesson, feedback))
    }

    func navigateToStories() {
        navigationPath.append(AppScreen.storyList)
    }

    func navigateToStory(_ story: Story) {
        navigationPath.append(AppScreen.story(story))
    }

    func navigateToThemes() {
        navigationPath.append(AppScreen.themeList)
    }

    func navigateToThemePractice(_ theme: Theme) {
        navigationPath.append(AppScreen.themePractice(theme))
    }

    func navigateToThemeFeedback(_ theme: Theme, _ evaluation: ThemeEvaluation) {
        navigationPath.append(AppScreen.themeFeedback(theme, evaluation))
    }

    func navigateHome() {
        navigationPath = NavigationPath()
    }
}
