import PetalKit
import SwiftUI

public enum NoteStackFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case open = "On Desk"
    case collapsed = "Pills"
    case tasks = "Checklists"
    case timers = "Timers & Reminders"

    public var id: String {
        rawValue
    }

    public var iconName: String {
        switch self {
        case .all: return "note.text"
        case .open: return "macwindow.on.rectangle"
        case .collapsed: return "capsule"
        case .tasks: return "checklist"
        case .timers: return "hourglass"
        }
    }
}

public struct NotesStackListView: View {
    var appState: AppState = AppState.shared
    public var onSelectNote: (Note.ID) -> Void
    public var onToggleCollapse: (Note.ID) -> Void
    public var onNewNote: () -> Void
    public var onCascadeNotes: () -> Void
    public var onToggleCollapseAll: () -> Void
    public var onDeleteNote: (Note.ID) -> Void
    public var onDismiss: () -> Void

    @State private var searchText: String = ""
    @State private var selectedFilter: NoteStackFilter = .all
    @State private var hoveredNoteID: Note.ID?

    public init(
        notes: [Note] = [],
        activeControllerIDs: Set<Note.ID> = [],
        appState: AppState = AppState.shared,
        onSelectNote: @escaping (Note.ID) -> Void,
        onToggleCollapse: @escaping (Note.ID) -> Void,
        onNewNote: @escaping () -> Void,
        onCascadeNotes: @escaping () -> Void,
        onToggleCollapseAll: @escaping () -> Void,
        onDeleteNote: @escaping (Note.ID) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.appState = appState
        self.onSelectNote = onSelectNote
        self.onToggleCollapse = onToggleCollapse
        self.onNewNote = onNewNote
        self.onCascadeNotes = onCascadeNotes
        self.onToggleCollapseAll = onToggleCollapseAll
        self.onDeleteNote = onDeleteNote
        self.onDismiss = onDismiss
    }

    private var filteredNotes: [Note] {
        var list = appState.notes.filter { !$0.isTrash && !$0.isArchived }

        // Filter tab
        switch selectedFilter {
        case .all:
            break
        case .open:
            list = list.filter { appState.activeControllers.keys.contains($0.id) && !$0.isCollapsed }
        case .collapsed:
            list = list.filter { $0.isCollapsed || (appState.activeControllers.keys.contains($0.id) && $0.isCollapsed) }
        case .tasks:
            list = list.filter { !$0.checklist.isEmpty }
        case .timers:
            list = list.filter { $0.hasActiveTimer || $0.hasActiveReminder }
        }

        // Search text
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return list }
        let lower = trimmed.lowercased()

        return list.filter {
            $0.title.lowercased().contains(lower) ||
                $0.body.lowercased().contains(lower) ||
                $0.folder.lowercased().contains(lower) ||
                $0.checklist.contains { $0.text.lowercased().contains(lower) }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Search & Filters
            searchAndFiltersSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider()
                .opacity(0.12)

            // Notes List
            ScrollView(.vertical, showsIndicators: true) {
                if filteredNotes.isEmpty {
                    emptyStateView
                        .padding(.top, 40)
                        .padding(.bottom, 30)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredNotes) { note in
                            noteRowCard(note: note)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .frame(width: 500, height: 540)
        .background(
            ZStack {
                Color(hex: "#FAF9F5").opacity(0.97)
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.20), radius: 24, x: 0, y: 12)
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Text("🌸")
                    .font(.system(size: 15))

                Text("All Notes")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("\(appState.notes.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            // Calendar & Agenda button
            Button(action: {
                appState.openCalendar()
                onDismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Calendar")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color(hex: "#2563EB"))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Open Master Calendar & Agenda with all tasks and reminders (⌥⌘K)")

            // Collapse All button
            Button(action: {
                appState.collapseAllNotes()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "capsule")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Collapse All")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color(hex: "#4B5563"))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Collapse all open notes to compact pills (⌃⌥C)")

            // See All / Expand All button
            Button(action: {
                appState.expandAllNotes()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 10, weight: .semibold))
                    Text("See All")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color(hex: "#4B5563"))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Expand and bring all open notes to front (⌃⌥E)")

            // Cascade / Unstack notes button
            Button(action: onCascadeNotes) {
                HStack(spacing: 4) {
                    Image(systemName: "square.split.diagonal.2x2")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Unstack")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                }
                .foregroundColor(Color(hex: "#4B5563"))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Cascade and unstack all open notes across the screen")

            // New Note button
            Button(action: {
                onNewNote()
                onDismiss()
            }) {
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

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close (Escape)")
        }
    }

    private var searchAndFiltersSection: some View {
        VStack(spacing: 8) {
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "#6B7280"))

                TextField("Search notes, tasks, ideas...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color(hex: "#1C1D21"))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.92))
            .cornerRadius(9)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
            )

            // Filter Tabs
            HStack(spacing: 6) {
                ForEach(NoteStackFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    Button(action: { selectedFilter = filter }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.iconName)
                                .font(.system(size: 9.5))
                            Text(filter.rawValue)
                                .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .white : Color(hex: "#1C1D21").opacity(0.75))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(
                            isSelected ? Color(hex: "#1C1D21") : Color.black.opacity(0.05)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
        }
    }

    private func noteRowCard(note: Note) -> some View {
        let isHovered = hoveredNoteID == note.id
        let isOpen = appState.activeControllers.keys.contains(note.id)
        let noteBg = Color(hex: note.color.hex)

        return HStack(spacing: 10) {
            // Left color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(noteBg)
                .frame(width: 4, height: 34)

            // Title & Snippet
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#1C1D21"))
                        .lineLimit(1)

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    // Date Tag
                    HStack(spacing: 3) {
                        Image(systemName: "calendar")
                            .font(.system(size: 8.5))
                        Text(note.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color(hex: "#6B7280"))

                    // Status Chips
                    if isOpen {
                        Text(note.isCollapsed ? "Pill" : "On Desk")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(note.isCollapsed ? Color(hex: "#6B7280") : Color(hex: "#2563EB"))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                (note.isCollapsed ? Color.black.opacity(0.06) : Color.blue.opacity(0.12))
                            )
                            .clipShape(Capsule())
                    }
                }

                // Snippet or task progress
                if !note.checklist.isEmpty {
                    let doneCount = note.checklist.filter(\.isDone).count
                    HStack(spacing: 4) {
                        Image(systemName: "checklist")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "#2EB872"))
                        Text("\(doneCount) of \(note.checklist.count) tasks done")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                } else if !note.previewSnippet.isEmpty {
                    Text(note.previewSnippet)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(1)
                }

                // Timers & Reminders indicators
                if note.hasActiveTimer || note.hasActiveReminder {
                    HStack(spacing: 6) {
                        if let timer = note.timerSession {
                            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                                HStack(spacing: 3) {
                                    Image(systemName: "hourglass")
                                        .font(.system(size: 9))
                                    Text(timer.formattedRemaining(at: context.date))
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                }
                                .foregroundColor(.blue)
                            }
                        }

                        if let rem = note.reminder {
                            HStack(spacing: 3) {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 9))
                                Text(rem.targetDate.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    .padding(.top, 1)
                }
            }

            // Quick actions on row hover
            if isHovered {
                HStack(spacing: 4) {
                    // Bring to front button
                    Button(action: {
                        onSelectNote(note.id)
                    }) {
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#1C1D21"))
                            .frame(width: 24, height: 24)
                            .background(Color.black.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Bring this note to front")

                    // Toggle Collapse button
                    Button(action: {
                        onToggleCollapse(note.id)
                    }) {
                        Image(systemName: note.isCollapsed ? "arrow.up.left.and.arrow.down.right" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(hex: "#4B5563"))
                            .frame(width: 24, height: 24)
                            .background(Color.black.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(note.isCollapsed ? "Expand note" : "Collapse to pill")

                    // Delete button
                    Button(action: {
                        onDeleteNote(note.id)
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                            .frame(width: 24, height: 24)
                            .background(Color.red.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Delete note")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.white : Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovered ? Color.black.opacity(0.12) : Color.black.opacity(0.05), lineWidth: 0.8)
        )
        .contentShape(Rectangle())
        .onHover { isHov in
            hoveredNoteID = isHov ? note.id : nil
        }
        .onTapGesture {
            onSelectNote(note.id)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.6))

            if searchText.isEmpty {
                Text("No notes found in this category")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                Text("No notes matching \"\(searchText)\"")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                Button(action: {
                    onNewNote()
                    onDismiss()
                }) {
                    Text("Create note with this title")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context _: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ visualEffectView: NSVisualEffectView, context _: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
