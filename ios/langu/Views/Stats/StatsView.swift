import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \PracticeRecord.date, order: .reverse) private var records: [PracticeRecord]
    @State private var appeared = false

    private var stats: UserStats {
        UserStats.from(records: records)
    }

    private var weeklyData: [DailyPractice] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let count = records.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
            return DailyPractice(date: date, count: count)
        }
    }

    private var recentScores: [ScoreEntry] {
        Array(records.prefix(10)).enumerated().map { index, record in
            ScoreEntry(index: index, score: record.score, date: record.date)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Header
                header
                    .popIn(isVisible: appeared, delay: 0)

                // Quick Stats
                quickStatsSection
                    .popIn(isVisible: appeared, delay: 0.1)

                // Weekly Activity
                weeklyActivitySection
                    .popIn(isVisible: appeared, delay: 0.2)

                // Performance
                if !records.isEmpty {
                    performanceSection
                        .popIn(isVisible: appeared, delay: 0.3)
                }

                // Recent Scores
                if !recentScores.isEmpty {
                    recentScoresSection
                        .popIn(isVisible: appeared, delay: 0.4)
                }

                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
        }
        .background(Color.appBg)
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your Progress")
                .font(AppFont.title())
                .foregroundColor(.appTextPrimary)

            Text("Track your Korean learning journey")
                .font(AppFont.body())
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: AppSpacing.lg) {
            StatsStatCard(
                icon: "flame.fill",
                iconColor: .appOrange,
                value: "\(stats.streak)",
                label: "Day Streak",
                trend: stats.streak > 0 ? .up : .neutral
            )

            StatsStatCard(
                icon: "star.fill",
                iconColor: .appYellow,
                value: "\(stats.totalXP)",
                label: "Total XP",
                trend: .up
            )

            StatsStatCard(
                icon: "checkmark.circle.fill",
                iconColor: .appGreen,
                value: "\(stats.completedLessons)",
                label: "Lessons",
                trend: .neutral
            )

            StatsStatCard(
                icon: "chart.line.uptrend.xyaxis",
                iconColor: .appBlue,
                value: "\(stats.averageScore)%",
                label: "Avg Score",
                trend: stats.averageScore >= 70 ? .up : .down
            )
        }
    }

    // MARK: - Weekly Activity

    private var weeklyActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("This Week")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            Chart(weeklyData) { day in
                BarMark(
                    x: .value("Day", day.dayLabel),
                    y: .value("Sessions", day.count)
                )
                .foregroundStyle(day.count > 0 ? Color.appGreen : Color.appSurface)
                .cornerRadius(8)
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text("\(count)")
                                .font(AppFont.caption())
                                .foregroundColor(.appTextMuted)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(AppFont.caption())
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    // MARK: - Performance

    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Performance")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            VStack(spacing: AppSpacing.md) {
                PerformanceRow(
                    label: "Best Score",
                    value: "\(records.map(\.score).max() ?? 0)%",
                    icon: "trophy.fill",
                    color: .appYellow
                )

                PerformanceRow(
                    label: "Sessions Today",
                    value: "\(sessionsToday)",
                    icon: "calendar",
                    color: .appBlue
                )

                PerformanceRow(
                    label: "Total Sessions",
                    value: "\(records.count)",
                    icon: "number",
                    color: .appPurple
                )
            }
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }

    private var sessionsToday: Int {
        let calendar = Calendar.current
        return records.filter { calendar.isDateInToday($0.date) }.count
    }

    // MARK: - Recent Scores

    private var recentScoresSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Recent Scores")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            Chart(recentScores) { entry in
                LineMark(
                    x: .value("Session", entry.index),
                    y: .value("Score", entry.score)
                )
                .foregroundStyle(Color.appGreen)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Session", entry.index),
                    y: .value("Score", entry.score)
                )
                .foregroundStyle(Color.appGreen)
            }
            .frame(height: 120)
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { value in
                    AxisValueLabel {
                        if let score = value.as(Int.self) {
                            Text("\(score)")
                                .font(AppFont.caption())
                                .foregroundColor(.appTextMuted)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(Color.appTextMuted.opacity(0.3))
                }
            }
            .chartXAxis(.hidden)
        }
        .padding(AppSpacing.lg)
        .cardStyle()
    }
}

// MARK: - Supporting Types

private struct DailyPractice: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

private struct ScoreEntry: Identifiable {
    let id = UUID()
    let index: Int
    let score: Int
    let date: Date
}

// MARK: - Stats Stat Card

private struct StatsStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let trend: Trend

    enum Trend {
        case up, down, neutral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                // Icon in colored circle
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                Spacer()

                if trend != .neutral {
                    // Trend pill
                    HStack(spacing: 2) {
                        Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(trend == .up ? .appGreen : .appRed)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background((trend == .up ? Color.appGreen : Color.appRed).opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)

            Text(label)
                .font(AppFont.caption())
                .foregroundColor(.appTextSecondary)
        }
        .padding(AppSpacing.lg)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
    }
}

// MARK: - Performance Row

private struct PerformanceRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            Text(label)
                .font(AppFont.body())
                .foregroundColor(.appTextSecondary)

            Spacer()

            Text(value)
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)
        }
    }
}

#Preview {
    StatsView()
        .modelContainer(for: PracticeRecord.self, inMemory: true)
}
