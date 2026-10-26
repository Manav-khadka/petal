import AppKit
import PetalKit
import SwiftUI

@MainActor
public final class BoardWindowController: NSObject, NSWindowDelegate {
    public static let shared = BoardWindowController()

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
            contentRect: NSRect(x: 100, y: 100, width: 960, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Petal Board"
        newWindow.titlebarAppearsTransparent = true
        newWindow.toolbarStyle = .unified
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
