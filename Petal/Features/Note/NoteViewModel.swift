import Observation
import PetalKit
import SwiftUI

@MainActor
@Observable
public final class NoteViewModel: Identifiable {
    public nonisolated let id: Note.ID
    public var note: Note
    public var isHovered: Bool = false
    public var activePopover: ActivePopover?
    public var isRecordingAudio: Bool = false
    public var isSparkling: Bool = false
    public var sparkleItemID: UUID?
    public var currentTheme: PetalTheme = .light

    public enum ActivePopover: String, Identifiable {
        case color
        case reminder
        case alarm
        case timer
        case calendar

        public var id: String {
            rawValue
        }
    }

    private let repository: any NoteRepository
    private let notificationScheduler: any NotificationScheduler
    private let dateProvider: any DateProvider

    public init(
        note: Note,
        repository: any NoteRepository,
        notificationScheduler: any NotificationScheduler,
        dateProvider: any DateProvider = SystemDateProvider()
    ) {
        id = note.id
        self.note = note
        self.repository = repository
        self.notificationScheduler = notificationScheduler
        self.dateProvider = dateProvider
    }

    public func updateTitle(_ newTitle: String) {
        note.title = newTitle
        note.updatedAt = dateProvider.now
        save()
    }

    public func updateBody(_ newBody: String) {
        note.body = newBody
        note.updatedAt = dateProvider.now
        save()
    }

    public var onCollapseToggled: ((Bool) -> Void)?
    public var onColorChanged: ((NoteColor) -> Void)?
    public var onNoteChanged: ((Note) -> Void)?

    public func setColor(_ color: NoteColor) {
        note.color = color
        note.updatedAt = dateProvider.now
        save()
        onColorChanged?(color)
    }

    public func togglePin() {
        note.isPinned.toggle()
        save()
    }

    public func toggleOnDesktop() {
        note.isOnDesktop.toggle()
        save()
    }

    public func setCollapsed(_ collapsed: Bool) {
        guard note.isCollapsed != collapsed else { return }
        note.isCollapsed = collapsed
        save()
        onCollapseToggled?(note.isCollapsed)
    }

    public func toggleCollapse() {
        setCollapsed(!note.isCollapsed)
    }

    @discardableResult
    public func addChecklistItem(text: String = "") -> ChecklistItem {
        if text.isEmpty, let last = note.checklist.last, last.text.trimmingCharacters(in: .whitespaces).isEmpty {
            return last
        }
        let item = ChecklistItem(text: text, isDone: false)
        note.checklist.append(item)
        note.updatedAt = dateProvider.now
        save()
        return item
    }

    public func updateChecklistItem(id: UUID, text: String) {
        guard let index = note.checklist.firstIndex(where: { $0.id == id }) else { return }
        note.checklist[index].text = text
        note.updatedAt = dateProvider.now
        save()
    }

    public func toggleChecklist(item: ChecklistItem) {
        guard let index = note.checklist.firstIndex(where: { $0.id == item.id }) else { return }
        note.checklist[index].isDone.toggle()
        note.updatedAt = dateProvider.now

        if note.checklist[index].isDone {
            sparkleItemID = item.id
            isSparkling = true
            Task {
                try? await Task.sleep(nanoseconds: 600_000_000)
                isSparkling = false
                sparkleItemID = nil
            }
        }
        save()
    }

    public func removeChecklistItem(at index: Int) {
        guard index >= 0, index < note.checklist.count else { return }
        note.checklist.remove(at: index)
        note.updatedAt = dateProvider.now
        save()
    }

    public func removeChecklistItem(id: UUID) {
        guard let index = note.checklist.firstIndex(where: { $0.id == id }) else { return }
        note.checklist.remove(at: index)
        note.updatedAt = dateProvider.now
        save()
    }

    public func setReminder(date: Date, repeatOption: Reminder.RepeatOption) {
        let reminder = Reminder(targetDate: date, repeatOption: repeatOption)
        note.reminder = reminder
        save()

        Task {
            try? await notificationScheduler.scheduleReminder(
                for: note.id,
                title: note.title.isEmpty ? "Note reminder" : note.title,
                at: date,
                repeatOption: repeatOption
            )
        }
    }

    public func clearReminder() {
        note.reminder = nil
        save()
        Task {
            await notificationScheduler.cancelNotifications(for: note.id)
        }
    }

    public func setAlarm(hour: Int, minute: Int, repeatDays: [Int], soundName: String) {
        let alarm = Alarm(hour: hour, minute: minute, repeatDays: repeatDays, soundName: soundName, isEnabled: true)
        note.alarm = alarm
        save()

        if let next = alarm.nextFireDate(from: dateProvider.now) {
            Task {
                try? await notificationScheduler.scheduleAlarm(
                    for: note.id,
                    title: note.title.isEmpty ? "Petal Alarm" : note.title,
                    at: next,
                    soundName: soundName
                )
            }
        }
    }

    public func clearAlarm() {
        note.alarm = nil
        save()
    }

    public func startTimer(minutes: Int) {
        let end = dateProvider.now.addingTimeInterval(Double(minutes * 60))
        let timer = TimerSession(durationMinutes: Double(minutes), endDate: end)
        note.timerSession = timer
        save()

        Task {
            try? await notificationScheduler.scheduleTimer(
                for: note.id,
                title: note.title.isEmpty ? "Timer Done" : "\(note.title) timer done",
                endingAt: end
            )
        }
    }

    public func pauseOrResumeTimer() {
        guard var timer = note.timerSession else { return }
        if timer.isPaused {
            let remaining = timer.remainingSecondsWhenPaused ?? timer.totalSeconds
            timer.endDate = dateProvider.now.addingTimeInterval(remaining)
            timer.remainingSecondsWhenPaused = nil
            timer.isPaused = false
        } else {
            timer.remainingSecondsWhenPaused = timer.remainingSeconds(at: dateProvider.now)
            timer.isPaused = true
            timer.endDate = nil
        }
        note.timerSession = timer
        save()
    }

    public func resetTimer() {
        note.timerSession = nil
        save()
    }

    public func saveVoiceClip(url: URL, duration: TimeInterval, waveform: [Float], transcript: String?) {
        let clip = VoiceClip(
            relativePath: url.lastPathComponent,
            duration: duration,
            waveformSamples: waveform,
            transcript: transcript
        )
        note.voiceClip = clip
        if let transcript = transcript, !transcript.isEmpty {
            if note.body.isEmpty {
                note.body = transcript
            } else {
                note.body += "\n\n" + transcript
            }
        }
        save()
    }

    public func removeVoiceClip() {
        note.voiceClip = nil
        save()
    }

    public func save() {
        onNoteChanged?(note)
        Task {
            try? await repository.save(note)
        }
    }
}
