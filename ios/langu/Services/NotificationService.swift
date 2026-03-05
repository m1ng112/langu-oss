import UserNotifications
import SwiftUI

@Observable
final class NotificationService {
    var isAuthorized = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let notificationCenter = UNUserNotificationCenter.current()
    private let dailyReminderIdentifier = "daily_practice_reminder"

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            authorizationStatus = settings.authorizationStatus
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
                authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("[NotificationService] Authorization error: \(error)")
            return false
        }
    }

    // MARK: - Daily Reminder

    func scheduleDailyReminder(at hour: Int, minute: Int) async {
        // Cancel existing reminder first
        cancelDailyReminder()

        // Check authorization
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }

        // Create content
        let content = UNMutableNotificationContent()
        content.title = "Time to practice! 🇰🇷"
        content.body = "Keep your streak going with a quick Korean lesson."
        content.sound = .default
        content.badge = 1

        // Create trigger (daily at specified time)
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: dailyReminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("[NotificationService] Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("[NotificationService] Failed to schedule reminder: \(error)")
        }
    }

    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [dailyReminderIdentifier])
        print("[NotificationService] Daily reminder cancelled")
    }

    // MARK: - Badge

    func clearBadge() async {
        try? await notificationCenter.setBadgeCount(0)
    }

    // MARK: - Settings Deep Link

    func openNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Reminder Time

struct ReminderTime: Codable, Equatable {
    var hour: Int
    var minute: Int

    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    static let `default` = ReminderTime(hour: 19, minute: 0) // 7:00 PM
}
