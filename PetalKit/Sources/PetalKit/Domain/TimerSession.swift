import Foundation

public struct TimerSession: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var durationMinutes: Double
    public var endDate: Date?
    public var remainingSecondsWhenPaused: Double?
    public var isPaused: Bool

    public static let presetMinutes: [Int] = [5, 10, 25, 45]

    public init(
        id: UUID = UUID(),
        durationMinutes: Double = 25,
        endDate: Date? = nil,
        remainingSecondsWhenPaused: Double? = nil,
        isPaused: Bool = false
    ) {
        self.id = id
        self.durationMinutes = durationMinutes
        self.endDate = endDate
        self.remainingSecondsWhenPaused = remainingSecondsWhenPaused
        self.isPaused = isPaused
    }

    public var totalSeconds: Double {
        durationMinutes * 60.0
    }

    public var isRunning: Bool {
        !isPaused && endDate != nil
    }

    public func remainingSeconds(at now: Date) -> Double {
        if isPaused {
            return max(0, remainingSecondsWhenPaused ?? totalSeconds)
        }
        guard let endDate = endDate else {
            return totalSeconds
        }
        return max(0, endDate.timeIntervalSince(now))
    }

    public func progress(at now: Date) -> Double {
        guard totalSeconds > 0 else { return 1.0 }
        let remaining = remainingSeconds(at: now)
        let elapsed = totalSeconds - remaining
        return min(1.0, max(0.0, elapsed / totalSeconds))
    }

    public func isFinished(at now: Date) -> Bool {
        if isPaused {
            return false
        }
        guard let endDate = endDate else { return false }
        return now >= endDate
    }

    public func formattedRemaining(at now: Date) -> String {
        let seconds = Int(ceil(remainingSeconds(at: now)))
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
