import Foundation

public struct Reminder: Codable, Sendable, Hashable, Identifiable {
    public enum RepeatOption: String, Codable, Sendable, CaseIterable {
        case none = "Never"
        case daily = "Daily"
        case weekdays = "Weekdays"
        case weekly = "Weekly"
    }

    public let id: UUID
    public var targetDate: Date
    public var repeatOption: RepeatOption
    public var isCompleted: Bool
    public var snoozeUntil: Date?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        targetDate: Date,
        repeatOption: RepeatOption = .none,
        isCompleted: Bool = false,
        snoozeUntil: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.targetDate = targetDate
        self.repeatOption = repeatOption
        self.isCompleted = isCompleted
        self.snoozeUntil = snoozeUntil
        self.createdAt = createdAt
    }

    public var effectiveDate: Date {
        snoozeUntil ?? targetDate
    }

    public func isDue(at now: Date) -> Bool {
        !isCompleted && effectiveDate <= now
    }
}
