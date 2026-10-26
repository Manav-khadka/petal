import AppKit
import Carbon
import Foundation

// Global C-function callback for Carbon event handler
private func carbonHotKeyEventHandler(
    _: EventHandlerCallRef?,
    event: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return noErr }
    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr else { return noErr }

    DispatchQueue.main.async {
        GlobalShortcutManager.shared.dispatchHotKey(id: hotKeyID.id)
    }
    return noErr
}

@MainActor
public final class GlobalShortcutManager {
    public static let shared = GlobalShortcutManager()

    public var onNewNote: (() -> Void)?
    public var onQuickOpen: (() -> Void)?
    public var onToggleAllNotes: (() -> Void)?
    public var onStackList: (() -> Void)?
    public var onCalendar: (() -> Void)?
    public var onCollapseAll: (() -> Void)?
    public var onExpandAll: (() -> Void)?

    private var localMonitor: Any?
    private var eventHandler: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []

    public enum HotKeyID: UInt32 {
        case quickOpen = 1
        case quickOpenOptionSpace = 2
        case quickOpenCmdShiftSpace = 3
        case newNote = 4
        case newNoteCmdOpt = 5
        case stackList = 6
        case stackListCmdOpt = 7
        case collapseAll = 8
        case expandAll = 9
        case toggleAll = 10
        case calendar = 11
        case calendarCmdOpt = 12
    }

    private init() {
        setupCarbonHotKeys()
        setupLocalMonitors()
    }

    private func setupCarbonHotKeys() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotKeyEventHandler,
            1,
            &eventSpec,
            nil,
            &eventHandler
        )

        // 1. Quick Open / Command Palette:
        // ⌃⌥Space
        registerCarbonHotKey(id: .quickOpen, keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey))
        // ⌥Space
        registerCarbonHotKey(id: .quickOpenOptionSpace, keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))
        // ⌘⇧Space
        registerCarbonHotKey(id: .quickOpenCmdShiftSpace, keyCode: UInt32(kVK_Space), modifiers: UInt32(cmdKey | shiftKey))

        // 2. New Note:
        // ⌃⌥N
        registerCarbonHotKey(id: .newNote, keyCode: UInt32(kVK_ANSI_N), modifiers: UInt32(controlKey | optionKey))
        // ⌥⌘N
        registerCarbonHotKey(id: .newNoteCmdOpt, keyCode: UInt32(kVK_ANSI_N), modifiers: UInt32(optionKey | cmdKey))

        // 3. Stack List:
        // ⌃⌥L
        registerCarbonHotKey(id: .stackList, keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(controlKey | optionKey))
        // ⌥⌘L
        registerCarbonHotKey(id: .stackListCmdOpt, keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(optionKey | cmdKey))

        // 4. Collapse All: ⌃⌥C
        registerCarbonHotKey(id: .collapseAll, keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(controlKey | optionKey))

        // 5. Expand All / See All: ⌃⌥E
        registerCarbonHotKey(id: .expandAll, keyCode: UInt32(kVK_ANSI_E), modifiers: UInt32(controlKey | optionKey))

        // 6. Toggle All Notes: ⌃⌥H
        registerCarbonHotKey(id: .toggleAll, keyCode: UInt32(kVK_ANSI_H), modifiers: UInt32(controlKey | optionKey))

        // 7. Calendar & Agenda:
        // ⌃⌥K
        registerCarbonHotKey(id: .calendar, keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(controlKey | optionKey))
        // ⌥⌘K
        registerCarbonHotKey(id: .calendarCmdOpt, keyCode: UInt32(kVK_ANSI_K), modifiers: UInt32(optionKey | cmdKey))
    }

    private func registerCarbonHotKey(id: HotKeyID, keyCode: UInt32, modifiers: UInt32) {
        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x50544C4B), id: id.rawValue) // 'PTLK'
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        }
    }

    public func dispatchHotKey(id: UInt32) {
        switch id {
        case HotKeyID.quickOpen.rawValue, HotKeyID.quickOpenOptionSpace.rawValue, HotKeyID.quickOpenCmdShiftSpace.rawValue:
            onQuickOpen?()
        case HotKeyID.newNote.rawValue, HotKeyID.newNoteCmdOpt.rawValue:
            onNewNote?()
        case HotKeyID.stackList.rawValue, HotKeyID.stackListCmdOpt.rawValue:
            onStackList?()
        case HotKeyID.collapseAll.rawValue:
            onCollapseAll?()
        case HotKeyID.expandAll.rawValue:
            onExpandAll?()
        case HotKeyID.toggleAll.rawValue:
            onToggleAllNotes?()
        case HotKeyID.calendar.rawValue, HotKeyID.calendarCmdOpt.rawValue:
            onCalendar?()
        default:
            break
        }
    }

    private func setupLocalMonitors() {
        // Local monitor when Petal is key
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleLocalKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    @discardableResult
    private func handleLocalKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let chars = event.charactersIgnoringModifiers?.lowercased()

        // ⌘N -> New Note when app is key
        if flags == .command && chars == "n" {
            onNewNote?()
            return true
        }

        // ⌘L -> Stack List when app is key
        if flags == .command && chars == "l" {
            onStackList?()
            return true
        }

        // ⌥⌘K or ⌃⌥K -> Calendar
        if (flags.contains([.command, .option]) || flags.contains([.control, .option])) && chars == "k" {
            onCalendar?()
            return true
        }

        // ⌘K -> Quick Open when app is key
        if flags == .command && chars == "k" {
            onQuickOpen?()
            return true
        }

        return false
    }
}
