import PetalKit
import SwiftUI

public struct VoiceRecorderBar: View {
    @Bindable var viewModel: NoteViewModel
    public var recorder: any AudioRecorder
    public var transcriber: any PetalSpeechTranscriber

    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var liveLevels: [CGFloat] = Array(repeating: 0.15, count: 20)
    @State private var isPulsing = false

    public init(viewModel: NoteViewModel, recorder: any AudioRecorder, transcriber: any PetalSpeechTranscriber) {
        self.viewModel = viewModel
        self.recorder = recorder
        self.transcriber = transcriber
    }

    public var body: some View {
        HStack(spacing: Spacing.s) {
            // Pulsing record dot
            Circle()
                .fill(Color(hex: "#FF4D6D"))
                .frame(width: 10, height: 10)
                .scaleEffect(isPulsing ? 1.25 : 0.85)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)

            // Live Waveform Bars
            HStack(spacing: 2) {
                ForEach(0 ..< liveLevels.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: "#FF4D6D"))
                        .frame(width: 3, height: max(4, liveLevels[i] * 22))
                }
            }
            .frame(height: 24)

            // Elapsed time
            Text(formattedTime(elapsedSeconds))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            Spacer()

            // Stop button
            Button(action: stopAndSave) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color(hex: "#FF4D6D"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.85))
        .cornerRadius(14)
        .onAppear {
            startRecording()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startRecording() {
        isPulsing = true
        elapsedSeconds = 0
        Task {
            try? await recorder.startRecording()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
            // Random jitter for simulation if no hardware meter
            liveLevels = (0 ..< 20).map { _ in CGFloat.random(in: 0.1 ... 0.9) }
            if elapsedSeconds >= 300 { // 5 min max
                stopAndSave()
            }
        }
    }

    private func stopAndSave() {
        timer?.invalidate()
        timer = nil
        Task {
            if let result = try? await recorder.stopRecording() {
                let transcript = try? await transcriber.transcribe(audioURL: result.url)
                await MainActor.run {
                    viewModel.saveVoiceClip(
                        url: result.url,
                        duration: result.duration,
                        waveform: result.waveform,
                        transcript: transcript
                    )
                    viewModel.isRecordingAudio = false
                }
            } else {
                await MainActor.run {
                    viewModel.isRecordingAudio = false
                }
            }
        }
    }

    private func formattedTime(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
