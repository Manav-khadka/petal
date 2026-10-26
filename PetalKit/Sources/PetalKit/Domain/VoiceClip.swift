import Foundation

public struct VoiceClip: Codable, Sendable, Hashable, Identifiable {
    public let id: UUID
    public var relativePath: String
    public var duration: Double
    public var waveformSamples: [Float]
    public var transcript: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        relativePath: String,
        duration: Double,
        waveformSamples: [Float] = [],
        transcript: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.relativePath = relativePath
        self.duration = duration
        self.waveformSamples = waveformSamples
        self.transcript = transcript
        self.createdAt = createdAt
    }

    public var formattedDuration: String {
        let total = Int(duration)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
