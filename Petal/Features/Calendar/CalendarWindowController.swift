import AppKit
import PetalKit
import SwiftUI

@MainActor
public final class CalendarWindowController: NSObject, NSWindowDelegate {
    public static let shared = CalendarWindowController()

    private var window: NSWindow?

    override private init() {
        super.init()
    }

    public func show(with rootView: some View) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 120, y: 120, width: 880, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Petal Calendar & Agenda"
        newWindow.titlebarAppearsTransparent = true
        newWindow.toolbarStyle = .unified
        newWindow.minSize = NSSize(width: 760, height: 480)
        newWindow.center()
        newWindow.delegate = self
        newWindow.contentView = NSHostingView(rootView: rootView)

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func windowWillClose(_: Notification) {
        window = nil
    }
}
