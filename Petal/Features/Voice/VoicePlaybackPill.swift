import AVFoundation
import PetalKit
import SwiftUI

public struct VoicePlaybackPill: View {
    @Bindable var viewModel: NoteViewModel
    public let clip: VoiceClip

    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackProgress: Double = 0.0
    @State private var playbackRate: Float = 1.0
    @State private var progressTimer: Timer?
    @State private var showTranscript = false

    public init(viewModel: NoteViewModel, clip: VoiceClip) {
        self.viewModel = viewModel
        self.clip = clip
    }

    public var body: some View {
        let isDarkText = viewModel.note.color.requiresDarkText
        let primaryInk = PetalColor.textColor(for: viewModel.note.color, theme: viewModel.currentTheme)

        HStack(spacing: 7) {
            // Tactile Play / Pause Button
            Button(action: togglePlay) {
                ZStack {
                    Circle()
                        .fill(isPlaying ? Color(hex: "#FF4D6D") : primaryInk.opacity(0.12))
                        .frame(width: 22, height: 22)

                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(isPlaying ? .white : primaryInk)
                        .offset(x: isPlaying ? 0 : 0.8)
                }
            }
            .buttonStyle(.plain)

            // Dynamic Waveform Visualizer
            HStack(spacing: 1.5) {
                let samples = clip.waveformSamples.isEmpty ? Array(repeating: 0.3, count: 20) : clip.waveformSamples
                ForEach(0 ..< min(samples.count, 20), id: \.self) { i in
                    let fraction = Double(i) / Double(min(samples.count, 20))
                    let isPlayed = fraction <= playbackProgress
                    RoundedRectangle(cornerRadius: 1)
                        .fill(isPlayed ? Color(hex: "#FF4D6D") : primaryInk.opacity(0.25))
                        .frame(width: 2.2, height: max(4, CGFloat(samples[i]) * 15))
                }
            }
            .frame(height: 16)

            // Duration
            Text(clip.formattedDuration)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(primaryInk.opacity(0.75))

            // Speed Pill
            Button(action: cycleSpeed) {
                Text(String(format: "%.1fx", playbackRate))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 2)
                    .background(primaryInk.opacity(0.08))
                    .foregroundColor(primaryInk.opacity(0.85))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Transcript Toggle
            if let transcript = clip.transcript, !transcript.isEmpty {
                Button(action: { showTranscript.toggle() }) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 10))
                        .foregroundColor(showTranscript ? Color(hex: "#2563EB") : primaryInk.opacity(0.6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showTranscript) {
                    Text(transcript)
                        .font(.system(.caption, design: .rounded))
                        .padding(Spacing.m)
                        .frame(maxWidth: 220)
                }
            }

            // Remove clip
            Button(action: {
                stopAudio()
                viewModel.removeVoiceClip()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(primaryInk.opacity(0.55))
                    .frame(width: 16, height: 16)
                    .background(Color.black.opacity(0.04))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete voice note")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(
            Capsule()
                .fill(Color.white.opacity(isDarkText ? 0.88 : 0.2))
                .background(Capsule().fill(.ultraThinMaterial))
        )
        .overlay(
            Capsule()
                .stroke(Color.black.opacity(0.07), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1.5)
        .onDisappear {
            stopAudio()
        }
    }

    private func togglePlay() {
        if isPlaying {
            stopAudio()
        } else {
            startAudio()
        }
    }

    private func startAudio() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let fileURL = appSupport.appendingPathComponent("Petal/Recordings/\(clip.relativePath)")

        guard let player = try? AVAudioPlayer(contentsOf: fileURL) else { return }
        player.enableRate = true
        player.rate = playbackRate
        player.play()
        audioPlayer = player
        isPlaying = true

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                guard let p = audioPlayer, p.isPlaying else {
                    stopAudio()
                    return
                }
                playbackProgress = p.currentTime / p.duration
            }
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        progressTimer?.invalidate()
        progressTimer = nil
        playbackProgress = 0.0
    }

    private func cycleSpeed() {
        if playbackRate == 1.0 {
            playbackRate = 1.5
        } else if playbackRate == 1.5 {
            playbackRate = 2.0
        } else {
            playbackRate = 1.0
        }
        audioPlayer?.rate = playbackRate
    }
}
