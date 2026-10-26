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
        notes.first {
            guard let timer = $0.timerSession else { return false }
            return timer.isRunning && !timer.isFinished(at: Date())
        }
    }

    private var nextReminderNote: Note? {
        notes.filter { $0.hasActiveReminder }
            .sorted { ($0.reminder?.targetDate ?? .distantFuture) < ($1.reminder?.targetDate ?? .distantFuture) }
            .first
    }

    private var displayedNotes: [Note] {
        let nonTrash = notes.filter { !$0.isTrash && !$0.isArchived }
        if search.isEmpty {
            // Deduplicate empty untitled notes so at most one is shown
            var result: [Note] = []
            var hasEmptyUntitled = false
            for n in nonTrash {
                let isEmpty = n.title.trimmingCharacters(in: .whitespaces).isEmpty &&
                    n.body.trimmingCharacters(in: .whitespaces).isEmpty &&
                    n.checklist.isEmpty
                if isEmpty {
                    if !hasEmptyUntitled {
                        hasEmptyUntitled = true
                        result.append(n)
                    }
                } else {
                    result.append(n)
                }
                if result.count == 4 { break }
            }
            return result
        }
        let lower = search.lowercased()
        return nonTrash.filter {
            $0.title.lowercased().contains(lower) ||
                $0.body.lowercased().contains(lower)
        }
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Header: Title + Status + New Note button
            headerBar

            // Quick Desk Controls: Collapse All & See All
            fastControlsBar

            // Next Reminder Banner (only if active)
            if let reminderNote = nextReminderNote, let rem = reminderNote.reminder {
                reminderBanner(note: reminderNote, reminder: rem)
            }

            // Running Timer Banner (only if actually running and not finished)
            if let timerNote = activeTimerNote, let timer = timerNote.timerSession {
                timerBanner(note: timerNote, timer: timer)
            }

            // 2-Column Grid of Recent Notes with high-contrast text
            recentNotesGrid

            Divider()
                .opacity(0.15)

            // Footer: Board, Stack List, Settings
            footerBar
        }
        .padding(12)
        .frame(width: 320)
        .background(.ultraThinMaterial)
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("🌸")
                    .font(.system(size: 15))

                Text("Petal")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                cloudStatusIcon
            }

            Spacer()

            Button(action: onNewNote) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                    Text("New Note")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Create a new note (⌘N)")
        }
    }

    private var fastControlsBar: some View {
        HStack(spacing: 6) {
            Button(action: {
                AppState.shared.collapseAllNotes()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "capsule")
                        .font(.system(size: 9.5, weight: .semibold))
                    Text("Collapse All")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .foregroundColor(.primary.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(7)
            }
            .buttonStyle(.plain)
            .help("Collapse all desk notes to compact pills (⌃⌥C)")

            Button(action: {
                AppState.shared.expandAllNotes()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 9.5, weight: .semibold))
                    Text("See All")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .foregroundColor(.primary.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .cornerRadius(7)
            }
            .buttonStyle(.plain)
            .help("Expand and reveal all desk notes (⌃⌥E)")

            Spacer()

            Button(action: {
                AppState.shared.openAllNotesStackList()
            }) {
                HStack(spacing: 3.5) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 9.5))
                    Text("Stack")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.12))
                .cornerRadius(7)
            }
            .buttonStyle(.plain)
            .help("All Notes Stack Manager (⌘L)")
        }
    }

    @ViewBuilder
    private var cloudStatusIcon: some View {
        switch backupStatus {
        case .backedUp:
            Image(systemName: "checkmark.icloud.fill")
                .foregroundColor(.green.opacity(0.8))
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
        HStack(spacing: 8) {
            Image(systemName: "bell.fill")
                .foregroundColor(.orange)
                .font(.system(size: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Reminder" : note.title)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(reminder.targetDate.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Open") {
                onOpenNote(note)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(.orange)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(6)
        }
        .padding(8)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(9)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.orange.opacity(0.18), lineWidth: 0.8)
        )
    }

    private func timerBanner(note: Note, timer: TimerSession) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Focus Timer" : note.title)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(timer.formattedRemaining(at: Date()) + " remaining")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.blue)
            }

            Spacer()

            Button("Open") {
                onOpenNote(note)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(.blue)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.12))
            .cornerRadius(6)
        }
        .padding(8)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(9)
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(Color.blue.opacity(0.18), lineWidth: 0.8)
        )
    }

    private var recentNotesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(displayedNotes) { note in
                Button(action: { onOpenNote(note) }) {
                    let inkColor = note.color.requiresDarkText ? Color(hex: "#1C1D21") : Color(hex: "#FAF9F5")
                    let subColor = note.color.requiresDarkText ? Color(hex: "#52525B") : Color(hex: "#D4D4D8")
                    let cardBg = Color(hex: note.color.hex)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(inkColor.opacity(0.35))
                                .frame(width: 6, height: 6)

                            Text(note.title.isEmpty ? "Untitled Note" : note.title)
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                .foregroundColor(inkColor)
                                .lineLimit(1)

                            Spacer()
                        }

                        if !note.checklist.isEmpty {
                            let doneCount = note.checklist.filter(\.isDone).count
                            HStack(spacing: 3) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 8))
                                Text("\(doneCount)/\(note.checklist.count) done")
                                    .font(.system(size: 9.5, design: .rounded))
                            }
                            .foregroundColor(subColor)
                        } else {
                            Text(note.previewSnippet.isEmpty ? "Tap to open..." : note.previewSnippet)
                                .font(.system(size: 9.5, design: .rounded))
                                .foregroundColor(subColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(8)
                    .frame(height: 64)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .background(cardBg)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var footerBar: some View {
        HStack(spacing: 12) {
            Button(action: onOpenBoard) {
                HStack(spacing: 4) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 10))
                    Text("Board")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Button(action: {
                AppState.shared.openAllNotesStackList()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 10))
                    Text("Stack List")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 11.5))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
    }
}
