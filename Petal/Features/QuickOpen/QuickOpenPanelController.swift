import AppKit
import PetalKit
import SwiftUI

public final class QuickOpenPanel: NSPanel {
    override public var canBecomeKey: Bool {
        true
    }

    override public var canBecomeMain: Bool {
        true
    }
}

@MainActor
public final class QuickOpenPanelController: NSObject, NSWindowDelegate {
    public static let shared = QuickOpenPanelController()

    private var panel: QuickOpenPanel?

    override private init() {
        super.init()
    }

    public func toggle(with view: some View) {
        if let p = panel, p.isVisible {
            hide()
        } else {
            show(with: view)
        }
    }

    public func show(with view: some View) {
        guard let screen = NSScreen.main else { return }

        if panel == nil {
            let width: CGFloat = 520
            let height: CGFloat = 260
            let x = screen.visibleFrame.midX - (width / 2)
            let y = screen.visibleFrame.midY + 80 // slightly above center

            let newPanel = QuickOpenPanel(
                contentRect: NSRect(x: x, y: y, width: width, height: height),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = true
            newPanel.level = .floating
            newPanel.delegate = self
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel = newPanel
        }

        panel?.contentView = NSHostingView(rootView: view)
        NSApp.activate(ignoringOtherApps: true)
        panel?.orderFrontRegardless()
        panel?.makeKeyAndOrderFront(nil)
    }

    public func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    public func windowDidResignKey(_: Notification) {
        hide()
    }
}
