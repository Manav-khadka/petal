import PetalKit
import SwiftUI

public struct TimerPopoverView: View {
    @Bindable var viewModel: NoteViewModel
    @State private var selectedMinutes: Int = 25

    public init(viewModel: NoteViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: Spacing.m) {
            HStack {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let isRunning = (viewModel.note.timerSession?.isRunning ?? false) &&
                        !(viewModel.note.timerSession?.isFinished(at: context.date) ?? true)
                    MascotFaceView(
                        mood: isRunning ? .awake : .sleeping,
                        tint: .blue,
                        size: 24
                    )
                }
                Text("Focus Timer")
                    .font(.system(.headline, design: .rounded))
                Spacer()
                if viewModel.note.timerSession != nil {
                    Button("Reset") {
                        viewModel.resetTimer()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .font(.caption)
                }
            }

            // Live Countdown Display when running
            if let timer = viewModel.note.timerSession {
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    VStack(spacing: 6) {
                        Text(timer.formattedRemaining(at: context.date))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundColor(timer.isPaused ? .secondary : Color(hex: "#2563EB"))

                        ProgressView(value: timer.progress(at: context.date))
                            .progressViewStyle(.linear)
                            .tint(Color(hex: "#2563EB"))

                        Text(timer.isPaused ? "Paused" : (timer.isFinished(at: context.date) ? "Finished" : "Focusing..."))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(10)
                }
            }

            // Presets
            HStack(spacing: 8) {
                ForEach(TimerSession.presetMinutes, id: \.self) { mins in
                    Button(action: {
                        selectedMinutes = mins
                        viewModel.startTimer(minutes: mins)
                        viewModel.activePopover = nil
                    }) {
                        Text("\(mins)m")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(selectedMinutes == mins ? Color.blue : Color.secondary.opacity(0.12))
                            .foregroundColor(selectedMinutes == mins ? .white : .primary)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Custom slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Custom:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedMinutes) min")
                        .font(.system(.caption, design: .rounded).bold())
                }
                Slider(value: Binding(
                    get: { Double(selectedMinutes) },
                    set: { selectedMinutes = Int($0) }
                ), in: 1 ... 120, step: 1)
            }

            HStack {
                if let timer = viewModel.note.timerSession {
                    Button(timer.isPaused ? "Resume" : "Pause") {
                        viewModel.pauseOrResumeTimer()
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button("Start \(selectedMinutes)m") {
                    viewModel.startTimer(minutes: selectedMinutes)
                    viewModel.activePopover = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }
        }
        .padding(Spacing.m)
        .frame(width: 260)
        .onAppear {
            if let timer = viewModel.note.timerSession {
                selectedMinutes = Int(timer.durationMinutes)
            }
        }
    }
}
