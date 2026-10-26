import PetalKit
import SwiftUI

public struct CalendarPopoverView: View {
    @Bindable var viewModel: NoteViewModel
    @State private var selectedDate: Date = Date()
    @State private var reminderHour: Int = 9
    @State private var reminderMinute: Int = 0

    public init(viewModel: NoteViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "#2563EB"))
                    .font(.system(size: 15, weight: .bold))
                Text("Calendar & Dates")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("Today")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .help("Jump to today")
            }

            // Note Timestamp Badges
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Text("Created:")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text(viewModel.note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }

                if viewModel.note.updatedAt > viewModel.note.createdAt.addingTimeInterval(60) {
                    HStack(spacing: 5) {
                        Text("Updated:")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Text(viewModel.note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.04))
            .cornerRadius(8)

            // Graphical Calendar
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .labelsHidden()

            Divider()

            // Reminder Integration for this date
            VStack(alignment: .leading, spacing: 6) {
                if let rem = viewModel.note.reminder {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 12))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Scheduled Reminder")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                            Text(rem.targetDate.formatted(date: .complete, time: .shortened))
                                .font(.system(size: 10.5, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Clear") {
                            viewModel.clearReminder()
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                } else {
                    Button(action: {
                        let cal = Calendar.current
                        var components = cal.dateComponents([.year, .month, .day], from: selectedDate)
                        components.hour = 9
                        components.minute = 0
                        let target = cal.date(from: components) ?? selectedDate
                        viewModel.setReminder(date: target, repeatOption: .none)
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 11))
                            Text("Set Reminder for \(selectedDate.formatted(date: .abbreviated, time: .omitted)) (9 AM)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Footer
            HStack {
                Button(action: {
                    viewModel.activePopover = nil
                    AppState.shared.openCalendar()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                        Text("All Notes Agenda ↗")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "#2563EB"))
                }
                .buttonStyle(.plain)
                .help("Open full master calendar with all tasks and reminders (⌥⌘K)")

                Spacer()
                Button("Done") {
                    viewModel.activePopover = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#2563EB"))
            }
        }
        .padding(Spacing.m)
        .frame(width: 290)
        .onAppear {
            if let reminder = viewModel.note.reminder {
                selectedDate = reminder.targetDate
            } else {
                selectedDate = viewModel.note.createdAt
            }
        }
    }
}
