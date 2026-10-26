import Foundation

public protocol NotificationScheduler: Sendable {
    func scheduleReminder(
        for noteID: Note.ID,
        title: String,
        at date: Date,
        repeatOption: Reminder.RepeatOption
    ) async throws
    func scheduleAlarm(for noteID: Note.ID, title: String, at date: Date, soundName: String) async throws
    func scheduleTimer(for noteID: Note.ID, title: String, endingAt date: Date) async throws
    func cancelNotifications(for noteID: Note.ID) async
}
