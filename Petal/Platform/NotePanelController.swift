import AppKit
import PetalKit
import SwiftUI

public final class NotePanel: NSPanel {
    public var onEscapePressed: (() -> Void)?

    override public var canBecomeKey: Bool {
        true
    }

    override public var canBecomeMain: Bool {
        true
    }

    override public func cancelOperation(_ sender: Any?) {
        if let onEscapePressed = onEscapePressed {
            onEscapePressed()
        } else {
            super.cancelOperation(sender)
        }
    }
}

public struct WindowDragArea: NSViewRepresentable {
    public var onDoubleClick: (() -> Void)?

    public init(onDoubleClick: (() -> Void)? = nil) {
        self.onDoubleClick = onDoubleClick
    }

    public func makeNSView(context _: Context) -> WindowDragView {
        let view = WindowDragView()
        view.onDoubleClick = onDoubleClick
        return view
    }

    public func updateNSView(_ nsView: WindowDragView, context _: Context) {
        nsView.onDoubleClick = onDoubleClick
    }
}

public final class WindowDragView: NSView {
    public var onDoubleClick: (() -> Void)?

    override public var mouseDownCanMoveWindow: Bool {
        true
    }

    override public func mouseDown(with event: NSEvent) {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if event.clickCount == 2 {
            onDoubleClick?()
            return
        }
        window?.performDrag(with: event)
    }
}

@MainActor
public final class NotePanelController: NSObject, NSWindowDelegate {
    public static let minimumExpandedWidth: CGFloat = 260
    public static let minimumExpandedHeight: CGFloat = 280

    public let noteID: Note.ID
    public private(set) var panel: NotePanel?
    public var onFrameChanged: ((CGRect) -> Void)?
    public var onEscapePressed: (() -> Void)?
    public var onAutoShrinkRequested: (() -> Void)?
    private var expandedSize: CGSize = .init(width: 280, height: 320)

    public init(noteID: Note.ID) {
        self.noteID = noteID
        super.init()
    }

    public func show(
        with rootView: some View,
        frame: CGRect,
        isPinned: Bool,
        isOnDesktop: Bool,
        isCollapsed: Bool = false,
        collapseStyle: CollapseStyle = .pill,
        requiresDarkText: Bool = true
    ) {
        if let existing = panel {
            existing.orderFrontRegardless()
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let initialWidth = max(Self.minimumExpandedWidth, max(280, frame.width))
        let initialHeight = max(Self.minimumExpandedHeight, max(320, frame.height))
        expandedSize = CGSize(width: initialWidth, height: initialHeight)

        let initialRect: NSRect
        if isCollapsed {
            let targetW: CGFloat = (collapseStyle == .pill) ? 136 : 96
            let targetH: CGFloat = (collapseStyle == .pill) ? 28 : 96
            let y = frame.maxY - targetH
            initialRect = NSRect(x: frame.origin.x, y: y, width: targetW, height: targetH)
        } else {
            initialRect = NSRect(
                x: frame.origin.x,
                y: frame.origin.y,
                width: initialWidth,
                height: initialHeight
            )
        }

        let newPanel = NotePanel(
            contentRect: initialRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )

        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = false
        newPanel.isMovableByWindowBackground = true
        newPanel.hidesOnDeactivate = false
        newPanel.becomesKeyOnlyIfNeeded = false
        newPanel.appearance = NSAppearance(named: requiresDarkText ? .aqua : .darkAqua)
        newPanel.delegate = self
        newPanel.onEscapePressed = { [weak self] in
            self?.onEscapePressed?()
        }

        updateWindowLevel(panel: newPanel, isPinned: isPinned, isOnDesktop: isOnDesktop)
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingController = NSHostingController(rootView: rootView)
        hostingController.sizingOptions = []
        newPanel.contentViewController = hostingController

        newPanel.orderFrontRegardless()
        newPanel.makeKeyAndOrderFront(nil)
        panel = newPanel
        ensureOnScreen()
    }

    public func ensureOnScreen() {
        guard let panel = panel, let screen = panel.screen ?? NSScreen.main else { return }
        var frame = panel.frame
        let visible = screen.visibleFrame
        let inset: CGFloat = 16.0

        let minX = visible.minX + inset
        let maxX = max(minX, visible.maxX - frame.width - inset)
        let minY = visible.minY + inset
        let maxY = max(minY, visible.maxY - frame.height - inset)

        let clampedX = min(max(minX, frame.origin.x), maxX)
        let clampedY = min(max(minY, frame.origin.y), maxY)

        if clampedX != frame.origin.x || clampedY != frame.origin.y {
            frame.origin.x = clampedX
            frame.origin.y = clampedY
            panel.setFrame(frame, display: true, animate: false)
            DispatchQueue.main.async { [weak self] in
                self?.onFrameChanged?(frame)
            }
        }
    }

    public func updateWindowLevel(panel: NSPanel, isPinned: Bool, isOnDesktop: Bool) {
        if isOnDesktop {
            panel.level = .init(Int(CGWindowLevelForKey(.desktopWindow)))
        } else if isPinned {
            panel.level = .floating
        } else {
            panel.level = .normal
        }
    }

    public func setCollapsed(_ collapsed: Bool, style: CollapseStyle = .pill, animated _: Bool = false) {
        guard let panel = panel else { return }
        let frame = panel.frame

        if collapsed {
            if frame.width >= 200, frame.height >= 200 {
                expandedSize = frame.size
            }
            let targetW: CGFloat = (style == .pill) ? 136 : 96
            let targetH: CGFloat = (style == .pill) ? 28 : 96
            let newY = frame.maxY - targetH
            let newFrame = NSRect(x: frame.minX, y: newY, width: targetW, height: targetH)
            panel.setFrame(newFrame, display: true)
        } else {
            let targetW = max(Self.minimumExpandedWidth, max(280, expandedSize.width))
            let targetH = max(Self.minimumExpandedHeight, max(320, expandedSize.height))
            var newX = frame.minX
            var newY = frame.maxY - targetH

            if let screen = panel.screen ?? NSScreen.main {
                let vis = screen.visibleFrame
                let inset: CGFloat = 16.0
                newX = min(max(vis.minX + inset, newX), max(vis.minX + inset, vis.maxX - targetW - inset))
                newY = min(max(vis.minY + inset, newY), max(vis.minY + inset, vis.maxY - targetH - inset))
            }

            let newFrame = NSRect(x: newX, y: newY, width: targetW, height: targetH)
            panel.setFrame(newFrame, display: true)
        }
    }

    public func move(by delta: CGSize) {
        guard let panel = panel else { return }
        var origin = panel.frame.origin
        origin.x += delta.width
        origin.y -= delta.height
        panel.setFrameOrigin(origin)
        let frame = panel.frame
        DispatchQueue.main.async { [weak self] in
            self?.onFrameChanged?(frame)
        }
    }

    public func resize(by delta: CGSize) {
        guard let panel = panel else { return }
        var frame = panel.frame
        let minW: CGFloat = Self.minimumExpandedWidth
        let minH: CGFloat = Self.minimumExpandedHeight
        let newWidth = max(minW, frame.width + delta.width)
        let newHeight = max(minH, frame.height + delta.height)

        let heightDiff = newHeight - frame.height
        frame.origin.y -= heightDiff
        frame.size.width = newWidth
        frame.size.height = newHeight

        if let screen = panel.screen ?? NSScreen.main {
            let vis = screen.visibleFrame
            if frame.minY < vis.minY + 8 {
                let overflow = (vis.minY + 8) - frame.minY
                frame.origin.y = vis.minY + 8
                frame.size.height = max(minH, frame.size.height - overflow)
            }
            if frame.maxX > vis.maxX - 8 {
                frame.size.width = max(minW, vis.maxX - 8 - frame.minX)
            }
        }

        panel.setFrame(frame, display: true, animate: false)

        expandedSize = frame.size
        DispatchQueue.main.async { [weak self] in
            self?.onFrameChanged?(frame)
        }
    }

    public func updateAppearance(requiresDarkText: Bool) {
        panel?.appearance = NSAppearance(named: requiresDarkText ? .aqua : .darkAqua)
    }

    public func updateFrame(_ newFrame: CGRect, animate: Bool = false) {
        panel?.setFrame(newFrame, display: true, animate: animate)
    }

    public func close() {
        panel?.orderOut(nil)
        panel = nil
    }

    public func windowDidMove(_: Notification) {
        guard let panel = panel, let screen = panel.screen ?? NSScreen.main else { return }
        var frame = panel.frame
        let visibleFrame = screen.visibleFrame
        let inset: CGFloat = 8.0

        var adjusted = false
        if frame.minX < visibleFrame.minX + inset {
            frame.origin.x = visibleFrame.minX + inset
            adjusted = true
        } else if frame.maxX > visibleFrame.maxX - inset {
            frame.origin.x = max(visibleFrame.minX + inset, visibleFrame.maxX - frame.width - inset)
            adjusted = true
        }

        if frame.maxY > visibleFrame.maxY - inset {
            frame.origin.y = max(visibleFrame.minY + inset, visibleFrame.maxY - frame.height - inset)
            adjusted = true
        } else if frame.minY < visibleFrame.minY + inset {
            frame.origin.y = visibleFrame.minY + inset
            adjusted = true
        }

        if adjusted {
            panel.setFrame(frame, display: true, animate: false)
        }

        let updatedFrame = panel.frame
        DispatchQueue.main.async { [weak self] in
            self?.onFrameChanged?(updatedFrame)
        }
    }

    public func windowDidResize(_: Notification) {
        guard let panel = panel else { return }
        let frame = panel.frame
        DispatchQueue.main.async { [weak self] in
            self?.onFrameChanged?(frame)
        }
    }

    public func windowDidResignKey(_: Notification) {
        let autoShrink = UserDefaults.standard.bool(forKey: "autoShrinkEnabled")
        if autoShrink {
            DispatchQueue.main.async { [weak self] in
                self?.onAutoShrinkRequested?()
            }
        }
    }
}
