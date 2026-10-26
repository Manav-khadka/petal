import Foundation
import PetalKit
import Speech

public final class SpeechRecognitionManager: PetalSpeechTranscriber, @unchecked Sendable {
    public init() {}

    public func transcribe(audioURL: URL) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                guard authStatus == .authorized,
                      let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
                      recognizer.isAvailable
                else {
                    continuation.resume(returning: "")
                    return
                }

                let request = SFSpeechURLRecognitionRequest(url: audioURL)
                request.requiresOnDeviceRecognition = true

                recognizer.recognitionTask(with: request) { result, error in
                    if let result = result, result.isFinal {
                        continuation.resume(returning: result.bestTranscription.formattedString)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
