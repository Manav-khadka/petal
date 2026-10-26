import PetalKit
import SwiftUI

public enum BoardSidebarItem: String, CaseIterable, Identifiable {
    case allNotes = "All Notes"
    case reminders = "Reminders"
    case labels = "Edit Labels"
    case archives = "Archives"
    case trash = "Trash"

    public var id: String {
        rawValue
    }

    public var iconName: String {
        switch self {
        case .allNotes: return "note.text"
        case .reminders: return "bell"
        case .labels: return "square.and.pencil"
        case .archives: return "archivebox"
        case .trash: return "trash"
        }
    }
}

public struct BoardView: View {
    public var notes: [Note]
    public var onNewNote: () -> Void
    public var onOpenFloatingNote: (Note) -> Void
    public var onDeleteNote: (Note.ID) -> Void
    public var onArchiveNote: (Note.ID) -> Void

    @State private var selectedSidebarItem: BoardSidebarItem = .allNotes
    @State private var searchText: String = ""
    @State private var filterColor: String?
    @State private var isGridView: Bool = true

    public init(
        notes: [Note],
        onNewNote: @escaping () -> Void,
        onOpenFloatingNote: @escaping (Note) -> Void,
        onDeleteNote: @escaping (Note.ID) -> Void,
        onArchiveNote: @escaping (Note.ID) -> Void
    ) {
        self.notes = notes
        self.onNewNote = onNewNote
        self.onOpenFloatingNote = onOpenFloatingNote
        self.onDeleteNote = onDeleteNote
        self.onArchiveNote = onArchiveNote
    }

    private var filteredNotes: [Note] {
        var result = notes

        // Sidebar filter
        switch selectedSidebarItem {
        case .allNotes:
            result = result.filter { !$0.isArchived && !$0.isTrash }
        case .reminders:
            result = result.filter { $0.hasActiveReminder && !$0.isTrash }
        case .labels:
            result = result.filter { !$0.isTrash }
        case .archives:
            result = result.filter { $0.isArchived && !$0.isTrash }
        case .trash:
            result = result.filter { $0.isTrash }
        }

        // Color filter
        if let colorHex = filterColor {
            result = result.filter { $0.color.hex == colorHex }
        }

        // Search text
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let lower = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(lower) ||
                    $0.body.lowercased().contains(lower) ||
                    $0.checklist.contains { $0.text.lowercased().contains(lower) }
            }
        }

        return result
    }

    public var body: some View {
        NavigationSplitView {
            // Sidebar matching design 1.png
            List(BoardSidebarItem.allCases, selection: $selectedSidebarItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: item.iconName)
                        .font(.system(.body, design: .rounded))
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 190, max: 240)
        } detail: {
            VStack(spacing: 0) {
                // Top bar matching design 1.png
                topBar

                Divider()

                // Subheader with filter & search
                subHeaderBar

                // Notes Canvas / Masonry Grid
                ScrollView {
                    if isGridView {
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 220, maximum: 260), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(filteredNotes) { note in
                                boardNoteCard(note: note)
                            }
                        }
                        .padding(20)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotes) { note in
                                boardNoteListRow(note: note)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(Color(hex: "#F8FAFC"))
        }
        .frame(minWidth: 840, minHeight: 560)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search for note...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .rounded))

            Spacer()

            Text(Date().formatted(date: .abbreviated, time: .shortened))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Button(action: onNewNote) {
                Label("New Note", systemImage: "plus")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var subHeaderBar: some View {
        HStack {
            Text(selectedSidebarItem.rawValue)
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Spacer()

            // Filter menu by Color
            Menu {
                Button("All Colors") { filterColor = nil }
                Divider()
                ForEach(NoteColor.presets) { preset in
                    Button(preset.name ?? preset.hex) {
                        filterColor = preset.hex
                    }
                }
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 12, design: .rounded))
            }

            // Grid vs List View Toggle
            HStack(spacing: 2) {
                Button(action: { isGridView = false }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 12))
                        .padding(5)
                        .background(!isGridView ? Color.black.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { isGridView = true }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 12))
                        .padding(5)
                        .background(isGridView ? Color.black.opacity(0.1) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func boardNoteCard(note: Note) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#1E293B"))
                    .lineLimit(1)

                Spacer()

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            // Folder tag pill
            Text(note.folder)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.white.opacity(0.6))
                .cornerRadius(6)

            // Body or checklist
            if !note.checklist.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(note.checklist.prefix(3)) { item in
                        HStack(spacing: 4) {
                            Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                                .font(.system(size: 11))
                                .foregroundColor(item.isDone ? .green : .secondary)
                            Text(item.text)
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(.primary.opacity(0.85))
                                .strikethrough(item.isDone)
                                .lineLimit(1)
                        }
                    }
                }
            } else {
                Text(note.body)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(Color(hex: "#334155"))
                    .lineLimit(4)
            }

            Spacer(minLength: 8)

            // Card bottom actions
            HStack(spacing: 8) {
                if note.hasActiveReminder {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
                if note.hasVoiceNote {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.purple)
                }
                if note.hasActiveTimer {
                    Image(systemName: "hourglass")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                }

                Spacer()

                Button("Open") {
                    onOpenFloatingNote(note)
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
        }
        .padding(14)
        .frame(minHeight: 160)
        .background(Color(hex: note.color.hex))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        .onTapGesture {
            onOpenFloatingNote(note)
        }
    }

    private func boardNoteListRow(note: Note) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: note.color.hex))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                Text(note.previewSnippet)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(note.folder)
                .font(.system(size: 10, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)

            Button("Open") {
                onOpenFloatingNote(note)
            }
            .buttonStyle(.plain)
            .foregroundColor(.blue)
            .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
    }
}
