import Foundation

public enum AudioRecordingState: Sendable {
    case idle
    case recording(elapsed: TimeInterval, currentLevel: Float)
    case paused
    case stopped(url: URL, duration: TimeInterval, waveform: [Float])
    case failed(String)
}

public protocol AudioRecorder: Sendable {
    func startRecording() async throws
    func stopRecording() async throws -> (url: URL, duration: TimeInterval, waveform: [Float])
    func cancelRecording() async
}
