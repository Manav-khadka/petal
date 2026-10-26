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
        "Subtle Ping",
        "Clear Alert"
    ]

    private init() {}

    public func play(soundName: String) {
        let sound: NSSound? = {
            switch soundName {
            case "Soft Bell":
                return NSSound(named: "Glass")
            case "Harp Melody":
                return NSSound(named: "Tink")
            case "Subtle Ping":
                return NSSound(named: "Pop")
            case "Clear Alert":
                return NSSound(named: "Ping")
            default:
                return NSSound(named: "Glass")
            }
        }()
        sound?.stop()
        sound?.play()
    }

    public func playAlarmRinging() {
        if let s = NSSound(named: "Glass") {
            s.stop()
            s.play()
        }
        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            if let s = NSSound(named: "Glass") {
                s.stop()
                s.play()
            }
            try? await Task.sleep(nanoseconds: 650_000_000)
            if let s = NSSound(named: "Glass") {
                s.stop()
                s.play()
            }
        }
    }

    public func playTimerFinished() {
        if let s = NSSound(named: "Ping") {
            s.stop()
            s.play()
        }
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            if let s = NSSound(named: "Ping") {
                s.stop()
                s.play()
            }
        }
    }

    public func playReminderChime() {
        if let s = NSSound(named: "Glass") {
            s.stop()
            s.play()
        }
    }
}
