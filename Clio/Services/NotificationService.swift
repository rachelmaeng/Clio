import Foundation
import UserNotifications

/// Service for managing local push notifications
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var authorizationError: String?

    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Authorization

    /// Request permission to send notifications
    func requestAuthorization() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            authorizationError = nil
        } catch {
            authorizationError = error.localizedDescription
            isAuthorized = false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Scheduling Notifications

    /// Schedule a daily check-in reminder
    func scheduleDailyCheckInReminder(hour: Int = 9, minute: Int = 0) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Good morning"
        content.body = "Take a moment to check in with how you're feeling today."
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-checkin",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            authorizationError = "Failed to schedule notification: \(error.localizedDescription)"
        }
    }

    /// Schedule a movement reminder
    func scheduleMovementReminder(hour: Int = 14, minute: Int = 0) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to move"
        content.body = "A little movement goes a long way. What feels right for your body today?"
        content.sound = .default
        content.categoryIdentifier = "MOVEMENT_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "movement-reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            authorizationError = "Failed to schedule notification: \(error.localizedDescription)"
        }
    }

    /// Schedule a period reminder based on cycle prediction
    func schedulePeriodReminder(daysFromNow: Int) async {
        guard isAuthorized, daysFromNow > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Cycle reminder"
        content.body = "Your period may start soon. Take care of yourself."
        content.sound = .default
        content.categoryIdentifier = "PERIOD_REMINDER"

        let triggerDate = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) ?? Date()
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: "period-reminder-\(daysFromNow)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            authorizationError = "Failed to schedule notification: \(error.localizedDescription)"
        }
    }

    // MARK: - Managing Notifications

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Cancel a specific notification by identifier
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Get all pending notification requests
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}
