import AppKit
import PetalKit
import SwiftUI

public final class NotesStackPanel: NSPanel {
    override public var canBecomeKey: Bool {
        true
    }

    override public var canBecomeMain: Bool {
        true
    }
}

@MainActor
public final class NotesStackListController: NSObject, NSWindowDelegate {
    public static let shared = NotesStackListController()

    private var panel: NotesStackPanel?

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

        let width: CGFloat = 500
        let height: CGFloat = 540
        let x = screen.visibleFrame.midX - (width / 2)
        let y = screen.visibleFrame.midY - (height / 2) + 40

        if panel == nil {
            let newPanel = NotesStackPanel(
                contentRect: NSRect(x: x, y: y, width: width, height: height),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = true
            newPanel.level = .floating
            newPanel.isMovableByWindowBackground = true
            newPanel.becomesKeyOnlyIfNeeded = false
            newPanel.hidesOnDeactivate = false
            newPanel.delegate = self
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel = newPanel
        } else {
            panel?.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }

        let hostingView = NSHostingView(rootView: view)
        panel?.contentView = hostingView
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
