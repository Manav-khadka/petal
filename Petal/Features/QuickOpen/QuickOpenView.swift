import PetalKit
import SwiftUI

public struct QuickOpenView: View {
    public var notes: [Note]
    public var onSelectNote: (Note, Bool) -> Void // (note, isCollapsed)
    public var onExecuteCommand: (ParsedCommand) -> Void
    public var onDismiss: () -> Void

    @State private var query: String = ""
    @State private var selectedIndex: Int = 0
    @FocusState private var isFieldFocused: Bool

    public init(
        notes: [Note],
        onSelectNote: @escaping (Note, Bool) -> Void,
        onExecuteCommand: @escaping (ParsedCommand) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.notes = notes
        self.onSelectNote = onSelectNote
        self.onExecuteCommand = onExecuteCommand
        self.onDismiss = onDismiss
    }

    private var filteredNotes: [Note] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return Array(notes.prefix(6))
        }
        let lower = query.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(lower) ||
                $0.body.lowercased().contains(lower) ||
                $0.checklist.contains { $0.text.lowercased().contains(lower) }
        }
    }

    private var detectedCommand: ParsedCommand? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let cmd = SchedulingService.parseCommand(trimmed)
        if case .search = cmd {
            return nil
        }
        return cmd
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Pill
            HStack(spacing: Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)

                TextField("Search notes or type 'new', 'timer 10m', 'remind 5pm'...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .focused($isFieldFocused)
                    .onSubmit {
                        executeSelection(collapsed: false)
                    }

                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.m)

            // Command Preview Chip if recognized
            if let cmd = detectedCommand {
                Divider()
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                    switch cmd {
                    case let .newNote(title):
                        Text("Create new note: \"\(title.isEmpty ? "Untitled" : title)\"")
                    case let .startTimer(min):
                        Text("Start \(min)-minute timer")
                    case let .createReminder(title, date):
                        Text("Remind \"\(title)\" at \(date.formatted(date: .omitted, time: .shortened))")
                    case .search:
                        EmptyView()
                    }
                    Spacer()
                    Text("Press Enter")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.08))
            }

            // Results List
            if !filteredNotes.isEmpty {
                Divider()
                VStack(spacing: 0) {
                    ForEach(Array(filteredNotes.enumerated()), id: \.element.id) { index, note in
                        let isSelected = index == selectedIndex
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: note.color.hex))
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.title.isEmpty ? "Untitled Note" : note.title)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text(note.previewSnippet)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text(note.folder)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                        }
                        .padding(.horizontal, Spacing.l)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.blue.opacity(0.12) : Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectNote(note, false)
                        }
                    }
                }
            }
        }
        .frame(width: 520)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .background(Color(hex: "#FFFDF5").opacity(0.75))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
        .onAppear {
            isFieldFocused = true
        }
    }

    private func executeSelection(collapsed: Bool) {
        if let cmd = detectedCommand {
            onExecuteCommand(cmd)
            onDismiss()
            return
        }
        if selectedIndex < filteredNotes.count {
            onSelectNote(filteredNotes[selectedIndex], collapsed)
            onDismiss()
        }
    }
}
