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
        case .reminders: return "bell.fill"
        case .labels: return "square.and.pencil"
        case .archives: return "archivebox.fill"
        case .trash: return "trash.fill"
        }
    }
}

public struct BoardView: View {
    public var notes: [Note]
    public var onNewNote: () -> Void
    public var onOpenFloatingNote: (Note) -> Void
    public var onDeleteNote: (Note.ID) -> Void
    public var onArchiveNote: (Note.ID) -> Void
    public var onPinNote: ((Note.ID) -> Void)?
    public var onChangeColor: ((Note.ID, NoteColor) -> Void)?
    public var onOpenSettings: (() -> Void)?

    @State private var selectedSidebarItem: BoardSidebarItem = .allNotes
    @State private var searchText: String = ""
    @State private var filterColor: String?
    @State private var isGridView: Bool = true
    @State private var hoveredCardID: Note.ID?
    @State private var currentTimeString: String = ""

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    public init(
        notes: [Note],
        onNewNote: @escaping () -> Void,
        onOpenFloatingNote: @escaping (Note) -> Void,
        onDeleteNote: @escaping (Note.ID) -> Void,
        onArchiveNote: @escaping (Note.ID) -> Void,
        onPinNote: ((Note.ID) -> Void)? = nil,
        onChangeColor: ((Note.ID, NoteColor) -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.notes = notes
        self.onNewNote = onNewNote
        self.onOpenFloatingNote = onOpenFloatingNote
        self.onDeleteNote = onDeleteNote
        self.onArchiveNote = onArchiveNote
        self.onPinNote = onPinNote
        self.onChangeColor = onChangeColor
        self.onOpenSettings = onOpenSettings
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
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let lower = trimmed.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(lower) ||
                    $0.body.lowercased().contains(lower) ||
                    $0.folder.lowercased().contains(lower) ||
                    $0.checklist.contains { $0.text.lowercased().contains(lower) }
            }
        }

        return result
    }

    private func count(for item: BoardSidebarItem) -> Int {
        switch item {
        case .allNotes:
            return notes.filter { !$0.isArchived && !$0.isTrash }.count
        case .reminders:
            return notes.filter { $0.hasActiveReminder && !$0.isTrash }.count
        case .labels:
            return notes.filter { !$0.isTrash }.count
        case .archives:
            return notes.filter { $0.isArchived && !$0.isTrash }.count
        case .trash:
            return notes.filter { $0.isTrash }.count
        }
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar matching designs/1.png
            sidebarSection
                .frame(width: 200)
                .background(Color(hex: "#F1F5F9"))

            Divider()
                .opacity(0.12)

            // Right Main Content matching designs/1.png
            VStack(spacing: 0) {
                // Top Global Bar (Search, Date/Time, Icons)
                topGlobalBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // Subheader Bar (Notes title with purple accent pill + New Note button)
                notesHeaderBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)

                // Filter & View Toggle Bar
                filterAndToggleBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // Main Masonry Canvas or List
                ScrollView(.vertical, showsIndicators: true) {
                    if filteredNotes.isEmpty {
                        emptyBoardView
                            .padding(.top, 60)
                    } else if isGridView {
                        masonryGrid(filteredNotes)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 30)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredNotes) { note in
                                boardNoteListRow(note: note)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 30)
                    }
                }
            }
            .background(Color(hex: "#F8FAFC"))
        }
        .frame(minWidth: 920, minHeight: 640)
        .onAppear {
            updateTime()
        }
        .onReceive(timer) { _ in
            updateTime()
        }
    }

    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm   d MMM"
        currentTimeString = formatter.string(from: Date())
    }

    // MARK: - Sidebar matching designs/1.png

    private var sidebarSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Logo Badge matching designs/1.png
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#2563EB"), Color(hex: "#1D4ED8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.blue.opacity(0.25), radius: 4, y: 2)

                    Text("🌸")
                        .font(.system(size: 18))
                }

                Text("Petal")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#0F172A"))

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
            .padding(.bottom, 24)

            // Sidebar navigation items
            VStack(spacing: 4) {
                ForEach(BoardSidebarItem.allCases) { item in
                    let isSelected = selectedSidebarItem == item
                    Button(action: {
                        selectedSidebarItem = item
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? Color(hex: "#2563EB") : Color(hex: "#64748B"))
                                .frame(width: 20)

                            Text(item.rawValue)
                                .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                                .foregroundColor(isSelected ? Color(hex: "#0F172A") : Color(hex: "#475569"))

                            Spacer()

                            let c = count(for: item)
                            if c > 0 {
                                Text("\(c)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(isSelected ? Color(hex: "#2563EB") : Color(hex: "#94A3B8"))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1.5)
                                    .background(isSelected ? Color.blue.opacity(0.12) : Color.black.opacity(0.04))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? Color.white : Color.clear
                        )
                        .cornerRadius(10)
                        .shadow(color: isSelected ? Color.black.opacity(0.05) : Color.clear, radius: 4, y: 1.5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Bottom subtle indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("Mac Storage Synced")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#64748B"))
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
    }

    // MARK: - Top Global Bar matching designs/1.png

    private var topGlobalBar: some View {
        HStack(spacing: 16) {
            // Search for note input pill
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#94A3B8"))

                TextField("Search for note...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, design: .rounded))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#94A3B8"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .frame(maxWidth: 320)

            Spacer()

            // Date & Time
            Text(currentTimeString.isEmpty ? Date().formatted(date: .abbreviated, time: .shortened) : currentTimeString)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#64748B"))

            // Notification Bell
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#64748B"))
                    .frame(width: 28, height: 28)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
            }
            .buttonStyle(.plain)

            // Settings Gear
            Button(action: { onOpenSettings?() }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#64748B"))
                    .frame(width: 28, height: 28)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 2, y: 1)
            }
            .buttonStyle(.plain)
            .help("Petal Settings")

            // Mascot Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "#FFF3B0"))
                    .frame(width: 30, height: 30)
                    .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))

                MascotFaceView(mood: .awake, tint: Color(hex: "#1E293B"), size: 18)
            }
        }
    }

    // MARK: - Notes Header Bar matching designs/1.png

    private var notesHeaderBar: some View {
        HStack(alignment: .center) {
            // Vertical Purple Accent Pill + Title "Notes"
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#8B5CF6"))
                    .frame(width: 6, height: 22)

                Text(selectedSidebarItem == .allNotes ? "Notes" : selectedSidebarItem.rawValue)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "#0F172A"))
            }

            Spacer()

            // "+ New Note" Primary Blue Button matching designs/1.png
            Button(action: onNewNote) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .bold))
                    Text("New Note")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "#2563EB"), Color(hex: "#1D4ED8")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(10)
                .shadow(color: Color(hex: "#2563EB").opacity(0.3), radius: 6, y: 2)
            }
            .buttonStyle(.plain)
            .help("Create a new note (⌘N)")
        }
    }

    // MARK: - Filter & View Toggle Bar matching designs/1.png

    private var filterAndToggleBar: some View {
        HStack(spacing: 12) {
            // Secondary search by title, labels
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "#94A3B8"))

                TextField("Search by title, labels...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .rounded))
            }
            .frame(maxWidth: 240)

            Spacer()

            // Filter Dropdown
            Menu {
                Button("All Colors") { filterColor = nil }
                Divider()
                ForEach(NoteColor.presets) { preset in
                    Button(action: { filterColor = preset.hex }) {
                        HStack {
                            Circle().fill(Color(hex: preset.hex)).frame(width: 8, height: 8)
                            Text(preset.name ?? preset.hex)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(filterColor == nil ? "Filter" : "Filtered")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(filterColor != nil ? Color.blue : Color(hex: "#475569"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
            }

            // Grid / List Toggle matching designs/1.png
            HStack(spacing: 2) {
                Button(action: { isGridView = false }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(!isGridView ? Color(hex: "#0F172A") : Color(hex: "#94A3B8"))
                        .frame(width: 28, height: 26)
                        .background(!isGridView ? Color.white : Color.clear)
                        .cornerRadius(6)
                        .shadow(color: !isGridView ? Color.black.opacity(0.06) : Color.clear, radius: 2, y: 1)
                }
                .buttonStyle(.plain)

                Button(action: { isGridView = true }) {
                    Image(systemName: "rectangle.grid.2x2")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isGridView ? Color(hex: "#0F172A") : Color(hex: "#94A3B8"))
                        .frame(width: 28, height: 26)
                        .background(isGridView ? Color.white : Color.clear)
                        .cornerRadius(6)
                        .shadow(color: isGridView ? Color.black.opacity(0.06) : Color.clear, radius: 2, y: 1)
                }
                .buttonStyle(.plain)
            }
            .padding(2)
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)
        }
    }

    // MARK: - Masonry Grid Layout matching designs/1.png

    private func masonryGrid(_ notes: [Note]) -> some View {
        GeometryReader { proxy in
            let availableWidth = proxy.size.width
            let colCount = max(2, min(4, Int(availableWidth / 220)))
            let columns = splitIntoColumns(notes: notes, columnCount: colCount)

            HStack(alignment: .top, spacing: 16) {
                ForEach(0 ..< colCount, id: \.self) { c in
                    LazyVStack(spacing: 16) {
                        ForEach(columns[c]) { note in
                            boardNoteCard(note: note)
                        }
                    }
                }
            }
        }
        .frame(minHeight: 500)
    }

    private func splitIntoColumns(notes: [Note], columnCount: Int) -> [[Note]] {
        var cols = Array(repeating: [Note](), count: columnCount)
        for (i, note) in notes.enumerated() {
            cols[i % columnCount].append(note)
        }
        return cols
    }

    // MARK: - Board Note Card matching designs/1.png

    private func boardNoteCard(note: Note) -> some View {
        let isHovered = hoveredCardID == note.id
        let bg = Color(hex: note.color.hex)
        let textColor = Color(hex: "#0F172A")

        return VStack(alignment: .leading, spacing: 8) {
            // Title & Pin
            HStack(alignment: .top) {
                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                    .foregroundColor(textColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.orange)
                } else if isHovered {
                    Button(action: { onPinNote?(note.id) }) {
                        Image(systemName: "pin")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "#64748B"))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Tag Pill matching designs/1.png
            HStack(spacing: 5) {
                let tagText = !note.checklist.isEmpty ? "Task" : (note.hasActiveReminder ? "Reminder" : note.folder)
                Text(tagText)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#334155"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(5)

                if note.hasActiveTimer, let timer = note.timerSession {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        HStack(spacing: 3) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 8.5))
                            Text(timer.formattedRemaining(at: context.date))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Color.blue.opacity(0.12))
                        .cornerRadius(5)
                    }
                }

                Spacer()
            }

            // Body text or Checklist matching designs/1.png
            if !note.checklist.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(note.checklist.prefix(6)) { item in
                        HStack(spacing: 6) {
                            // Rounded squircle checkbox
                            RoundedRectangle(cornerRadius: 4.5)
                                .strokeBorder(Color.black.opacity(0.2), lineWidth: 1.2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4.5)
                                        .fill(item.isDone ? Color(hex: "#2EB872") : Color.white.opacity(0.65))
                                )
                                .frame(width: 14, height: 14)
                                .overlay(
                                    item.isDone ? Image(systemName: "checkmark")
                                        .font(.system(size: 7.5, weight: .heavy))
                                        .foregroundColor(.white) : nil
                                )

                            Text(item.text.isEmpty ? "Task" : item.text)
                                .font(.system(size: 11.5, design: .rounded))
                                .foregroundColor(item.isDone ? textColor.opacity(0.4) : textColor.opacity(0.9))
                                .strikethrough(item.isDone, color: textColor.opacity(0.35))
                                .lineLimit(1)
                        }
                    }
                    if note.checklist.count > 6 {
                        Text("+ \(note.checklist.count - 6) more tasks")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(textColor.opacity(0.5))
                            .padding(.top, 2)
                    }
                }
            } else if !note.body.isEmpty {
                Text(note.body)
                    .font(.system(size: 12, design: .rounded))
                    .lineSpacing(3)
                    .foregroundColor(textColor.opacity(0.85))
                    .lineLimit(6)
            }

            // Bottom toolbar matching designs/1.png
            HStack(spacing: 10) {
                if isHovered {
                    // Reminder bell
                    Image(systemName: note.hasActiveReminder ? "bell.fill" : "bell")
                        .font(.system(size: 11))
                        .foregroundColor(note.hasActiveReminder ? .orange : textColor.opacity(0.5))

                    // Color palette
                    Menu {
                        ForEach(NoteColor.presets) { color in
                            Button(color.name ?? color.hex) {
                                onChangeColor?(note.id, color)
                            }
                        }
                    } label: {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)

                    // Archive / Delete
                    Button(action: { onArchiveNote(note.id) }) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Archive note")

                    Button(action: { onDeleteNote(note.id) }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(textColor.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Move to trash")
                }

                Spacer()

                // Floating Sticky Pop-out Button
                Button(action: { onOpenFloatingNote(note) }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.forward.app.fill")
                            .font(.system(size: 9.5))
                        Text("Pop out")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(textColor.opacity(0.75))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Open as floating sticky note on desktop")
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(bg)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.8)
        )
        .shadow(
            color: Color.black.opacity(isHovered ? 0.12 : 0.05),
            radius: isHovered ? 12 : 6,
            x: 0,
            y: isHovered ? 4 : 2
        )
        .contentShape(Rectangle())
        .onHover { isHov in
            hoveredCardID = isHov ? note.id : nil
        }
        .onTapGesture {
            onOpenFloatingNote(note)
        }
    }

    // MARK: - List Row View

    private func boardNoteListRow(note: Note) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: note.color.hex))
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(note.title.isEmpty ? "Untitled Note" : note.title)
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(hex: "#0F172A"))

                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(.orange)
                    }
                }

                Text(note.previewSnippet)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(Color(hex: "#64748B"))
                    .lineLimit(1)
            }

            Spacer()

            Text(note.folder)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "#64748B"))
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(Color.black.opacity(0.05))
                .cornerRadius(6)

            Button(action: { onOpenFloatingNote(note) }) {
                Text("Open on Desk")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#2563EB"))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1.5)
        .contentShape(Rectangle())
        .onTapGesture {
            onOpenFloatingNote(note)
        }
    }

    private var emptyBoardView: some View {
        VStack(spacing: 12) {
            Text("🌸")
                .font(.system(size: 36))

            Text("No notes in \(selectedSidebarItem.rawValue)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "#0F172A"))

            Text("Click below to create a new sticky note")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(Color(hex: "#64748B"))

            Button(action: onNewNote) {
                Label("Create Note", systemImage: "plus")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#2563EB"))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }
}
