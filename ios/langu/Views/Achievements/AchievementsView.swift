import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(AchievementService.self) private var achievementService
    @Query private var records: [PracticeRecord]
    @State private var selectedAchievement: Achievement?
    @State private var appeared = false

    private var stats: UserStats {
        UserStats.from(records: records)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xxl) {
                    // Header stats
                    headerSection
                        .popIn(isVisible: appeared, delay: 0)

                    // Category sections
                    ForEach(Array(AchievementCategory.allCases.enumerated()), id: \.element) { index, category in
                        categorySection(category)
                            .popIn(isVisible: appeared, delay: 0.05 + Double(index) * 0.03)
                    }
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.lg)
                .padding(.bottom, 100)
            }
            .background(Color.appBg)
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedAchievement) { achievement in
                achievementDetailSheet(achievement)
            }
            .onAppear {
                withAnimation {
                    appeared = true
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: AppSpacing.lg) {
            // Total unlocked
            VStack(spacing: AppSpacing.xs) {
                Text("\(achievementService.unlockedCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appGreen)

                Text("Unlocked")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.appSurface)
                .frame(width: 1, height: 50)

            // Total available
            VStack(spacing: AppSpacing.xs) {
                Text("\(achievementService.totalCount)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextMuted)

                Text("Total")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(Color.appSurface)
                .frame(width: 1, height: 50)

            // Completion percentage
            VStack(spacing: AppSpacing.xs) {
                Text("\(Int(Double(achievementService.unlockedCount) / Double(achievementService.totalCount) * 100))%")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appYellow)

                Text("Complete")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Category Section

    private func categorySection(_ category: AchievementCategory) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Category header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appGreen)

                Text(category.rawValue)
                    .font(AppFont.headline())
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                // Unlocked count for category
                let unlockedInCategory = category.achievements.filter { achievementService.isUnlocked($0) }.count
                Text("\(unlockedInCategory)/\(category.achievements.count)")
                    .font(AppFont.caption())
                    .foregroundStyle(Color.appTextMuted)
            }

            // Achievement grid
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: AppSpacing.md),
                    GridItem(.flexible(), spacing: AppSpacing.md),
                    GridItem(.flexible(), spacing: AppSpacing.md),
                    GridItem(.flexible(), spacing: AppSpacing.md)
                ],
                spacing: AppSpacing.lg
            ) {
                ForEach(category.achievements) { achievement in
                    Button {
                        selectedAchievement = achievement
                    } label: {
                        AchievementBadge(
                            achievement: achievement,
                            isUnlocked: achievementService.isUnlocked(achievement),
                            progress: achievementService.progress(for: achievement, stats: stats, records: records),
                            unlockedDate: achievementService.unlockedDate(for: achievement)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Detail Sheet

    private func achievementDetailSheet(_ achievement: Achievement) -> some View {
        VStack {
            // Drag indicator
            Capsule()
                .fill(Color.appTextMuted.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, AppSpacing.md)

            Spacer()

            AchievementBadgeLarge(
                achievement: achievement,
                isUnlocked: achievementService.isUnlocked(achievement),
                progress: achievementService.progress(for: achievement, stats: stats, records: records),
                progressText: achievementService.progressText(for: achievement, stats: stats, records: records),
                unlockedDate: achievementService.unlockedDate(for: achievement)
            )

            Spacer()

            // Close button
            Button {
                selectedAchievement = nil
            } label: {
                Text("Close")
                    .font(AppFont.body())
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .background(Color.appBg)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    AchievementsView()
        .environment(AchievementService())
        .modelContainer(for: PracticeRecord.self, inMemory: true)
}
