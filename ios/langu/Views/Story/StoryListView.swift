import SwiftUI

struct StoryListView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    private let stories = ContentLoader.stories

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                headerSection
                    .popIn(isVisible: appeared, delay: 0)

                // Story Cards
                ForEach(Array(stories.enumerated()), id: \.element.id) { index, story in
                    StoryCard(story: story) {
                        appState.navigateToStory(story)
                    }
                    .popIn(isVisible: appeared, delay: 0.05 + Double(index) * 0.05)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .background(Color.appBg)
        .navigationTitle("Stories")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation { appeared = true }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Practice reading longer texts")
                .font(AppFont.body())
                .foregroundStyle(Color.appTextSecondary)

            HStack(spacing: AppSpacing.md) {
                DifficultyLegend(difficulty: .beginner)
                DifficultyLegend(difficulty: .intermediate)
                DifficultyLegend(difficulty: .advanced)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Story Card

struct StoryCard: View {
    let story: Story
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.lg) {
                // Emoji
                Text(story.emoji)
                    .font(.system(size: 36))
                    .frame(width: 56, height: 56)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))

                // Content
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(story.titleKorean)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.appTextPrimary)

                    Text(story.title)
                        .font(AppFont.body())
                        .foregroundStyle(Color.appTextSecondary)

                    HStack(spacing: AppSpacing.sm) {
                        Text(story.difficulty.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: story.difficulty.color))

                        Text("•")
                            .foregroundStyle(Color.appTextMuted)

                        Text("\(story.wordCount) words")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appTextMuted)

                        Text("•")
                            .foregroundStyle(Color.appTextMuted)

                        Text("\(story.sentences.count) sentences")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.appTextMuted)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appTextMuted)
            }
            .padding(AppSpacing.lg)
            .background(Color.appCardBg)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
            .shadow(color: AppShadow.sm.color, radius: AppShadow.sm.radius, x: AppShadow.sm.x, y: AppShadow.sm.y)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Difficulty Legend

struct DifficultyLegend: View {
    let difficulty: Story.Difficulty

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<difficulty.stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: difficulty.color))
                }
            }
            Text(difficulty.rawValue)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.appTextMuted)
        }
    }
}
