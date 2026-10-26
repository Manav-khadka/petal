import AppKit
import AudioToolbox
import Foundation

@MainActor
public final class SoundPlayer {
    public static let shared = SoundPlayer()

    public static let availableSounds = [
        "Gentle Chime",
        "Soft Bell",
        "Harp Melody",
        "Subtle Ping"
    ]

    private init() {}

    public func play(soundName: String) {
        switch soundName {
        case "Soft Bell":
            NSSound(named: "Glass")?.play()
        case "Harp Melody":
            NSSound(named: "Tink")?.play()
        case "Subtle Ping":
            NSSound(named: "Pop")?.play()
        default:
            NSSound(named: "Purr")?.play()
        }
    }

    public func playAlarmRinging() {
        NSSound(named: "Glass")?.play()
    }
}
