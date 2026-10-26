import PetalKit
import SwiftUI

public enum CalendarScope: String, CaseIterable, Identifiable {
    case selectedDate = "Selected Date"
    case upcoming = "Upcoming (Future)"
    case past = "Past / History"
    case allTime = "All Items"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .selectedDate: return "calendar"
        case .upcoming: return "clock.arrow.circlepath"
        case .past: return "clock.badge.checkmark"
        case .allTime: return "tray.full"
        }
    }
}

public enum CalendarTypeFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case reminders = "Reminders"
    case tasks = "Tasks"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .reminders: return "bell.badge.fill"
        case .tasks: return "checklist"
        }
    }
}

public struct CalendarView: View {
    @Bindable var appState: AppState
    public var onOpenNote: (Note.ID) -> Void

    @State private var selectedDate: Date = Date()
    @State private var selectedScope: CalendarScope = .selectedDate
    @State private var selectedType: CalendarTypeFilter = .all
    @State private var searchText: String = ""
    @State private var newTaskText: String = ""
    @State private var isCreatingTask: Bool = false

    public init(appState: AppState, onOpenNote: @escaping (Note.ID) -> Void) {
        self.appState = appState
        self.onOpenNote = onOpenNote
    }

    private var allAgendaItems: [AgendaItem] {
        appState.notes.agendaItems()
    }

    private var scopedItems: [AgendaItem] {
        let calendar = Calendar.current
        let now = Date()

        let base: [AgendaItem]
        switch selectedScope {
        case .selectedDate:
            base = appState.notes.agendaItems(for: selectedDate, calendar: calendar)
        case .upcoming:
            base = appState.notes.upcomingAgendaItems(from: now)
        case .past:
            base = appState.notes.pastAgendaItems(from: now)
        case .allTime:
            base = allAgendaItems
        }

        // Type filter
        let typeFiltered: [AgendaItem]
        switch selectedType {
        case .all:
            typeFiltered = base
        case .reminders:
            typeFiltered = base.filter { $0.type == .reminder || $0.type == .alarm }
        case .tasks:
            typeFiltered = base.filter { $0.type == .task }
        }

        // Search text
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return typeFiltered }

        return typeFiltered.filter {
            $0.title.lowercased().contains(query) ||
                $0.noteTitle.lowercased().contains(query)
        }
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar: Calendar Picker & Controls
            sidebarView
                .frame(width: 310)
                .background(Color(nsColor: .windowBackgroundColor))

            Divider()
                .opacity(0.15)

            // Right Area: Timeline, Reminders & Tasks
            mainTimelineView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .frame(minWidth: 780, minHeight: 520)
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title Header with Mascot
            HStack(spacing: 8) {
                MascotFaceView(mood: .awake, tint: Color(hex: "#2C2D30"), size: 22)
                Text("Calendar & Agenda")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Button(action: {
                    selectedDate = Date()
                    selectedScope = .selectedDate
                }) {
                    Text("Today")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Jump to Today")
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)

            // Graphical Month Picker
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()
            .padding(.horizontal, 10)
            .onChange(of: selectedDate) { _, _ in
                if selectedScope != .selectedDate {
                    selectedScope = .selectedDate
                }
            }

            // Scope Selector List
            VStack(spacing: 3) {
                ForEach(CalendarScope.allCases) { scope in
                    Button(action: { selectedScope = scope }) {
                        HStack(spacing: 8) {
                            Image(systemName: scope.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(selectedScope == scope ? .white : .secondary)
                                .frame(width: 20)

                            Text(scope.rawValue)
                                .font(.system(size: 12.5, weight: selectedScope == scope ? .bold : .medium, design: .rounded))
                                .foregroundColor(selectedScope == scope ? .white : .primary)

                            Spacer()

                            // Item count badge for this scope
                            let count = countForScope(scope)
                            if count > 0 {
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(selectedScope == scope ? Color.white.opacity(0.25) : Color.black.opacity(0.06))
                                    .foregroundColor(selectedScope == scope ? .white : .secondary)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selectedScope == scope ? Color.accentColor : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Summary Stats Pill at Bottom
            sidebarStatsBadge
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
        }
    }

    private var sidebarStatsBadge: some View {
        let totalTasks = allAgendaItems.filter { $0.type == .task }
        let completedTasks = totalTasks.filter(\.isCompleted).count
        let activeReminders = allAgendaItems.filter { $0.type == .reminder && !$0.isCompleted }.count

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 9.5))
                    .foregroundColor(.orange)
                Text("\(activeReminders) active reminder\(activeReminders == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }

            HStack(spacing: 5) {
                Image(systemName: "checklist")
                    .font(.system(size: 9.5))
                    .foregroundColor(Color(hex: "#22C55E"))
                Text("\(completedTasks) of \(totalTasks.count) tasks done")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func countForScope(_ scope: CalendarScope) -> Int {
        let now = Date()
        let cal = Calendar.current
        switch scope {
        case .selectedDate:
            return allAgendaItems.filter { cal.isDate($0.date, inSameDayAs: selectedDate) }.count
        case .upcoming:
            return allAgendaItems.filter { $0.date >= now && !$0.isCompleted }.count
        case .past:
            return allAgendaItems.filter { $0.date < now || $0.isCompleted }.count
        case .allTime:
            return allAgendaItems.count
        }
    }

    // MARK: - Main Timeline View

    private var mainTimelineView: some View {
        VStack(spacing: 0) {
            // Top Toolbar: Search & Type Filter Tabs
            HStack(spacing: 12) {
                // Header Label
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleForScope)
                        .font(.system(size: 18, weight: .bold, design: .rounded))

                    Text(subtitleForScope)
                        .font(.system(size: 11.5, design: .rounded))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Type Filter Pills
                HStack(spacing: 4) {
                    ForEach(CalendarTypeFilter.allCases) { filter in
                        Button(action: { selectedType = filter }) {
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: selectedType == filter ? .bold : .medium, design: .rounded))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(selectedType == filter ? Color.accentColor : Color.primary.opacity(0.06))
                                .foregroundColor(selectedType == filter ? .white : .primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Search Bar
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    TextField("Search tasks & reminders...", text: $searchText)
                        .font(.system(size: 12, design: .rounded))
                        .textFieldStyle(.plain)
                        .frame(width: 140)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4.5)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .opacity(0.12)

            // Items List
            ScrollView(.vertical, showsIndicators: true) {
                if scopedItems.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 10) {
                        // Quick Add Row
                        quickTaskInputRow

                        ForEach(scopedItems) { item in
                            agendaItemCard(item: item)
                        }
                    }
                    .padding(18)
                }
            }
        }
    }

    private var titleForScope: String {
        switch selectedScope {
        case .selectedDate:
            if Calendar.current.isDateInToday(selectedDate) {
                return "Today"
            }
            return selectedDate.formatted(date: .complete, time: .omitted)
        case .upcoming:
            return "Upcoming Schedule"
        case .past:
            return "Past & Completed History"
        case .allTime:
            return "All Notes & Agenda"
        }
    }

    private var subtitleForScope: String {
        let count = scopedItems.count
        return "\(count) item\(count == 1 ? "" : "s") found"
    }

    // MARK: - Quick Add Row

    private var quickTaskInputRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.accentColor)

            TextField("Add a new task for this date...", text: $newTaskText)
                .font(.system(size: 13, design: .rounded))
                .textFieldStyle(.plain)
                .onSubmit {
                    createQuickTask()
                }

            if !newTaskText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Add Task") {
                    createQuickTask()
                }
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4)
                .background(Color.accentColor)
                .clipShape(Capsule())
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func createQuickTask() {
        let text = newTaskText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        // Find or create a note for this date
        if let targetNote = appState.notes.first(where: { !$0.isTrash && !$0.isArchived }) {
            if let vm = appState.activeViewModels[targetNote.id] {
                vm.addChecklistItem(text: text)
            } else if let idx = appState.notes.firstIndex(where: { $0.id == targetNote.id }) {
                appState.notes[idx].checklist.append(ChecklistItem(text: text, isDone: false))
                Task {
                    try? await appState.repository.save(appState.notes[idx])
                }
            }
        } else {
            appState.createNewNote(title: "My Tasks")
            if let first = appState.notes.first {
                appState.activeViewModels[first.id]?.addChecklistItem(text: text)
            }
        }

        newTaskText = ""
    }

    // MARK: - Agenda Item Card

    private func agendaItemCard(item: AgendaItem) -> some View {
        let noteColor = Color(hex: item.noteColor.hex)
        let isDarkText = item.noteColor.requiresDarkText

        return HStack(spacing: 10) {
            // Checkbox or Type Icon
            if item.type == .task, let taskID = item.checklistItemID {
                Button(action: {
                    toggleTaskCompletion(noteID: item.noteID, taskID: taskID)
                }) {
                    ZStack {
                        if item.isCompleted {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#22C55E"), Color(hex: "#16A34A")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 18, height: 18)
                                .shadow(color: Color(hex: "#16A34A").opacity(0.35), radius: 2, y: 1)

                            Image(systemName: "checkmark")
                                .font(.system(size: 9.5, weight: .heavy))
                                .foregroundColor(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1.2)
                                .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.primary.opacity(0.06)))
                                .frame(width: 18, height: 18)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else if item.type == .reminder {
                Image(systemName: item.isCompleted ? "bell.slash.fill" : "bell.badge.fill")
                    .font(.system(size: 14))
                    .foregroundColor(item.isCompleted ? .secondary : .orange)
                    .frame(width: 18, height: 18)
            } else if item.type == .alarm {
                Image(systemName: "alarm.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                    .frame(width: 18, height: 18)
            }

            // Title & Timestamp
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .strikethrough(item.isCompleted, color: .secondary.opacity(0.6))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    // Type Badge
                    Text(item.type.title)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(typeBadgeBg(item.type))
                        .foregroundColor(typeBadgeFg(item.type))
                        .clipShape(Capsule())

                    // Formatted Date / Time
                    Text(formattedDateTime(item.date))
                        .font(.system(size: 10.5, design: .rounded))
                        .foregroundColor(.secondary)

                    if item.isCompleted {
                        Text("• Completed")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Note Capsule Badge & Jump Button
            Button(action: {
                onOpenNote(item.noteID)
            }) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(noteColor)
                        .frame(width: 7, height: 7)
                        .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))

                    Text(item.noteTitle)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(isDarkText ? Color(hex: "#1C1D21") : Color(hex: "#FAF9F5"))
                        .lineLimit(1)

                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isDarkText ? Color(hex: "#595B65") : Color(hex: "#AEB0B8"))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4.5)
                .background(noteColor.opacity(0.85))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Open '\(item.noteTitle)' on desktop")

            // Reminder Actions (if reminder)
            if item.type == .reminder, let remID = item.reminderID, !item.isCompleted {
                Menu {
                    Button("Mark Completed") {
                        markReminderCompleted(noteID: item.noteID)
                    }
                    Button("Snooze 15 Minutes") {
                        snoozeReminder(noteID: item.noteID, minutes: 15)
                    }
                    Button("Snooze 1 Hour") {
                        snoozeReminder(noteID: item.noteID, minutes: 60)
                    }
                    Divider()
                    Button("Clear Reminder", role: .destructive) {
                        clearReminder(noteID: item.noteID)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 22)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 3, y: 1.5)
    }

    private func typeBadgeBg(_ type: AgendaItemType) -> Color {
        switch type {
        case .reminder: return Color.orange.opacity(0.14)
        case .alarm: return Color.purple.opacity(0.14)
        case .task: return Color.green.opacity(0.14)
        }
    }

    private func typeBadgeFg(_ type: AgendaItemType) -> Color {
        switch type {
        case .reminder: return .orange
        case .alarm: return .purple
        case .task: return Color(hex: "#16A34A")
        }
    }

    private func formattedDateTime(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today at " + date.formatted(date: .omitted, time: .shortened)
        } else if cal.isDateInTomorrow(date) {
            return "Tomorrow at " + date.formatted(date: .omitted, time: .shortened)
        } else if cal.isDateInYesterday(date) {
            return "Yesterday at " + date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    // MARK: - Actions

    private func toggleTaskCompletion(noteID: Note.ID, taskID: UUID) {
        if let vm = appState.activeViewModels[noteID] {
            if let item = vm.note.checklist.first(where: { $0.id == taskID }) {
                vm.toggleChecklist(item: item)
            }
        } else if let idx = appState.notes.firstIndex(where: { $0.id == noteID }) {
            if let taskIdx = appState.notes[idx].checklist.firstIndex(where: { $0.id == taskID }) {
                appState.notes[idx].checklist[taskIdx].isDone.toggle()
                Task {
                    try? await appState.repository.save(appState.notes[idx])
                }
            }
        }
    }

    private func markReminderCompleted(noteID: Note.ID) {
        if let vm = appState.activeViewModels[noteID] {
            vm.note.reminder?.isCompleted = true
            vm.save()
        } else if let idx = appState.notes.firstIndex(where: { $0.id == noteID }) {
            appState.notes[idx].reminder?.isCompleted = true
            Task {
                try? await appState.repository.save(appState.notes[idx])
            }
        }
    }

    private func snoozeReminder(noteID: Note.ID, minutes: Int) {
        let newDate = Date().addingTimeInterval(Double(minutes * 60))
        if let vm = appState.activeViewModels[noteID] {
            vm.setReminder(date: newDate, repeatOption: vm.note.reminder?.repeatOption ?? .none)
        } else if let idx = appState.notes.firstIndex(where: { $0.id == noteID }) {
            appState.notes[idx].reminder?.targetDate = newDate
            appState.notes[idx].reminder?.isCompleted = false
            Task {
                try? await appState.repository.save(appState.notes[idx])
            }
        }
    }

    private func clearReminder(noteID: Note.ID) {
        if let vm = appState.activeViewModels[noteID] {
            vm.clearReminder()
        } else if let idx = appState.notes.firstIndex(where: { $0.id == noteID }) {
            appState.notes[idx].reminder = nil
            Task {
                try? await appState.repository.save(appState.notes[idx])
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            MascotFaceView(mood: .sleeping, tint: .secondary.opacity(0.6), size: 36)

            Text("No reminders or tasks scheduled")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)

            Text("You can create a task or reminder on any note,\nor add a task right above.")
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
