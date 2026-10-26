import Foundation

public struct Alarm: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var hour: Int
    public var minute: Int
    public var repeatDays: [Int] // 1 = Sunday, 2 = Monday, ... 7 = Saturday
    public var soundName: String
    public var isEnabled: Bool
    public var snoozeUntil: Date?

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        repeatDays: [Int] = [],
        soundName: String = "Gentle Chime",
        isEnabled: Bool = true,
        snoozeUntil: Date? = nil
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.repeatDays = repeatDays
        self.soundName = soundName
        self.isEnabled = isEnabled
        self.snoozeUntil = snoozeUntil
    }

    public var displayTimeString: String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour >= 12 ? "PM" : "AM"
        return String(format: "%d:%02d %@", h, minute, period)
    }

    /// Calculate next firing date from a reference date
    public func nextFireDate(from referenceDate: Date, calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }

        if let snoozeUntil = snoozeUntil, snoozeUntil > referenceDate {
            return snoozeUntil
        }

        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: referenceDate)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let candidateToday = calendar.date(from: components) else { return nil }

        if repeatDays.isEmpty {
            if candidateToday > referenceDate {
                return candidateToday
            } else {
                return calendar.date(byAdding: .day, value: 1, to: candidateToday)
            }
        }

        // Repeat on specific weekdays
        for dayOffset in 0 ..< 7 {
            guard let nextDay = calendar.date(byAdding: .day, value: dayOffset, to: candidateToday) else { continue }
            let weekday = calendar.component(.weekday, from: nextDay)
            if repeatDays.contains(weekday) {
                if dayOffset == 0, nextDay <= referenceDate {
                    continue
                }
                return nextDay
            }
        }

        return nil
    }
}
