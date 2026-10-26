import Foundation

public struct ChecklistItem: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var text: String
    public var isDone: Bool

    public init(id: UUID = UUID(), text: String, isDone: Bool = false) {
        self.id = id
        self.text = text
        self.isDone = isDone
    }
}

public enum CollapseStyle: String, Codable, Sendable, CaseIterable {
    case mini // 120x120 square preview
    case pill // 160x32 strip preview
}

public struct Note: Codable, Sendable, Hashable, Identifiable {
    public typealias ID = UUID

    public let id: UUID
    public var title: String
    public var body: String
    public var checklist: [ChecklistItem]
    public var color: NoteColor
    public var isPinned: Bool
    public var isOnDesktop: Bool
    public var isCollapsed: Bool
    public var collapseStyle: CollapseStyle
    public var frameX: Double
    public var frameY: Double
    public var width: Double
    public var height: Double
    public var folder: String
    public var isArchived: Bool
    public var isTrash: Bool
    public var reminder: Reminder?
    public var alarm: Alarm?
    public var timerSession: TimerSession?
    public var voiceClip: VoiceClip?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "",
        body: String = "",
        checklist: [ChecklistItem] = [],
        color: NoteColor = .butter,
        isPinned: Bool = true,
        isOnDesktop: Bool = false,
        isCollapsed: Bool = false,
        collapseStyle: CollapseStyle = .pill,
        frameX: Double = 100,
        frameY: Double = 100,
        width: Double = 280,
        height: Double = 220,
        folder: String = "General",
        isArchived: Bool = false,
        isTrash: Bool = false,
        reminder: Reminder? = nil,
        alarm: Alarm? = nil,
        timerSession: TimerSession? = nil,
        voiceClip: VoiceClip? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.checklist = checklist
        self.color = color
        self.isPinned = isPinned
        self.isOnDesktop = isOnDesktop
        self.isCollapsed = isCollapsed
        self.collapseStyle = collapseStyle
        self.frameX = frameX
        self.frameY = frameY
        self.width = width
        self.height = height
        self.folder = folder
        self.isArchived = isArchived
        self.isTrash = isTrash
        self.reminder = reminder
        self.alarm = alarm
        self.timerSession = timerSession
        self.voiceClip = voiceClip
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var hasActiveReminder: Bool {
        reminder != nil && !(reminder?.isCompleted ?? true)
    }

    public var hasActiveTimer: Bool {
        guard let timer = timerSession, timer.isRunning else { return false }
        if let end = timer.endDate, Date() >= end {
            return false
        }
        return true
    }

    public var hasVoiceNote: Bool {
        voiceClip != nil
    }

    public var previewSnippet: String {
        if !checklist.isEmpty {
            return checklist.prefix(2).map { ($0.isDone ? "✓ " : "○ ") + $0.text }.joined(separator: "\n")
        }
        let lines = body.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lines.prefix(2).joined(separator: "\n")
    }
}
