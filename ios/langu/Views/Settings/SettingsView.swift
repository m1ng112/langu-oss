import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("dailyGoal") private var dailyGoal = 3
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("reminderHour") private var reminderHour = 19
    @AppStorage("reminderMinute") private var reminderMinute = 0
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @State private var appeared = false
    @State private var notificationService = NotificationService()
    @State private var showTimePicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxl) {
                // Header
                header
                    .popIn(isVisible: appeared, delay: 0)

                // Appearance
                appearanceSection
                    .popIn(isVisible: appeared, delay: 0.05)

                // Learning Settings
                learningSection
                    .popIn(isVisible: appeared, delay: 0.1)

                // Notifications
                notificationsSection
                    .popIn(isVisible: appeared, delay: 0.2)

                // About
                aboutSection
                    .popIn(isVisible: appeared, delay: 0.3)

                // Debug (dev only)
                #if DEBUG
                debugSection
                    .popIn(isVisible: appeared, delay: 0.4)
                #endif

                Spacer(minLength: 100)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.lg)
        }
        .background(Color.appBg)
        .preferredColorScheme(appearanceMode.colorScheme)
        .onAppear {
            withAnimation(.spring(response: 0.5)) {
                appeared = true
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Settings")
                .font(AppFont.title())
                .foregroundColor(.appTextPrimary)

            Text("Customize your learning experience")
                .font(AppFont.body())
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Appearance")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            HStack(spacing: AppSpacing.md) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    AppearanceButton(
                        mode: mode,
                        isSelected: appearanceMode == mode
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            appearanceMode = mode
                        }
                    }
                }
            }
        }
    }

    // MARK: - Learning Section

    private var learningSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Learning")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 0) {
                // Daily Goal
                HStack {
                    Image(systemName: "target")
                        .font(.system(size: 20))
                        .foregroundColor(.appGreen)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Goal")
                            .font(AppFont.body())
                            .foregroundColor(.appTextPrimary)

                        Text("\(dailyGoal) lessons per day")
                            .font(AppFont.caption())
                            .foregroundColor(.appTextSecondary)
                    }

                    Spacer()

                    Stepper("", value: $dailyGoal, in: 1...10)
                        .labelsHidden()
                }
                .padding(AppSpacing.lg)

                Divider()
                    .padding(.leading, 56)

                // Difficulty (placeholder)
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 20))
                        .foregroundColor(.appBlue)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Difficulty")
                            .font(AppFont.body())
                            .foregroundColor(.appTextPrimary)

                        Text("Beginner")
                            .font(AppFont.caption())
                            .foregroundColor(.appTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextMuted)
                }
                .padding(AppSpacing.lg)
            }
            .cardStyle()
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Notifications")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 0) {
                // Daily Reminder Toggle
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.appOrange)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminder")
                            .font(AppFont.body())
                            .foregroundColor(.appTextPrimary)

                        Text(notificationsEnabled ? "Enabled" : "Get reminded to practice")
                            .font(AppFont.caption())
                            .foregroundColor(.appTextSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(.appGreen)
                }
                .padding(AppSpacing.lg)
                .onChange(of: notificationsEnabled) { _, newValue in
                    handleNotificationToggle(enabled: newValue)
                }

                // Reminder Time (only show when enabled)
                if notificationsEnabled {
                    Divider()
                        .padding(.leading, 56)

                    Button {
                        showTimePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appBlue)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reminder Time")
                                    .font(AppFont.body())
                                    .foregroundColor(.appTextPrimary)

                                Text(formattedReminderTime)
                                    .font(AppFont.caption())
                                    .foregroundColor(.appTextSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appTextMuted)
                        }
                        .padding(AppSpacing.lg)
                    }
                }

                // Authorization status warning
                if notificationsEnabled && !notificationService.isAuthorized {
                    Divider()
                        .padding(.leading, 56)

                    Button {
                        notificationService.openNotificationSettings()
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appYellow)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications Disabled")
                                    .font(AppFont.body())
                                    .foregroundColor(.appTextPrimary)

                                Text("Tap to open Settings")
                                    .font(AppFont.caption())
                                    .foregroundColor(.appTextSecondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 14))
                                .foregroundColor(.appTextMuted)
                        }
                        .padding(AppSpacing.lg)
                    }
                }
            }
            .cardStyle()
        }
        .sheet(isPresented: $showTimePicker) {
            ReminderTimePickerSheet(
                hour: $reminderHour,
                minute: $reminderMinute,
                onSave: {
                    scheduleReminder()
                }
            )
            .presentationDetents([.height(320)])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            Task {
                await notificationService.checkAuthorizationStatus()
            }
        }
    }

    private var formattedReminderTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    private func handleNotificationToggle(enabled: Bool) {
        Task {
            if enabled {
                let granted = await notificationService.requestAuthorization()
                if granted {
                    await notificationService.scheduleDailyReminder(at: reminderHour, minute: reminderMinute)
                }
            } else {
                notificationService.cancelDailyReminder()
            }
        }
    }

    private func scheduleReminder() {
        Task {
            await notificationService.scheduleDailyReminder(at: reminderHour, minute: reminderMinute)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("About")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 0) {
                SettingsRow(icon: "info.circle", iconColor: .appBlue, title: "Version", value: "1.0.0")
                Divider().padding(.leading, 56)
                SettingsRow(icon: "doc.text", iconColor: .appPurple, title: "Privacy Policy", showChevron: true)
                Divider().padding(.leading, 56)
                SettingsRow(icon: "envelope", iconColor: .appGreen, title: "Contact Us", showChevron: true)
            }
            .cardStyle()
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            Text("Debug")
                .font(AppFont.headline())
                .foregroundColor(.appTextPrimary)

            VStack(spacing: 0) {
                Button {
                    hasCompletedOnboarding = false
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20))
                            .foregroundColor(.appRed)
                            .frame(width: 32)

                        Text("Reset Onboarding")
                            .font(AppFont.body())
                            .foregroundColor(.appTextPrimary)

                        Spacer()
                    }
                    .padding(AppSpacing.lg)
                }
            }
            .cardStyle()
        }
    }
    #endif
}

// MARK: - Settings Row

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var value: String? = nil
    var showChevron: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 32)

            Text(title)
                .font(AppFont.body())
                .foregroundColor(.appTextPrimary)

            Spacer()

            if let value {
                Text(value)
                    .font(AppFont.body())
                    .foregroundColor(.appTextSecondary)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appTextMuted)
            }
        }
        .padding(AppSpacing.lg)
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Appearance Button

private struct AppearanceButton: View {
    let mode: AppearanceMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HapticFeedback.light.play()
            action()
        } label: {
            VStack(spacing: AppSpacing.sm) {
                ZStack {
                    // Circle background
                    Circle()
                        .fill(isSelected ? Color.appGreenLight : Color.appSurface)
                        .frame(width: 72, height: 72)

                    Circle()
                        .strokeBorder(isSelected ? Color.appGreen : Color.clear, lineWidth: 3)
                        .frame(width: 72, height: 72)

                    Image(systemName: mode.icon)
                        .font(.system(size: 26))
                        .foregroundColor(isSelected ? .appGreen : .appTextMuted)
                }
                .shadow(
                    color: isSelected ? Color.appGreen.opacity(0.2) : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )

                Text(mode.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .appGreen : .appTextSecondary)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(AppAnimation.spring, value: isSelected)
    }
}

// MARK: - Reminder Time Picker Sheet

private struct ReminderTimePickerSheet: View {
    @Binding var hour: Int
    @Binding var minute: Int
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime: Date

    init(hour: Binding<Int>, minute: Binding<Int>, onSave: @escaping () -> Void) {
        _hour = hour
        _minute = minute
        self.onSave = onSave

        var components = DateComponents()
        components.hour = hour.wrappedValue
        components.minute = minute.wrappedValue
        let date = Calendar.current.date(from: components) ?? Date()
        _selectedTime = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.xl) {
                Text("🔔")
                    .font(.system(size: 48))

                Text("Set Reminder Time")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.appTextPrimary)

                DatePicker(
                    "Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding(.top, AppSpacing.xl)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        hour = components.hour ?? 19
                        minute = components.minute ?? 0
                        onSave()
                        HapticFeedback.medium.play()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appGreen)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
