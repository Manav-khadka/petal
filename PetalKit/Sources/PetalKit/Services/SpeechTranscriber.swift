import Foundation

public protocol PetalSpeechTranscriber: Sendable {
    func transcribe(audioURL: URL) async throws -> String
}

public struct MockSpeechTranscriber: PetalSpeechTranscriber {
    public init() {}
    public func transcribe(audioURL _: URL) async throws -> String {
        return "Voice note transcribed successfully."
    }
}
