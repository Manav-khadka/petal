import AppKit
import PetalKit
import SwiftUI

@MainActor
public final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var updateTimer: Timer?

    public var getPopoverView: (() -> AnyView)?

    override public init() {
        super.init()
    }

    public func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = NSImage(systemSymbolName: "note.text", accessibilityDescription: "Petal")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        statusItem = item

        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true
        popover = pop
    }

    @objc private func statusBarButtonClicked() {
        guard let pop = popover, let button = statusItem?.button else { return }

        if pop.isShown {
            pop.performClose(nil)
        } else {
            if let view = getPopoverView?() {
                pop.contentViewController = NSHostingController(rootView: view)
            }
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    public func updateTitle(text: String?) {
        guard let button = statusItem?.button else { return }
        button.title = text ?? ""
    }

    public func closePopover() {
        popover?.performClose(nil)
    }
}
