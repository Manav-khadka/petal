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
        HStack(spacing: 6) {
            // Play / Pause
            Button(action: togglePlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(width: 18, height: 18)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Mini Waveform
            HStack(spacing: 1.5) {
                let samples = clip.waveformSamples.isEmpty ? Array(repeating: 0.3, count: 20) : clip.waveformSamples
                ForEach(0 ..< min(samples.count, 22), id: \.self) { i in
                    let fraction = Double(i) / Double(min(samples.count, 22))
                    RoundedRectangle(cornerRadius: 1)
                        .fill(fraction <= playbackProgress ? Color.primary : Color.secondary.opacity(0.35))
                        .frame(width: 2, height: max(3, CGFloat(samples[i]) * 14))
                }
            }
            .frame(height: 16)

            // Duration
            Text(clip.formattedDuration)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            // Speed Button
            Button(action: cycleSpeed) {
                Text(String(format: "%.1fx", playbackRate))
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)

            // Transcript Toggle
            if let transcript = clip.transcript, !transcript.isEmpty {
                Button(action: { showTranscript.toggle() }) {
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 10))
                        .foregroundColor(showTranscript ? .blue : .secondary)
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
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.primary.opacity(0.06))
        .cornerRadius(12)
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
