import AppKit
import PetalKit
import SwiftUI

@MainActor
public final class NotesStackListController: NSObject, NSWindowDelegate {
    public static let shared = NotesStackListController()

    private var panel: NSPanel?

    override private init() {
        super.init()
    }

    public var isVisible: Bool {
        panel?.isVisible ?? false
    }

    public func toggle(with view: some View) {
        if isVisible {
            hide()
        } else {
            show(with: view)
        }
    }

    public func show(with view: some View) {
        guard let screen = NSScreen.main else { return }

        let width: CGFloat = 480
        let height: CGFloat = 530
        let x = screen.visibleFrame.midX - (width / 2)
        let y = screen.visibleFrame.midY - (height / 2) + 40

        if panel == nil {
            let newPanel = NSPanel(
                contentRect: NSRect(x: x, y: y, width: width, height: height),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = false
            newPanel.level = .floating
            newPanel.isMovableByWindowBackground = true
            newPanel.delegate = self
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel = newPanel
        } else {
            panel?.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }

        panel?.contentView = NSHostingView(rootView: view)
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    public func windowDidResignKey(_: Notification) {
        hide()
    }
}
