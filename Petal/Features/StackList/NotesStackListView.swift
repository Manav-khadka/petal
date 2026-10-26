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
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var filterAnimation

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

    private var nonTrashedNotes: [Note] {
        appState.notes.filter { !$0.isTrash && !$0.isArchived }
    }

    private var filteredNotes: [Note] {
        var list = nonTrashedNotes

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
        if !trimmed.isEmpty {
            let lower = trimmed.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(lower) ||
                    $0.body.lowercased().contains(lower) ||
                    $0.folder.lowercased().contains(lower) ||
                    $0.checklist.contains { $0.text.lowercased().contains(lower) }
            }
        }

        // Sort: Pinned first, then newest updated
        return list.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.updatedAt > $1.updatedAt
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerSection
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            // Search & Segmented Filter Bar
            searchAndFiltersSection
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            Divider()
                .opacity(colorScheme == .dark ? 0.15 : 0.10)

            // Notes List
            ScrollView(.vertical, showsIndicators: true) {
                if filteredNotes.isEmpty {
                    emptyStateView
                        .padding(.top, 45)
                        .padding(.bottom, 30)
                } else {
                    LazyVStack(spacing: 7) {
                        ForEach(filteredNotes) { note in
                            noteRowCard(note: note)
                        }
                    }
                    .padding(14)
                }
            }

            Divider()
                .opacity(colorScheme == .dark ? 0.15 : 0.10)

            // Bottom Status & Keyboard Shortcut Bar
            footerBar
        }
        .frame(width: 520, height: 530)
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                Color(nsColor: .windowBackgroundColor)
                    .opacity(colorScheme == .dark ? 0.45 : 0.65)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.20), radius: 28, x: 0, y: 14)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: 8) {
            // Left: Title with cute icon and count badge
            HStack(spacing: 7) {
                Text("🌸")
                    .font(.system(size: 16))

                Text("All Notes")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("\(nonTrashedNotes.count)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6.5)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(Capsule())
            }

            Spacer()

            // Quick actions icon cluster
            HStack(spacing: 4) {
                headerIconButton(
                    icon: "calendar",
                    tooltip: "Master Calendar & Agenda (⌥⌘K)",
                    tint: Color(hex: "#2563EB")
                ) {
                    appState.openCalendar()
                    onDismiss()
                }

                headerIconButton(
                    icon: "capsule",
                    tooltip: "Collapse all notes to desktop pills (⌃⌥C)",
                    tint: .secondary
                ) {
                    appState.collapseAllNotes()
                }

                headerIconButton(
                    icon: "macwindow.on.rectangle",
                    tooltip: "Expand and bring all notes to front (⌃⌥E)",
                    tint: .secondary
                ) {
                    appState.expandAllNotes()
                }

                headerIconButton(
                    icon: "square.split.diagonal.2x2",
                    tooltip: "Cascade notes across the screen",
                    tint: .secondary
                ) {
                    onCascadeNotes()
                }
            }

            Divider()
                .frame(height: 16)
                .opacity(0.3)
                .padding(.horizontal, 2)

            // New Note Button
            Button(action: {
                onNewNote()
                onDismiss()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10.5, weight: .heavy))
                    Text("New Note")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Color.accentColor)
                .clipShape(Capsule())
                .shadow(color: Color.accentColor.opacity(0.25), radius: 3, y: 1)
            }
            .buttonStyle(.plain)
            .help("Create a new note (⌘N)")

            // Close button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 22, height: 22)
                    .background(Color.primary.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Close (Escape)")
        }
    }

    private func headerIconButton(icon: String, tooltip: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 26, height: 26)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    // MARK: - Search & Filters Section

    private var searchAndFiltersSection: some View {
        VStack(spacing: 9) {
            // Modern Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.secondary)

                TextField("Search notes, tasks, ideas...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.primary)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.04))
            .cornerRadius(9)
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 0.8)
            )

            // Segmented Filter Bar
            HStack(spacing: 3) {
                ForEach(NoteStackFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedFilter = filter
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.iconName)
                                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                            Text(filter.rawValue)
                                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSelected ? Color.primary : Color.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            ZStack {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.10))
                                        .matchedGeometryEffect(id: "filterTabPill", in: filterAnimation)
                                }
                            }
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(2.5)
            .background(Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03))
            .cornerRadius(8)
        }
    }

    // MARK: - Note Row Card

    private func noteRowCard(note: Note) -> some View {
        let isHovered = hoveredNoteID == note.id
        let isOpen = appState.activeControllers.keys.contains(note.id)
        let noteBg = Color(hex: note.color.hex)

        return HStack(spacing: 10) {
            // Left color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(noteBg)
                .frame(width: 4, height: 34)
                .shadow(color: noteBg.opacity(0.35), radius: 2, x: 0, y: 0)

            // Title & Snippet
            VStack(alignment: .leading, spacing: 3) {
                // Row 1: Title, Pin, Date, Desk State
                HStack(spacing: 6) {
                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.orange)
                    }

                    Spacer()

                    // Date Tag
                    Text(note.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    // Status Chips
                    if isOpen {
                        HStack(spacing: 3) {
                            if note.isCollapsed {
                                Image(systemName: "capsule.fill")
                                    .font(.system(size: 7))
                                    .foregroundColor(.secondary)
                                Text("Pill")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            } else {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 5, height: 5)
                                Text("On Desk")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#10B981"))
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            note.isCollapsed ? Color.primary.opacity(0.06) : Color.green.opacity(0.12)
                        )
                        .clipShape(Capsule())
                    }
                }

                // Row 2: Checklist Progress or Preview Snippet
                HStack(spacing: 8) {
                    if !note.checklist.isEmpty {
                        let doneCount = note.checklist.filter(\.isDone).count
                        let total = note.checklist.count
                        let progress = Double(doneCount) / Double(max(total, 1))

                        HStack(spacing: 5) {
                            // Mini progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                        .frame(height: 3)
                                    Capsule()
                                        .fill(Color(hex: "#10B981"))
                                        .frame(width: geo.size.width * progress, height: 3)
                                }
                            }
                            .frame(width: 40, height: 3)

                            Text("\(doneCount)/\(total) tasks done")
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    } else if !note.previewSnippet.isEmpty {
                        Text(note.previewSnippet)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Empty note")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary.opacity(0.6))
                            .italic()
                    }

                    Spacer()

                    // Timers & Reminders indicators
                    if let timer = note.timerSession {
                        TimelineView(.periodic(from: .now, by: 1.0)) { context in
                            HStack(spacing: 3) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 8))
                                Text(timer.formattedRemaining(at: context.date))
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Color.blue.opacity(0.10))
                            .clipShape(Capsule())
                        }
                    }

                    if let rem = note.reminder {
                        HStack(spacing: 3) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 8))
                            Text(rem.targetDate.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
            }

            // Quick actions on row hover
            if isHovered {
                HStack(spacing: 3) {
                    rowIconButton(
                        icon: "arrow.up.forward.app",
                        tooltip: "Bring note to front",
                        tint: .primary
                    ) {
                        onSelectNote(note.id)
                    }

                    rowIconButton(
                        icon: note.isCollapsed ? "macwindow.on.rectangle" : "chevron.down",
                        tooltip: note.isCollapsed ? "Expand note" : "Collapse to pill",
                        tint: .secondary
                    ) {
                        onToggleCollapse(note.id)
                    }

                    rowIconButton(
                        icon: "trash",
                        tooltip: "Delete note",
                        tint: .red.opacity(0.85)
                    ) {
                        onDeleteNote(note.id)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7.5)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    isHovered
                        ? Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.07)
                        : Color.primary.opacity(colorScheme == .dark ? 0.05 : 0.03)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isHovered
                        ? Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.12)
                        : Color.primary.opacity(colorScheme == .dark ? 0.06 : 0.04),
                    lineWidth: 0.8
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onHover { isHov in
            withAnimation(.easeInOut(duration: 0.12)) {
                hoveredNoteID = isHov ? note.id : nil
            }
        }
        .onTapGesture {
            onSelectNote(note.id)
        }
        .contextMenu {
            Button {
                onSelectNote(note.id)
            } label: {
                Label("Bring to Front", systemImage: "arrow.up.forward.app")
            }

            Button {
                onToggleCollapse(note.id)
            } label: {
                Label(note.isCollapsed ? "Expand Note" : "Collapse to Pill", systemImage: note.isCollapsed ? "macwindow.on.rectangle" : "capsule")
            }

            Divider()

            Button(role: .destructive) {
                onDeleteNote(note.id)
            } label: {
                Label("Delete Note", systemImage: "trash")
            }
        }
    }

    private func rowIconButton(icon: String, tooltip: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(tint)
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.06))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }

    // MARK: - Footer Status & Keyboard Bar

    private var footerBar: some View {
        let onDeskCount = nonTrashedNotes.filter { appState.activeControllers.keys.contains($0.id) && !$0.isCollapsed }.count
        let pillCount = nonTrashedNotes.filter { $0.isCollapsed }.count

        return HStack {
            HStack(spacing: 5) {
                Text("\(filteredNotes.count) of \(nonTrashedNotes.count) notes")
                Text("•")
                    .opacity(0.35)
                Text("\(onDeskCount) on desk")
                if pillCount > 0 {
                    Text("•")
                        .opacity(0.35)
                    Text("\(pillCount) pills")
                }
            }
            .font(.system(size: 10.5, design: .rounded))
            .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 7) {
                shortcutBadge(key: "↵", label: "Open")
                shortcutBadge(key: "⌘N", label: "New")
                shortcutBadge(key: "⌥⌘K", label: "Agenda")
                shortcutBadge(key: "⎋", label: "Close")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(colorScheme == .dark ? 0.04 : 0.02))
    }

    private func shortcutBadge(key: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(3.5)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundColor(.secondary.opacity(0.5))

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
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
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
