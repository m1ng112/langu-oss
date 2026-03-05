import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @State private var appState = AppState()
    @State private var achievementService = AchievementService()
    @State private var progressService = LessonProgressService()
    @State private var errorService = ErrorHandlingService()
    @Query private var records: [PracticeRecord]

    var body: some View {
        if hasCompletedOnboarding {
            mainContent
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch appState.currentTab {
                case .home:
                    NavigationStack(path: Binding(
                        get: { appState.navigationPath },
                        set: { appState.navigationPath = $0 }
                    )) {
                        HomeView()
                            .navigationDestination(for: AppScreen.self) { screen in
                                switch screen {
                                case .home:
                                    HomeView()
                                case .lesson(let lesson):
                                    LessonView(lesson: lesson)
                                case .feedback(let lesson, let feedback):
                                    FeedbackView(lesson: lesson, feedback: feedback)
                                case .storyList:
                                    StoryListView()
                                case .story(let story):
                                    StoryPracticeView(story: story)
                                case .themeList:
                                    ThemeListView()
                                case .themePractice(let theme):
                                    ThemePracticeView(theme: theme)
                                case .themeFeedback(let theme, let evaluation):
                                    ThemeFeedbackView(theme: theme, evaluation: evaluation)
                                }
                            }
                    }

                case .achievements:
                    AchievementsView()

                case .stats:
                    StatsView()

                case .settings:
                    SettingsView()
                }
            }

            // Tab bar (only on root)
            if appState.navigationPath.isEmpty {
                TabBarView(selectedTab: Binding(
                    get: { appState.currentTab },
                    set: { appState.currentTab = $0 }
                ))
            }

            // Achievement unlock overlay
            AchievementUnlockOverlay()

            // Error banner
            ErrorBanner()
        }
        .environment(appState)
        .environment(achievementService)
        .environment(progressService)
        .environment(errorService)
        .onChange(of: records.count) { _, _ in
            achievementService.checkAndUnlock(records: records)
            progressService.updateProgress(from: records)
        }
        .onAppear {
            achievementService.checkAndUnlock(records: records)
            progressService.updateProgress(from: records)
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PracticeRecord.self, inMemory: true)
}
