import AVFoundation
import Foundation
import PetalKit

public final class AudioRecordingManager: NSObject, AudioRecorder, @unchecked Sendable, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var currentURL: URL?
    private var startTime: Date?
    private var recordedSamples: [Float] = []
    private var levelTimer: Timer?

    private var recordingsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Petal/Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    public func startRecording() async throws {
        let filename = "voice_\(UUID().uuidString).m4a"
        let fileURL = recordingsDirectory.appendingPathComponent(filename)
        currentURL = fileURL
        recordedSamples = []

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.isMeteringEnabled = true
        recorder.delegate = self
        guard recorder.record() else {
            throw NSError(domain: "PetalAudio", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to record"])
        }

        audioRecorder = recorder
        startTime = Date()

        await MainActor.run {
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let rec = self.audioRecorder, rec.isRecording else { return }
                rec.updateMeters()
                let power = rec.averagePower(forChannel: 0)
                let normalized = max(0.05, min(1.0, (power + 50.0) / 50.0))
                self.recordedSamples.append(normalized)
            }
        }
    }

    public func stopRecording() async throws -> (url: URL, duration: TimeInterval, waveform: [Float]) {
        await MainActor.run {
            levelTimer?.invalidate()
            levelTimer = nil
        }

        guard let recorder = audioRecorder, let url = currentURL else {
            throw NSError(domain: "PetalAudio", code: 2, userInfo: [NSLocalizedDescriptionKey: "No active recording"])
        }

        let duration = recorder.currentTime
        recorder.stop()
        audioRecorder = nil

        // Resample waveform into ~30 bars for the pill UI
        let finalWaveform = resample(samples: recordedSamples, targetCount: 30)
        return (url, duration, finalWaveform)
    }

    public func cancelRecording() async {
        await MainActor.run {
            levelTimer?.invalidate()
            levelTimer = nil
        }
        audioRecorder?.stop()
        audioRecorder = nil
        if let url = currentURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func resample(samples: [Float], targetCount: Int) -> [Float] {
        guard !samples.isEmpty else {
            return Array(repeating: 0.3, count: targetCount)
        }
        if samples.count <= targetCount {
            return samples
        }
        let chunkSize = Double(samples.count) / Double(targetCount)
        var result: [Float] = []
        for i in 0 ..< targetCount {
            let start = Int(Double(i) * chunkSize)
            let end = min(samples.count, Int(Double(i + 1) * chunkSize))
            if start < end {
                let slice = samples[start ..< end]
                let avg = slice.reduce(0, +) / Float(slice.count)
                result.append(avg)
            } else {
                result.append(samples[start])
            }
        }
        return result
    }
}
