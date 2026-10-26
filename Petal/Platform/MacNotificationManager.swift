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
        requestAuthorization()
    }

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            #if DEBUG
            print("Notification authorization granted: \(granted), error: \(String(describing: error))")
            #endif
        }
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
        requestAuthorization()

        let content = UNMutableNotificationContent()
        content.title = "🌸 Petal Reminder"
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

    public func scheduleAlarm(for noteID: Note.ID, title: String, at date: Date, soundName: String) async throws {
        requestAuthorization()

        let content = UNMutableNotificationContent()
        content.title = "⏰ Petal Alarm"
        content.body = title.isEmpty ? "Time to wake up or check your note!" : title
        content.sound = .default
        content.userInfo = [
            "noteID": noteID.uuidString,
            "isAlarm": true,
            "soundName": soundName
        ]

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
        requestAuthorization()

        let content = UNMutableNotificationContent()
        content.title = "⏳ Timer Complete"
        content.body = title.isEmpty ? "Your focus session is finished!" : title
        content.sound = .default
        content.userInfo = [
            "noteID": noteID.uuidString,
            "isTimer": true
        ]

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
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let isAlarm = (notification.request.content.userInfo["isAlarm"] as? Bool) ?? false
        let isTimer = (notification.request.content.userInfo["isTimer"] as? Bool) ?? false ||
            notification.request.identifier.starts(with: "timer_")
        let soundName = (notification.request.content.userInfo["soundName"] as? String) ?? "Gentle Chime"

        DispatchQueue.main.async {
            if isAlarm {
                SoundPlayer.shared.play(soundName: soundName)
                SoundPlayer.shared.playAlarmRinging()
            } else if isTimer {
                SoundPlayer.shared.playTimerFinished()
            } else {
                SoundPlayer.shared.playReminderChime()
            }
        }
        completionHandler([.banner, .sound, .badge, .list])
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let idStr = response.notification.request.content.userInfo["noteID"] as? String,
           let uuid = UUID(uuidString: idStr) {
            let isAlarm = (response.notification.request.content.userInfo["isAlarm"] as? Bool) ?? false
            let isTimer = (response.notification.request.content.userInfo["isTimer"] as? Bool) ?? false ||
                response.notification.request.identifier.starts(with: "timer_")
            let popover: NoteViewModel.ActivePopover? = isAlarm ? .alarm : (isTimer ? .timer : .reminder)

            DispatchQueue.main.async {
                AppState.shared.popupScheduledEvent(for: uuid, popover: popover)
            }
        }
        completionHandler()
    }
}
