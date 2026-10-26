import PetalKit
import SwiftUI

public struct ReminderPopoverView: View {
    @Bindable var viewModel: NoteViewModel
    @State private var selectedDate = Date().addingTimeInterval(3600)
    @State private var repeatOption: Reminder.RepeatOption = .none

    public init(viewModel: NoteViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                Text("Set Reminder")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if viewModel.note.reminder != nil {
                    Button("Clear") {
                        viewModel.clearReminder()
                        viewModel.activePopover = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
                }
            }

            // Quick Chips
            HStack(spacing: Spacing.xs) {
                quickChip("In 1 hr", offset: 3600)
                quickChip("Tonight", hour: 20)
                quickChip("Tomorrow 9am", days: 1, hour: 9)
            }

            DatePicker("Date & Time", selection: $selectedDate)
                .datePickerStyle(.compact)
                .labelsHidden()

            Picker("Repeat", selection: $repeatOption) {
                ForEach(Reminder.RepeatOption.allCases, id: \.self) { opt in
                    Text(opt.rawValue).tag(opt)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()
                Button("Done") {
                    viewModel.setReminder(date: selectedDate, repeatOption: repeatOption)
                    viewModel.activePopover = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding(Spacing.m)
        .frame(width: 270)
        .onAppear {
            if let existing = viewModel.note.reminder {
                selectedDate = existing.targetDate
                repeatOption = existing.repeatOption
            }
        }
    }

    private func quickChip(_ title: String, offset: TimeInterval? = nil, days: Int = 0, hour: Int? = nil) -> some View {
        Button(action: {
            var date = Date()
            if let offset = offset {
                date = date.addingTimeInterval(offset)
            } else if let hour = hour {
                var comp = Calendar.current.dateComponents([.year, .month, .day], from: date)
                comp.day = (comp.day ?? 0) + days
                comp.hour = hour
                comp.minute = 0
                if let d = Calendar.current.date(from: comp) {
                    date = d
                }
            }
            selectedDate = date
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.12))
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
