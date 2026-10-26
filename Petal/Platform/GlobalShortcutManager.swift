import AppKit
import Foundation

@MainActor
public final class GlobalShortcutManager {
    public static let shared = GlobalShortcutManager()

    private var globalMonitor: Any?
    private var localMonitor: Any?

    public var onNewNote: (() -> Void)?
    public var onQuickOpen: (() -> Void)?
    public var onToggleAllNotes: (() -> Void)?

    private init() {
        setupMonitors()
    }

    private func setupMonitors() {
        // Global monitor for when other apps are active
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor when Petal is key
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers?.lowercased()

        // ⌃⌥N (Control + Option + N) -> New Note
        if flags == [.control, .option] && chars == "n" {
            onNewNote?()
            return true
        }

        // ⌃⌥Space (Control + Option + Space) -> Quick Open
        if flags == [.control, .option] && event.keyCode == 49 { // 49 is Space
            onQuickOpen?()
            return true
        }

        // ⌃⌥H (Control + Option + H) -> Toggle All Notes
        if flags == [.control, .option] && chars == "h" {
            onToggleAllNotes?()
            return true
        }

        return false
    }
}
