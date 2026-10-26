import Foundation

public enum AgendaItemType: String, Sendable, Codable, CaseIterable {
    case reminder
    case alarm
    case task

    public var title: String {
        switch self {
        case .reminder: return "Reminder"
        case .alarm: return "Alarm"
        case .task: return "Task"
        }
    }

    public var systemIcon: String {
        switch self {
        case .reminder: return "bell.badge.fill"
        case .alarm: return "alarm.fill"
        case .task: return "checklist"
        }
    }
}

public struct AgendaItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let noteID: Note.ID
    public let noteTitle: String
    public let noteColor: NoteColor
    public let type: AgendaItemType
    public let title: String
    public let date: Date
    public var isCompleted: Bool
    public let checklistItemID: UUID?
    public let reminderID: UUID?
    public let alarmID: UUID?

    public init(
        id: String,
        noteID: Note.ID,
        noteTitle: String,
        noteColor: NoteColor,
        type: AgendaItemType,
        title: String,
        date: Date,
        isCompleted: Bool,
        checklistItemID: UUID? = nil,
        reminderID: UUID? = nil,
        alarmID: UUID? = nil
    ) {
        self.id = id
        self.noteID = noteID
        self.noteTitle = noteTitle
        self.noteColor = noteColor
        self.type = type
        self.title = title
        self.date = date
        self.isCompleted = isCompleted
        self.checklistItemID = checklistItemID
        self.reminderID = reminderID
        self.alarmID = alarmID
    }
}

public extension Array where Element == Note {
    func agendaItems() -> [AgendaItem] {
        var items: [AgendaItem] = []

        for note in self where !note.isTrash && !note.isArchived {
            let noteDisplayTitle = note.title.trimmingCharacters(in: .whitespaces).isEmpty
                ? "Untitled Note"
                : note.title

            // 1. Reminders (Future & Past)
            if let reminder = note.reminder {
                items.append(AgendaItem(
                    id: "reminder_\(reminder.id.uuidString)",
                    noteID: note.id,
                    noteTitle: noteDisplayTitle,
                    noteColor: note.color,
                    type: .reminder,
                    title: note.title.isEmpty ? "Reminder" : note.title,
                    date: reminder.targetDate,
                    isCompleted: reminder.isCompleted,
                    checklistItemID: nil,
                    reminderID: reminder.id,
                    alarmID: nil
                ))
            }

            // 2. Alarms
            if let alarm = note.alarm, alarm.isEnabled {
                if let nextFire = alarm.nextFireDate(from: Date()) {
                    items.append(AgendaItem(
                        id: "alarm_\(alarm.id.uuidString)",
                        noteID: note.id,
                        noteTitle: noteDisplayTitle,
                        noteColor: note.color,
                        type: .alarm,
                        title: "\(alarm.displayTimeString) Alarm",
                        date: nextFire,
                        isCompleted: false,
                        checklistItemID: nil,
                        reminderID: nil,
                        alarmID: alarm.id
                    ))
                }
            }

            // 3. Tasks / Checklist Items
            for task in note.checklist {
                let taskText = task.text.trimmingCharacters(in: .whitespaces).isEmpty
                    ? "To-do"
                    : task.text

                // If note has a reminder date, anchor task to that date; otherwise use note creation date
                let taskDate = note.reminder?.targetDate ?? note.createdAt

                items.append(AgendaItem(
                    id: "task_\(task.id.uuidString)",
                    noteID: note.id,
                    noteTitle: noteDisplayTitle,
                    noteColor: note.color,
                    type: .task,
                    title: taskText,
                    date: taskDate,
                    isCompleted: task.isDone,
                    checklistItemID: task.id,
                    reminderID: nil,
                    alarmID: nil
                ))
            }
        }

        return items.sorted(by: { $0.date < $1.date })
    }

    func agendaItems(for date: Date, calendar: Calendar = .current) -> [AgendaItem] {
        agendaItems().filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func upcomingAgendaItems(from now: Date = Date()) -> [AgendaItem] {
        agendaItems().filter { $0.date >= now && !$0.isCompleted }
    }

    func pastAgendaItems(from now: Date = Date()) -> [AgendaItem] {
        agendaItems().filter { $0.date < now || $0.isCompleted }
    }
}
