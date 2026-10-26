import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        NSApp.setActivationPolicy(.regular) // Normal macOS app with Dock icon and active application state
        Task { @MainActor in
            await AppState.shared.launch()
        }
    }

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows _: Bool) -> Bool {
        Task { @MainActor in
            AppState.shared.bringAllToFront()
        }
        return true
    }
}

@main
struct PetalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                backupService: AppState.shared.backupService,
                onBackupNow: {
                    Task {
                        _ = try? await AppState.shared.backupService.backup(notes: AppState.shared.notes)
                    }
                },
                onRestoreSnapshot: { id in
                    Task {
                        let restored = (try? await AppState.shared.backupService.restore(snapshotID: id)) ?? []
                        for r in restored {
                            try? await AppState.shared.repository.save(r)
                        }
                        await AppState.shared.loadNotes()
                    }
                }
            )
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    AppState.shared.createNewNote()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open Board") {
                    AppState.shared.openBoard()
                }
                .keyboardShortcut("b", modifiers: .command)

                Button("Quick Open") {
                    AppState.shared.toggleQuickOpen()
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
    }
}
