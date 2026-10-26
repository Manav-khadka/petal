import PetalKit
import SwiftUI

public struct AlarmPopoverView: View {
    @Bindable var viewModel: NoteViewModel
    @State private var selectedHour: Int = 8
    @State private var selectedMinute: Int = 0
    @State private var selectedDays: Set<Int> = []
    @State private var selectedSound: String = "Gentle Chime"

    private let weekdays = [
        (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
    ]

    public init(viewModel: NoteViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            HStack {
                Image(systemName: "alarm.fill")
                    .foregroundColor(.purple)
                Text("Set Alarm")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if viewModel.note.alarm != nil {
                    Button("Clear") {
                        viewModel.clearAlarm()
                        viewModel.activePopover = nil
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
                }
            }

            // Time Picker
            HStack {
                Picker("Hour", selection: $selectedHour) {
                    ForEach(0 ..< 24) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .labelsHidden()
                .frame(width: 60)

                Text(":")
                    .font(.headline)

                Picker("Minute", selection: $selectedMinute) {
                    ForEach(0 ..< 60) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 60)
            }

            // Repeat Weekdays
            VStack(alignment: .leading, spacing: 4) {
                Text("Repeat Days")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    ForEach(weekdays, id: \.0) { day in
                        let isSelected = selectedDays.contains(day.0)
                        Button(action: {
                            if isSelected {
                                selectedDays.remove(day.0)
                            } else {
                                selectedDays.insert(day.0)
                            }
                        }) {
                            Text(day.1)
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 26, height: 26)
                                .background(isSelected ? Color.purple : Color.secondary.opacity(0.15))
                                .foregroundColor(isSelected ? .white : .primary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Sound Picker
            Picker("Sound", selection: $selectedSound) {
                ForEach(SoundPlayer.availableSounds, id: \.self) { sound in
                    Text(sound).tag(sound)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Spacer()
                Button("Done") {
                    viewModel.setAlarm(
                        hour: selectedHour,
                        minute: selectedMinute,
                        repeatDays: Array(selectedDays),
                        soundName: selectedSound
                    )
                    viewModel.activePopover = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
        }
        .padding(Spacing.m)
        .frame(width: 250)
        .onAppear {
            if let existing = viewModel.note.alarm {
                selectedHour = existing.hour
                selectedMinute = existing.minute
                selectedDays = Set(existing.repeatDays)
                selectedSound = existing.soundName
            }
        }
    }
}
