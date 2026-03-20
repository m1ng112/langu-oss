import SwiftUI
import SwiftData

// MARK: - Home Mode

enum HomeMode: String, CaseIterable {
    case pronunciation = "Pronunciation"
    case freeTalk = "Free Talk"
    case stories = "Stories"
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(LessonProgressService.self) private var progressService
    @Query private var records: [PracticeRecord]
    @State private var appeared = false
    @State private var selectedMode: HomeMode = .pronunciation

    private var stats: UserStats {
        UserStats.from(records: records)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Header
                headerSection
                    .popIn(isVisible: appeared, delay: 0)

                // Mode Switcher
                modeSwitcher
                    .popIn(isVisible: appeared, delay: 0.03)

                // Mode-specific content
                switch selectedMode {
                case .pronunciation:
                    pronunciationContent
                case .freeTalk:
                    freeTalkContent
                case .stories:
                    storiesContent
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, 100)
        }
        .background(Color.appBg)
        .onAppear {
            withAnimation {
                appeared = true
            }
            progressService.updateProgress(from: records)
        }
        .onChange(of: records.count) { _, _ in
            progressService.updateProgress(from: records)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("langu")
                    .font(AppFont.title())
                    .foregroundStyle(Color.appGreen)
                Text("Korean Pronunciation")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            StreakBadge(streak: stats.streak)
        }
    }

    // MARK: - Mode Switcher

    private var modeSwitcher: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(HomeMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(AppAnimation.spring) {
                        selectedMode = mode
                    }
                } label: {
                    Text(mode.rawValue)
                        .font(AppFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(selectedMode == mode ? .white : Color.appTextSecondary)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.sm)
                        .background(
                            Capsule()
                                .fill(selectedMode == mode ? Color.appGreen : Color.appSurface)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.xs)
        .background(
            Capsule()
                .fill(Color.appSurface)
        )
    }

    // MARK: - Pronunciation Content

    private var pronunciationContent: some View {
        VStack(spacing: AppSpacing.xxl) {
            // Daily Goal
            DailyGoalCard()
                .popIn(isVisible: appeared, delay: 0.06)

            // Stats cards
            statsSection
                .popIn(isVisible: appeared, delay: 0.09)

            // Lessons
            lessonsSection
        }
    }

    // MARK: - Free Talk Content

    private var freeTalkContent: some View {
        VStack(spacing: AppSpacing.md) {
            ForEach(Array(ContentLoader.themes.enumerated()), id: \.element.id) { index, theme in
                ThemeCard(theme: theme) {
                    appState.navigateToThemePractice(theme)
                }
                .popIn(isVisible: appeared, delay: 0.06 + Double(index) * 0.03)
            }
        }
    }

    // MARK: - Stories Content

    private var storiesContent: some View {
        VStack(spacing: AppSpacing.lg) {
            ForEach(Array(ContentLoader.stories.enumerated()), id: \.element.id) { index, story in
                StoryCard(story: story) {
                    appState.navigateToStory(story)
                }
                .popIn(isVisible: appeared, delay: 0.06 + Double(index) * 0.05)
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            StatCard(title: "XP", value: "\(stats.totalXP)", icon: "bolt.fill", color: .appYellow)
            StatCard(title: "Lessons", value: "\(stats.completedLessons)", icon: "book.fill", color: .appBlue)
            StatCard(title: "Avg Score", value: stats.averageScore > 0 ? "\(stats.averageScore)%" : "—", icon: "chart.line.uptrend.xyaxis", color: .appGreen)
        }
    }

    // MARK: - Lessons

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxl) {
            ForEach(Array(ContentLoader.units.enumerated()), id: \.element.id) { unitIndex, unit in
                UnitSection(
                    unit: unit,
                    unitIndex: unitIndex,
                    appeared: appeared,
                    records: records
                ) { lesson in
                    appState.navigateToLesson(lesson)
                }
            }
        }
    }
}

// MARK: - Unit Section

private struct UnitSection: View {
    let unit: LessonUnit
    let unitIndex: Int
    let appeared: Bool
    let records: [PracticeRecord]
    let onLessonTap: (Lesson) -> Void

    @Environment(LessonProgressService.self) private var progressService
    @State private var isExpanded = true

    private var isUnitLocked: Bool {
        !progressService.isUnitUnlocked(unit.id)
    }

    private var unitProgress: (completed: Int, total: Int) {
        progressService.unitProgress(unit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Unit Header
            Button {
                guard !isUnitLocked else { return }
                withAnimation(AppAnimation.spring) {
                    isExpanded.toggle()
                }
                HapticFeedback.light.play()
            } label: {
                HStack(spacing: AppSpacing.lg) {
                    // Unit emoji or lock - larger circle
                    ZStack {
                        Circle()
                            .fill(isUnitLocked ? Color.appSurface : Color.appGreenLight.opacity(0.5))
                            .frame(width: 60, height: 60)

                        if isUnitLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.appTextMuted)
                        } else {
                            Text(unit.emoji)
                                .font(.system(size: 30))
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(unit.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(isUnitLocked ? .appTextMuted : .appTextPrimary)

                        HStack(spacing: AppSpacing.sm) {
                            Text("\(unit.lessonCount) lessons \u{2022} \(unit.difficulty.rawValue)")
                                .font(AppFont.caption())
                                .foregroundColor(.appTextSecondary)

                            if !isUnitLocked && unitProgress.completed > 0 {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color.appGreen)
                                        .frame(width: 6, height: 6)
                                    Text("\(unitProgress.completed)/\(unitProgress.total)")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.appGreen)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Right indicator in circle
                    ZStack {
                        if isUnitLocked {
                            Circle()
                                .fill(Color.appSurface)
                                .frame(width: 40, height: 40)
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextMuted)
                        } else if unitProgress.completed == unitProgress.total {
                            Circle()
                                .fill(Color.appGreen)
                                .frame(width: 40, height: 40)
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .fill(Color.appSurface)
                                .frame(width: 40, height: 40)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appTextMuted)
                                .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.xxl)
                .background(
                    ZStack {
                        if !isUnitLocked {
                            // 3D bottom edge
                            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                                .fill(unitProgress.completed == unitProgress.total ? Color.appGreen.opacity(0.3) : Color.black.opacity(0.08))
                                .offset(y: 4)
                        }

                        // Main surface
                        RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                            .fill(isUnitLocked ? Color.appSurface.opacity(0.5) : Color.appCardBg)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
                .opacity(isUnitLocked ? 0.7 : 1.0)
            }
            .buttonStyle(ScalePressButtonStyle())
            .disabled(isUnitLocked)
            .popIn(isVisible: appeared, delay: 0.1 + Double(unitIndex) * 0.05)

            // Lessons
            if isExpanded && !isUnitLocked {
                VStack(spacing: AppSpacing.xl) {
                    ForEach(Array(unit.lessons.enumerated()), id: \.element.id) { lessonIndex, lesson in
                        LessonCard(
                            lesson: lesson,
                            state: progressService.lessonState(lesson),
                            bestScore: progressService.bestScore(for: lesson.id, records: records),
                            action: {
                                onLessonTap(lesson)
                            }
                        )
                        .popIn(isVisible: appeared, delay: 0.15 + Double(unitIndex) * 0.05 + Double(lessonIndex) * 0.03)
                    }
                }
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            // Icon in colored circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text(title)
                .font(AppFont.caption())
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
    }
}
