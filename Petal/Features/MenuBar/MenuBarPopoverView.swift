import PetalKit
import SwiftUI

public struct MenuBarPopoverView: View {
    public var notes: [Note]
    public var backupStatus: BackupStatus
    public var onNewNote: () -> Void
    public var onOpenNote: (Note) -> Void
    public var onOpenBoard: () -> Void
    public var onOpenSettings: () -> Void

    @State private var search: String = ""

    public init(
        notes: [Note],
        backupStatus: BackupStatus = .backedUp(Date()),
        onNewNote: @escaping () -> Void,
        onOpenNote: @escaping (Note) -> Void,
        onOpenBoard: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void
    ) {
        self.notes = notes
        self.backupStatus = backupStatus
        self.onNewNote = onNewNote
        self.onOpenNote = onOpenNote
        self.onOpenBoard = onOpenBoard
        self.onOpenSettings = onOpenSettings
    }

    private var activeTimerNote: Note? {
        notes.first { $0.hasActiveTimer }
    }

    private var nextReminderNote: Note? {
        notes.filter { $0.hasActiveReminder }
            .sorted { ($0.reminder?.targetDate ?? .distantFuture) < ($1.reminder?.targetDate ?? .distantFuture) }
            .first
    }

    private var displayedNotes: [Note] {
        if search.isEmpty {
            return Array(notes.prefix(4))
        }
        let lower = search.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(lower) ||
                $0.body.lowercased().contains(lower)
        }
    }

    public var body: some View {
        VStack(spacing: Spacing.s) {
            // Header: Title + Search + Cloud backup icon
            headerBar

            // Next Reminder Banner (if any)
            if let reminderNote = nextReminderNote, let rem = reminderNote.reminder {
                reminderBanner(note: reminderNote, reminder: rem)
            }

            // Running Timer Banner (if any)
            if let timerNote = activeTimerNote, let timer = timerNote.timerSession {
                timerBanner(note: timerNote, timer: timer)
            }

            // 2-Column Grid of Recent Notes
            recentNotesGrid

            Divider()

            // Footer actions: Board, Settings, Quit
            footerBar
        }
        .padding(Spacing.m)
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "note.text")
                .foregroundColor(.orange)

            Text("Petal")
                .font(.system(.headline, design: .rounded))

            cloudStatusIcon

            Spacer()

            Button(action: onNewNote) {
                Label("New", systemImage: "plus")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var cloudStatusIcon: some View {
        switch backupStatus {
        case .backedUp:
            Image(systemName: "checkmark.icloud.fill")
                .foregroundColor(.green)
                .font(.system(size: 11))
                .help(backupStatus.message)
        case .syncing:
            Image(systemName: "arrow.triangle.2.circlepath.icloud")
                .foregroundColor(.blue)
                .font(.system(size: 11))
                .help(backupStatus.message)
        case .offline:
            Image(systemName: "bolt.horizontal.icloud")
                .foregroundColor(.secondary)
                .font(.system(size: 11))
                .help(backupStatus.message)
        case .needsSignIn, .driveFull:
            Image(systemName: "exclamationmark.icloud.fill")
                .foregroundColor(.red)
                .font(.system(size: 11))
                .help(backupStatus.message)
        }
    }

    private func reminderBanner(note: Note, reminder: Reminder) -> some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Reminder" : note.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(reminder.targetDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.orange.opacity(0.12))
        .cornerRadius(10)
        .onTapGesture {
            onOpenNote(note)
        }
    }

    private func timerBanner(note: Note, timer: TimerSession) -> some View {
        HStack {
            MascotFaceView(mood: timer.isRunning ? .awake : .sleeping, tint: .blue, size: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Focus Timer" : note.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                Text(timer.formattedRemaining(at: Date()))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.blue.opacity(0.12))
        .cornerRadius(10)
        .onTapGesture {
            onOpenNote(note)
        }
    }

    private var recentNotesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(displayedNotes) { note in
                Button(action: { onOpenNote(note) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(Color(hex: note.color.hex))
                                .frame(width: 8, height: 8)
                            Text(note.title.isEmpty ? "Untitled" : note.title)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        Text(note.previewSnippet)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(8)
                    .frame(height: 64)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(Color(hex: note.color.hex).opacity(0.85))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footerBar: some View {
        HStack(spacing: 10) {
            Button("All Notes (Board)") {
                onOpenBoard()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, design: .rounded))
            .foregroundColor(.secondary)

            Button("Stack List") {
                AppState.shared.openAllNotesStackList()
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(.secondary)

            Spacer()

            Button {
                onOpenSettings()
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
        }
    }
}
