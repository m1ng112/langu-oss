import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(Tab.allCases, id: \.rawValue) { tab in
                Button {
                    withAnimation(AppAnimation.spring) {
                        selectedTab = tab
                    }
                    HapticFeedback.light.play()
                } label: {
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                            .symbolEffect(.bounce, value: selectedTab == tab)

                        Text(tab.title)
                            .font(AppFont.caption())
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                    }
                    .foregroundStyle(selectedTab == tab ? Color.appGreen : Color.appTextMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(
                        selectedTab == tab
                            ? Color.appGreenLight.opacity(0.4)
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
                .accessibilityLabel(tab.title)
                .accessibilityHint("Switch to \(tab.title) tab")
                .accessibilityAddTraits(selectedTab == tab ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xxl, style: .continuous)
                .fill(Color.appCardBg)
                .shadow(color: AppShadow.lg.color, radius: AppShadow.lg.radius, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
