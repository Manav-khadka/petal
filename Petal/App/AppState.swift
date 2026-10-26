import AppKit
import Observation
import PetalKit
import SwiftUI

@MainActor
@Observable
public final class AppState {
    public static let shared = AppState()

    public let repository: any NoteRepository
    public let backupService: any BackupService
    public let audioRecorder: any AudioRecorder
    public let speechTranscriber: any PetalSpeechTranscriber
    public let notificationScheduler: any NotificationScheduler

    public var notes: [Note] = []
    public var backupStatus: BackupStatus = .backedUp(Date())
    public var activeControllers: [Note.ID: NotePanelController] = [:]
    public var areNotesHidden: Bool = false

    public let menuBarController = MenuBarController()

    private init() {
        repository = FileNoteRepository()
        backupService = DriveSyncManager()
        audioRecorder = AudioRecordingManager()
        speechTranscriber = SpeechRecognitionManager()
        notificationScheduler = MacNotificationManager.shared
    }

    public func launch() async {
        menuBarController.setup()
        menuBarController.getPopoverView = { [weak self] in
            guard let self = self else { return AnyView(EmptyView()) }
            return AnyView(
                MenuBarPopoverView(
                    notes: self.notes,
                    backupStatus: self.backupStatus,
                    onNewNote: { self.createNewNote() },
                    onOpenNote: { self.openFloatingNote($0) },
                    onOpenBoard: { self.openBoard() },
                    onOpenSettings: { self.openSettings() }
                )
            )
        }

        setupShortcuts()
        await loadNotes()

        if notes.isEmpty {
            await createSampleNotes()
        }

        // Show pinned / active notes
        for note in notes.prefix(3) {
            openFloatingNote(note)
        }
    }

    public func loadNotes() async {
        do {
            notes = try await repository.fetchAll()
        } catch {
            notes = []
        }
    }

    public func createNewNote(title: String = "", body: String = "") {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame

        // Cascade positions slightly
        let offset = CGFloat(activeControllers.count * 30)
        let x = visible.minX + 120 + offset
        let y = visible.maxY - 340 - offset

        let note = Note(
            title: title,
            body: body,
            color: NoteColor.butter,
            frameX: x,
            frameY: y
        )

        notes.insert(note, at: 0)
        Task {
            try? await repository.save(note)
        }
        openFloatingNote(note)
    }

    public func openFloatingNote(_ note: Note) {
        if let existing = activeControllers[note.id] {
            existing.panel?.makeKeyAndOrderFront(nil)
            return
        }

        let controller = NotePanelController(noteID: note.id)
        activeControllers[note.id] = controller

        let viewModel = NoteViewModel(
            note: note,
            repository: repository,
            notificationScheduler: notificationScheduler
        )

        viewModel.onCollapseToggled = { [weak controller, weak viewModel] isCollapsed in
            guard let style = viewModel?.note.collapseStyle else { return }
            DispatchQueue.main.async {
                controller?.setCollapsed(isCollapsed, style: style, animated: true)
            }
        }

        controller.onEscapePressed = { [weak viewModel] in
            if viewModel?.note.isCollapsed == false {
                viewModel?.toggleCollapse()
            }
        }

        controller.onAutoShrinkRequested = { [weak viewModel] in
            if viewModel?.note.isCollapsed == false, viewModel?.activePopover == nil {
                viewModel?.toggleCollapse()
            }
        }

        let frame = CGRect(x: note.frameX, y: note.frameY, width: max(260, note.width), height: max(260, note.height))

        let rootView = NoteCardView(
            viewModel: viewModel,
            audioRecorder: audioRecorder,
            speechTranscriber: speechTranscriber,
            onResize: { [weak controller] delta in
                controller?.resize(by: delta)
            },
            onClose: { [weak self, weak controller] in
                controller?.close()
                self?.activeControllers.removeValue(forKey: note.id)
            }
        )

        controller.onFrameChanged = { [weak self] newFrame in
            guard let self = self else { return }
            if let idx = self.notes.firstIndex(where: { $0.id == note.id }) {
                self.notes[idx].frameX = newFrame.origin.x
                self.notes[idx].frameY = newFrame.origin.y
                if !self.notes[idx].isCollapsed {
                    self.notes[idx].width = max(260, newFrame.width)
                    self.notes[idx].height = max(260, newFrame.height)
                }
                Task {
                    try? await self.repository.save(self.notes[idx])
                }
            }
        }

        controller.show(
            with: rootView,
            frame: frame,
            isPinned: note.isPinned,
            isOnDesktop: note.isOnDesktop,
            isCollapsed: note.isCollapsed,
            collapseStyle: note.collapseStyle
        )
    }

    public func bringAllToFront() {
        if activeControllers.isEmpty {
            if let first = notes.first {
                openFloatingNote(first)
            } else {
                createNewNote()
            }
        } else {
            for (_, controller) in activeControllers {
                controller.panel?.makeKeyAndOrderFront(nil)
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    public func openBoard() {
        BoardWindowController.shared.show(
            with: BoardView(
                notes: notes,
                onNewNote: { self.createNewNote() },
                onOpenFloatingNote: { self.openFloatingNote($0) },
                onDeleteNote: { self.deleteNote($0) },
                onArchiveNote: { self.archiveNote($0) }
            )
        )
    }

    public func openSettings() {
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 200, y: 200, width: 480, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "Petal Settings"
        settingsWindow.center()
        settingsWindow.contentView = NSHostingView(
            rootView: SettingsView(
                backupService: backupService,
                onBackupNow: {
                    Task {
                        _ = try? await self.backupService.backup(notes: self.notes)
                    }
                },
                onRestoreSnapshot: { id in
                    Task {
                        let restored = (try? await self.backupService.restore(snapshotID: id)) ?? []
                        for r in restored {
                            try? await self.repository.save(r)
                        }
                        await self.loadNotes()
                    }
                }
            )
        )
        settingsWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func toggleQuickOpen() {
        QuickOpenPanelController.shared.toggle(
            with: QuickOpenView(
                notes: notes,
                onSelectNote: { [weak self] note, isCollapsed in
                    var n = note
                    if isCollapsed {
                        n.isCollapsed = true
                    }
                    self?.openFloatingNote(n)
                },
                onExecuteCommand: { [weak self] cmd in
                    self?.executeCommand(cmd)
                },
                onDismiss: {
                    QuickOpenPanelController.shared.hide()
                }
            )
        )
    }

    public func toggleAllNotes() {
        areNotesHidden.toggle()
        for (_, controller) in activeControllers {
            if areNotesHidden {
                controller.panel?.orderOut(nil)
            } else {
                controller.panel?.makeKeyAndOrderFront(nil)
            }
        }
    }

    public func deleteNote(_ id: Note.ID) {
        if let idx = notes.firstIndex(where: { $0.id == id }) {
            notes.remove(at: idx)
        }
        activeControllers[id]?.close()
        activeControllers.removeValue(forKey: id)
        Task {
            try? await repository.delete(id)
        }
    }

    public func archiveNote(_ id: Note.ID) {
        if let idx = notes.firstIndex(where: { $0.id == id }) {
            notes[idx].isArchived = true
            let note = notes[idx]
            Task {
                try? await repository.save(note)
            }
        }
        activeControllers[id]?.close()
        activeControllers.removeValue(forKey: id)
    }

    private func executeCommand(_ cmd: ParsedCommand) {
        switch cmd {
        case let .newNote(title):
            createNewNote(title: title)
        case let .startTimer(minutes):
            createNewNote(title: "\(minutes)m Focus")
            if let first = notes.first {
                let vm = NoteViewModel(
                    note: first,
                    repository: repository,
                    notificationScheduler: notificationScheduler
                )
                vm.startTimer(minutes: minutes)
            }
        case let .createReminder(title, date):
            createNewNote(title: title)
            if let first = notes.first {
                let vm = NoteViewModel(
                    note: first,
                    repository: repository,
                    notificationScheduler: notificationScheduler
                )
                vm.setReminder(date: date, repeatOption: .none)
            }
        case .search:
            break
        }
    }

    private func setupShortcuts() {
        let sc = GlobalShortcutManager.shared
        sc.onNewNote = { [weak self] in self?.createNewNote() }
        sc.onQuickOpen = { [weak self] in self?.toggleQuickOpen() }
        sc.onToggleAllNotes = { [weak self] in self?.toggleAllNotes() }
    }

    private func createSampleNotes() async {
        let sample1 = Note(
            title: "Welcome to Petal 🌸",
            body: "Your soft pastel desk companion.\n- Drag top strip to move anywhere\n- Click collapse to shrink into a neat pill\n- ⌘N to create a note",
            checklist: [
                ChecklistItem(text: "Try out a focus timer", isDone: false),
                ChecklistItem(text: "Set a gentle reminder", isDone: true),
                ChecklistItem(text: "Record a quick voice note", isDone: false)
            ],
            color: .butter,
            frameX: 180,
            frameY: 420
        )

        let sample2 = Note(
            title: "Focus Time",
            body: "Deep work session on native Mac architecture.",
            color: .mint,
            frameX: 460,
            frameY: 420,
            timerSession: TimerSession(durationMinutes: 25, endDate: Date().addingTimeInterval(25 * 60))
        )

        let sample3 = Note(
            title: "Ideas & Scraps",
            body: "A sticky note app that looks like a desk, not a utility.",
            color: .lavender,
            frameX: 740,
            frameY: 420
        )

        for s in [sample1, sample2, sample3] {
            notes.append(s)
            try? await repository.save(s)
        }
    }
}
