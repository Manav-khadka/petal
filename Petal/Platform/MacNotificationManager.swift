import Foundation
import PetalKit
import UserNotifications

public final class MacNotificationManager: NSObject, NotificationScheduler, @unchecked Sendable,
    UNUserNotificationCenterDelegate {
    public static let shared = MacNotificationManager()

    override public init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupCategories()
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func setupCategories() {
        let snooze5 = UNNotificationAction(identifier: "SNOOZE_5", title: "Snooze 5 min", options: [])
        let snooze15 = UNNotificationAction(identifier: "SNOOZE_15", title: "Snooze 15 min", options: [])
        let snooze60 = UNNotificationAction(identifier: "SNOOZE_60", title: "Snooze 1 hour", options: [])

        let category = UNNotificationCategory(
            identifier: "PETAL_REMINDER",
            actions: [snooze5, snooze15, snooze60],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    public func scheduleReminder(
        for noteID: Note.ID,
        title: String,
        at date: Date,
        repeatOption _: Reminder.RepeatOption
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = title.isEmpty ? "Your Petal note reminder is due!" : title
        content.sound = .default
        content.categoryIdentifier = "PETAL_REMINDER"
        content.userInfo = ["noteID": noteID.uuidString]

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "reminder_\(noteID.uuidString)",
            content: content,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    public func scheduleAlarm(for noteID: Note.ID, title: String, at date: Date, soundName _: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Petal Alarm"
        content.body = title.isEmpty ? "Time to wake up or check your note!" : title
        content.sound = .defaultCritical
        content.userInfo = ["noteID": noteID.uuidString, "isAlarm": true]

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "alarm_\(noteID.uuidString)",
            content: content,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    public func scheduleTimer(for noteID: Note.ID, title: String, endingAt date: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Timer Finished"
        content.body = title.isEmpty ? "Your timer is up!" : title
        content.sound = .default

        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "timer_\(noteID.uuidString)",
            content: content,
            trigger: trigger
        )
        try await UNUserNotificationCenter.current().add(request)
    }

    public func cancelNotifications(for noteID: Note.ID) async {
        let idStr = noteID.uuidString
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "reminder_\(idStr)",
            "alarm_\(idStr)",
            "timer_\(idStr)"
        ])
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
