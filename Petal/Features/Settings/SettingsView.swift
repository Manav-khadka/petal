import PetalKit
import SwiftUI

public struct SettingsView: View {
    @AppStorage("defaultCollapseStyle") private var defaultCollapseStyle: String = CollapseStyle.pill.rawValue
    @AppStorage("autoShrinkEnabled") private var autoShrinkEnabled: Bool = true
    @AppStorage("snapToEdges") private var snapToEdges: Bool = true
    @AppStorage("petalTheme") private var selectedTheme: String = PetalTheme.light.rawValue
    @AppStorage("alarmSound") private var alarmSound: String = "Gentle Chime"
    @AppStorage("autoBackupCadence") private var autoBackupCadence: String = "On Change"

    public var backupService: any BackupService
    public var onBackupNow: () -> Void
    public var onRestoreSnapshot: (String) -> Void

    @State private var snapshots: [BackupSnapshot] = []
    @State private var backupStatusMessage: String = "Backed up"

    public init(
        backupService: any BackupService,
        onBackupNow: @escaping () -> Void,
        onRestoreSnapshot: @escaping (String) -> Void
    ) {
        self.backupService = backupService
        self.onBackupNow = onBackupNow
        self.onRestoreSnapshot = onRestoreSnapshot
    }

    public var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }

            appearanceTab
                .tabItem { Label("Appearance", systemImage: "paintpalette") }

            soundsTab
                .tabItem { Label("Sounds", systemImage: "speaker.wave.2") }

            shortcutsTab
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }

            backupTab
                .tabItem { Label("Backup", systemImage: "icloud") }
        }
        .frame(width: 480, height: 340)
        .padding(20)
        .onAppear {
            loadBackupInfo()
        }
    }

    private var generalTab: some View {
        Form {
            Section("Collapsed Notes") {
                Picker("Collapse Style", selection: $defaultCollapseStyle) {
                    Text("Mini (120 × 120 px square)").tag(CollapseStyle.mini.rawValue)
                    Text("Pill (160 × 32 px strip)").tag(CollapseStyle.pill.rawValue)
                }

                Toggle("Auto-shrink when clicking outside or pressing Esc", isOn: $autoShrinkEnabled)
                Toggle("Snap notes to screen edges", isOn: $snapToEdges)
            }
        }
    }

    private var appearanceTab: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(PetalTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text(themeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var themeDescription: String {
        switch selectedTheme {
        case "Dark": return "Muted pastels on comfortable charcoal background."
        case "Paper": return "Gentle textured background with light ruled lines."
        default: return "Bright pastel sticky notes on desk."
        }
    }

    private var soundsTab: some View {
        Form {
            Section("Alarm & Reminder Alerts") {
                Picker("Sound", selection: $alarmSound) {
                    ForEach(SoundPlayer.availableSounds, id: \.self) { sound in
                        Text(sound).tag(sound)
                    }
                }

                Button("Play Test Sound") {
                    SoundPlayer.shared.play(soundName: alarmSound)
                }
            }
        }
    }

    private var shortcutsTab: some View {
        Form {
            Section("Global Shortcuts") {
                LabeledContent("New Note", value: "⌃⌥N")
                LabeledContent("Quick Open", value: "⌃⌥Space")
                LabeledContent("Show / Hide All", value: "⌃⌥H")
            }
            Section("Note Shortcuts") {
                LabeledContent("Collapse Note", value: "⌘E")
                LabeledContent("Reminder Popover", value: "⌘⇧R")
                LabeledContent("Alarm Popover", value: "⌘⇧A")
                LabeledContent("Timer Popover", value: "⌘⇧T")
                LabeledContent("Voice Recorder", value: "⌘⇧M")
            }
        }
    }

    private var backupTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Google Drive Backup")
                        .font(.headline)
                    Text(backupStatusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Back Up Now", action: onBackupNow)
                    .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)

            Picker("Auto-backup Cadence", selection: $autoBackupCadence) {
                Text("On Change").tag("On Change")
                Text("Hourly").tag("Hourly")
                Text("Daily").tag("Daily")
            }

            Text("Snapshots")
                .font(.subheadline).bold()

            List(snapshots) { snap in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snap.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12, weight: .medium))
                        Text("\(snap.noteCount) notes backed up")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Restore") {
                        onRestoreSnapshot(snap.id)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
            .frame(height: 100)
        }
    }

    private func loadBackupInfo() {
        Task {
            let status = await backupService.status
            let list = (try? await backupService.listSnapshots()) ?? []
            await MainActor.run {
                self.backupStatusMessage = status.message
                self.snapshots = list
            }
        }
    }
}
