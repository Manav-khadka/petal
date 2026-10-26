
# PRD: Petal — Perfect Sticky Notes for Mac

Oct 26, 2026 · @Manav Khadka

## Overview

Petal (working name) is a Mac sticky notes app that looks like a pastel desk, not a utility, and can remind, ring, time and listen, with every note backed up to Google Drive.

- **For:** Mac users who keep to-dos and scraps on screen all day.
- **Problem:** Stickies looks dated, has no reminders, alarms, timers or voice notes, and no dependable backup.
- **Proposed platform:** native macOS 14+ menu-bar app (SwiftUI).

## Design principles

Every note should feel like a small, soft object you want to keep on your desk: pretty first, functional right behind it.

- **Shape:** 16 px corner radius, a subtle paper curl on the bottom-right corner, and a soft two-layer shadow instead of the flat Stickies border.
- **Type:** rounded sans (SF Pro Rounded) for body text; a handwritten face (for example Caveat) for note titles only.
- **Motion:** notes spring in (250 ms), tilt 1° on hover, and sparkle when a checklist item is ticked. Respect Reduce Motion.
- **Charm:** a tiny face on the alarm and timer widgets that blinks, and sleeps when idle.
- **Themes:** Light, Dark (muted pastels on charcoal) and Paper (light grain texture).

| Note color | Hex     | Default use   |
| ---------- | ------- | ------------- |
| Butter     | #FFF3B0 | New note      |
| Blush      | #FFD6E0 | Personal      |
| Mint       | #CFF3E1 | Done / habits |
| Sky        | #CDE7FF | Work          |
| Lavender   | #E3D8FF | Ideas         |
| Peach      | #FFDDC1 | Reminders     |

**Custom colors:** a **+** swatch after the six presets opens the system color picker with a hex field. Chosen colors are saved in a "My colors" row (up to 8) and appear in every note's color popover. Text color adjusts automatically for contrast, and custom colors are softened in Dark theme.

## Core features

Five tools live on the note itself, as small icon buttons in its bottom toolbar, so nothing needs a separate window.

| Feature    | UI entry               | Behavior                                                                                                                    | Priority           |
| ---------- | ---------------------- | --------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| Notes      | Menu-bar + button, ⌘N | Rich text, checklists, color picker, pin on top, resize, snap to screen edges, folders as colored tabs                      | P0                 |
| Reminder   | Bell chip on note      | Type or say "tomorrow 5pm"; repeat options; macOS notification with Snooze 5 / 15 / 60 min; note bounces and glows when due | P0                 |
| Alarm      | Clock icon on note     | Time, repeat days, sound; gentle fade-in; floating note with Stop and Snooze; works with the app closed                     | P0                 |
| Timer      | Hourglass icon on note | Presets 5 / 10 / 25 / 45 min or custom; progress ring on the note corner; live countdown in the menu bar                    | P0                 |
| Voice note | Mic icon on note       | Tap to record, live waveform, up to 5 min; playback pill with speed control; optional on-device transcript inserted as text | P0 (transcript P1) |

## Key screens

Seven main screens cover the app, plus the quick-open bar described under Shortcuts. The note itself is the hero: top to bottom it holds a color dot and pin, a handwritten title, the body, status chips (reminder time, timer ring, voice pill), and the toolbar.

| Screen                   | Layout                                          | UI details                                                                                                                                                  |
| ------------------------ | ----------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Note                     | Floating card, 240 × 240 px default, resizable | Drag by the top strip; color dot opens a popover with 6 presets, a + for custom color and My colors; toolbar fades in on hover; chips sit above the toolbar |
| Reminder / alarm popover | Small sheet anchored to the bell or clock icon  | Quick chips (In 1 hr, Tonight, Tomorrow 9 am), date wheel, repeat toggle row, sound picker                                                                  |
| Timer popover            | Anchored to the hourglass                       | Large circular dial, four preset pills, Start button; the ring then lives on the note corner                                                                |
| Voice recorder           | Replaces the toolbar while recording            | Pulsing red-pink dot, live waveform, elapsed time, Stop; saved as a playback pill                                                                           |
| Menu-bar popover         | 320 px wide dropdown                            | Search field, next reminder card, running timer, 2-column grid of recent notes, New note button                                                             |
| Board                    | Standard window, folder sidebar + masonry grid  | Notes shown as they look on the desk; drag between folders; filter by color, has-reminder, has-voice                                                        |
| Settings                 | Tabbed window                                   | General, Appearance (theme, font size), Sounds, Shortcuts, Backup (see below)                                                                               |

**First run:** three cards — pick a theme, allow notifications and microphone, connect Google Drive (skippable).

## Shortcuts and collapse

Everything is reachable from the keyboard. Global shortcuts work from any app; the rest work when a note is focused. All are remappable in Settings → Shortcuts, in case a default clashes with another app.

| Action                              | Default shortcut                   | Scope  |
| ----------------------------------- | ---------------------------------- | ------ |
| New note                            | ⌃⌥N                              | Global |
| Quick open (search and open a note) | ⌃⌥Space                          | Global |
| Show / hide all notes               | ⌃⌥H                              | Global |
| Collapse / expand this note         | ⌘E, or double-click the top strip | Note   |
| Collapse / expand all notes         | ⌘⌥E                              | Note   |
| Cycle between notes                 | ⌘\`                               | Note   |
| Reminder / alarm / timer / voice    | ⌘⇧R / ⌘⇧A / ⌘⇧T / ⌘⇧M      | Note   |

**Quick-open bar:** a Spotlight-style floating pill with a pastel tint. Type to search titles and text, arrow to a result, Enter to open it, ⌘Enter to open it collapsed. It also takes quick commands: `new`, `timer 10m`, `remind call mom 5pm`.

**Sticky but small:** notes stay pinned where you put them, floating above other windows on every desktop Space. Per note, "on the desktop" lets one sit behind windows instead. When collapsed, a note takes one of two forms, chosen in Settings → General:

- **Mini** (default): a 120 × 120 px square with the note color, title and first two lines.
- **Pill:** a 160 × 32 px strip with the color dot and title.

The reminder bell, timer ring and voice pill stay visible in both, so a running timer is never hidden. **Click to expand** in place with a 250 ms spring; click outside or press Esc and it **auto-shrinks** again (Auto-shrink can be turned off per note or globally). Hovering for 0.4 s peeks the full note without expanding. Collapsed notes can optionally stack along a screen edge.

Proposed build: Carbon hotkeys (or the KeyboardShortcuts Swift package) for global shortcuts, which needs no extra system permission.

## Google Drive backup

Backup is one-way by default: the Mac is the source of truth, Drive holds the safety copy. The Backup settings tab has a status card, an Auto-backup toggle (on change, hourly or daily), **Back up now**, **Restore**, and **Disconnect**.

- **Access:** Google sign-in with the narrow `drive.file` scope, so Petal sees only files it created, in a "Petal Backup" folder.
- **Contents:** one file per note plus voice recordings (.m4a), uploaded incrementally; reminders, alarms and colors travel with each note.
- **Restore:** pick a snapshot by date and note count, preview, then restore all or select notes. Existing notes are never overwritten; clashes become "(restored)" copies.
- **Menu bar:** a small cloud icon shows backup state at a glance.

| State         | Indicator                | Message                                  |
| ------------- | ------------------------ | ---------------------------------------- |
| Backed up     | Cloud with check         | Backed up 2 min ago                      |
| Syncing       | Cloud with spinning dots | Backing up 3 notes…                     |
| Offline       | Cloud with pause         | Waiting for internet; changes are queued |
| Needs sign-in | Cloud with !             | Reconnect Google Drive (button)          |
| Drive full    | Cloud with !             | Drive is full; free space to continue    |

## iPhone and iPad (phase 2)

Petal comes to iPhone and iPad as one universal SwiftUI app, planned now so the Mac data model carries over. Notes then sync both ways through Drive instead of one-way backup: the newest edit wins and the older clashing version is kept as a "(conflict copy)".

| Device | Layout                                                               | UI adaptations                                                                                                                                             |
| ------ | -------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| iPhone | Two-column board of cards; tap opens the note as a full-height sheet | Toolbar above the keyboard; Home and Lock Screen widgets for a pinned note; timer as a Live Activity; reminders and alarms as time-sensitive notifications |
| iPad   | Folder sidebar + board; works in Split View and Stage Manager        | Notes open as floating cards over the board; keyboard shortcuts; same popovers anchored to toolbar icons                                                   |
| Mac    | As in Key screens                                                    | Menu-bar popover stays Mac-only                                                                                                                            |

Colors (presets and My colors), reminders, alarms, timers and voice notes travel with each note, so a note looks and behaves the same on every device.

**Open:** two-way sync over Google Drive is slower and more limited on Apple devices than iCloud. Decide whether iCloud becomes the live sync layer, with Drive kept as the backup.

## Tech stack

Fully native Apple stack with no custom backend: Google Drive is the only server. Native beats Electron or Flutter here because floating windows, the menu bar, alarms that fire while the app is closed, and smooth animation all depend on platform APIs. All choices below are proposed.

| Layer                | Choice                                                                                                                                                              | Why                                                                                                        |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| UI                   | SwiftUI, with AppKit for floating note windows (NSPanel) and the menu-bar item (NSStatusItem)                                                                       | One UI codebase for Mac, iPhone and iPad; AppKit only where SwiftUI can't float or pin windows             |
| Rich text            | AttributedString with TextKit 2, wrapped for SwiftUI                                                                                                                | Bold, bullets and checklists inside a note                                                                 |
| Animation            | SwiftUI springs and Canvas                                                                                                                                          | Bounce-in, hover tilt, sparkle, paper curl, mascot face                                                    |
| Local data           | SwiftData (SQLite underneath)                                                                                                                                       | One shared note model across devices; works offline                                                        |
| Reminders and alarms | UserNotifications with custom sounds, plus a small login-item helper (SMAppService) on Mac                                                                          | Fires with the app closed; the helper shows the floating Stop / Snooze card and plays the full alarm sound |
| Timer                | Stored end time plus Swift concurrency; ActivityKit Live Activity on iPhone                                                                                         | Survives sleep and relaunch because it counts to a time, not ticks                                         |
| Voice notes          | AVAudioEngine (waveform) recording to AAC .m4a; Speech framework, on-device, for transcripts                                                                        | Small files that upload fast; transcripts stay private                                                     |
| Backup and sync      | GoogleSignIn SDK + Drive REST API v3 (`drive.file` scope); tokens in Keychain; background tasks via NSBackgroundActivityScheduler (Mac) and BGTaskScheduler (iOS) | Narrow Drive access; runs without opening the app                                                          |
| Widgets (phase 2)    | WidgetKit                                                                                                                                                           | Home and Lock Screen notes on iPhone and iPad                                                              |
| Build and release    | Xcode, Swift Package Manager, GitHub Actions or Xcode Cloud; notarized DMG or Mac App Store; MetricKit for crashes, no third-party analytics at launch              | Keeps the app light and privacy-friendly                                                                   |

## Project structure and code style

Layered and feature-first: dependencies point inward (UI → features → domain), and anything that touches the outside world (Drive, notifications, microphone, the clock) sits behind a protocol so it can be swapped or faked in tests. `PetalKit` imports no UI framework.

```text
Petal/
├── AGENTS.md                      # rules + commands for the AI
├── project.yml                    # XcodeGen project definition
├── justfile
├── .swiftlint.yml
├── .swiftformat
├── docs/                          # PRD and decision records (one short .md per decision)
├── PetalKit/                      # Swift package: no UI, fully unit-tested
│   ├── Package.swift
│   ├── Sources/PetalKit/
│   │   ├── Domain/                # pure types and rules, no frameworks
│   │   │   ├── Note.swift
│   │   │   ├── NoteColor.swift
│   │   │   ├── Reminder.swift
│   │   │   ├── Alarm.swift
│   │   │   ├── TimerSession.swift
│   │   │   └── VoiceClip.swift
│   │   ├── Services/              # protocols only
│   │   │   ├── NoteRepository.swift
│   │   │   ├── BackupService.swift
│   │   │   ├── NotificationScheduler.swift
│   │   │   ├── AudioRecorder.swift
│   │   │   └── DateProvider.swift
│   │   ├── Storage/               # SwiftData implementation of NoteRepository
│   │   ├── Sync/                  # Drive client, snapshots, merge and conflict rules
│   │   └── Scheduling/            # reminder, alarm and timer calculations
│   └── Tests/PetalKitTests/       # mirrors Sources; uses fakes, no real network or clock
├── Petal/                         # macOS app target (thin)
│   ├── App/                       # PetalApp, AppDelegate, dependency container
│   ├── Features/                  # one folder per feature: View + ViewModel + small subviews
│   │   ├── Note/
│   │   ├── Reminders/
│   │   ├── Alarm/
│   │   ├── Timer/
│   │   ├── Voice/
│   │   ├── Board/
│   │   ├── MenuBar/
│   │   ├── QuickOpen/
│   │   ├── Backup/
│   │   └── Settings/
│   ├── DesignSystem/              # colors, type, spacing, motion, shared views (move to a PetalUI package in phase 2)
│   ├── Platform/                  # AppKit only: floating panel, status item, global hotkeys
│   └── Resources/                 # Assets.xcassets, alarm sounds, Localizable.xcstrings
├── PetalAlarmHelper/              # login-item helper for the alarm card
└── PetalMobile/                   # phase 2: iPhone and iPad target, reuses PetalKit
```

**Design principles applied**

| Principle             | How it shows up                                                                                                                    |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Single responsibility | One primary type per file. A view only lays out; its view model holds UI logic; rules live in`Domain` and `Scheduling`.        |
| Dependency inversion  | Features depend on protocols in`Services`. Real implementations are created once, in `App/`, and passed in. Tests pass fakes.  |
| Feature-first         | Everything for a feature sits in one folder. Features never import each other; they share only domain types and services.          |
| Testability           | Time comes from`DateProvider`, so reminders and timers are tested without waiting. Timers store an end date, never a tick count. |
| Platform isolation    | AppKit (and later UIKit) appears only in`Platform/`; everything else is portable to iPhone and iPad.                             |
| Value types first     | Domain models are`struct` and `enum`. Classes are only view models and services.                                               |
| Few dependencies      | Only Google Sign-In, plus KeyboardShortcuts if used. Everything else is Apple frameworks.                                          |

**Swift code style.** Follow the Swift API Design Guidelines, enforced by SwiftFormat and SwiftLint:

- **Naming:** types `UpperCamelCase`, everything else `lowerCamelCase`. Booleans read as facts (`isPinned`, `hasReminder`). Name by role, not by type. No abbreviations except `id` and `URL`.
- **Files:** file name matches its main type; extensions go in `Type+Topic.swift`. Aim for files under 300 lines and functions under 40.
- **Types:** prefer `struct` and `enum`; make classes `final`; use the narrowest access control (`private` by default).
- **Concurrency:** `async/await` only (no completion handlers, no Combine in new code); `@MainActor` on view models; domain types are `Sendable`; turn on strict concurrency checking.
- **Safety:** no `!`, `try!` or `as!`; no `fatalError` outside previews and tests. Each module throws its own error enum.
- **SwiftUI:** keep a `body` short and free of logic; extract subviews; use design tokens (`Spacing.m`, `PetalColor.butter`), never raw numbers or hex values; every icon-only button has an accessibility label; every view has a preview with sample data; user-visible text goes in the String Catalog.
- **Comments:** explain why, not what; `///` on public API; no commented-out code.

```text
# .swiftformat
--indent 4
--maxwidth 120
--commas always
--self remove
```

```yaml
# .swiftlint.yml
line_length: 120
file_length: { warning: 300, error: 400 }
function_body_length: { warning: 40, error: 60 }
opt_in_rules: [force_unwrapping, implicitly_unwrapped_optional, empty_count]
force_cast: error
force_try: error
```

**Reference example** (the shape every feature should follow):

```swift
// PetalKit/Services/NotificationScheduler.swift
public protocol NotificationScheduler: Sendable {
    func scheduleTimer(endingAt date: Date) async throws
    func cancelAll(for noteID: Note.ID) async
}

// Petal/Features/Timer/TimerViewModel.swift
@MainActor
@Observable
final class TimerViewModel {
    private(set) var endDate: Date?

    private let scheduler: any NotificationScheduler
    private let dateProvider: any DateProvider

    init(scheduler: any NotificationScheduler, dateProvider: any DateProvider) {
        self.scheduler = scheduler
        self.dateProvider = dateProvider
    }

    func start(minutes: Int) async throws {
        let end = dateProvider.now.addingTimeInterval(TimeInterval(minutes * 60))
        endDate = end
        try await scheduler.scheduleTimer(endingAt: end)
    }
}
```

## Dev setup and AI workflow

Write code in VS Code and build, test and run from the command line with Xcode's tools, so an AI agent can loop (edit, build, test, run, look at a screenshot) without opening Xcode. Use the Xcode app only for signing, entitlements, Instruments and App Store upload.

**Fixed decisions**, written into `AGENTS.md` / `CLAUDE.md` at the repo root so the AI never re-debates them:

| Area         | Choice                                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------------------ |
| Minimum OS   | macOS 14 (SwiftData needs it); iOS and iPadOS 17 in phase 2                                                  |
| Project file | XcodeGen: edit`project.yml`, git-ignore the `.xcodeproj`, never hand-edit `.pbxproj`                   |
| Code layout  | Local Swift package`PetalKit` for models, sync, reminder and timer logic; thin `Petal` app target for UI |
| Architecture | SwiftUI views,`@Observable` view models, SwiftData models                                                  |
| Quality      | SwiftFormat and SwiftLint before every commit                                                                |
| Build output | `xcbeautify --quieter`, so a failed build prints only the errors                                           |

**One-time setup** (if the VS Code extension isn't found, search "Swift" by swiftlang in the Extensions panel):

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
brew install xcodegen swiftlint swiftformat xcbeautify just
code --install-extension swiftlang.swift-vscode
```

**Daily commands**, wrapped in a `justfile` at the repo root so the AI runs one short command (`just build`, `just test`, `just run`). Replace `bundle` with the real bundle ID:

```text
set shell := ["bash", "-o", "pipefail", "-c"]
app := "Petal"
bundle := "com.example.petal"

default:
    just --list

gen:
    xcodegen generate

build: gen
    xcodebuild -scheme {{app}} -destination 'platform=macOS' -derivedDataPath build build | xcbeautify --quieter

test:
    swift test --package-path PetalKit

uitest: gen
    xcodebuild test -scheme {{app}} -destination 'platform=macOS' -derivedDataPath build | xcbeautify --quieter

run: build
    pkill -x {{app}} || true
    open build/Build/Products/Debug/{{app}}.app

lint:
    swiftformat . && swiftlint --fix

logs:
    log stream --level debug --predicate 'process == "{{app}}"'

shot:
    screencapture -x build/shot.png

reset:
    defaults delete {{bundle}} || true
    tccutil reset All {{bundle}}
```

**Phase 2 (iPhone and iPad simulator).** Get the device name from the first command:

```bash
xcrun simctl list devices available
xcrun simctl boot "DEVICE NAME"
xcodebuild -scheme PetalMobile -destination 'platform=iOS Simulator,name=DEVICE NAME' -derivedDataPath build build | xcbeautify --quieter
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/PetalMobile.app
xcrun simctl launch booted BUNDLE_ID
xcrun simctl io booted screenshot build/shot-ios.png
```

**Release (later):**

```bash
xcodebuild archive -scheme Petal -archivePath build/Petal.xcarchive
xcodebuild -exportArchive -archivePath build/Petal.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist
codesign --verify --deep --strict --verbose=2 build/export/Petal.app
ditto -c -k --keepParent build/export/Petal.app build/Petal.zip
xcrun notarytool submit build/Petal.zip --keychain-profile "petal-notary" --wait
xcrun stapler staple build/export/Petal.app
```

**Rules that save AI tokens and time:**

- Put the logic code (reminders, timer end-times, sync, note model) in `PetalKit` and verify it with `just test`, which runs in seconds, before running the app.
- Run `just build` after every change and read only the errors it prints; do not paste full logs.
- Check UI by running `just shot` and viewing the image, instead of describing the screen in words.
- One feature per prompt, commit after each green build, and ask the AI to update `AGENTS.md` when a decision changes.
- Never let the AI edit `.pbxproj`; changes go in `project.yml`, then `just gen`.

## Scope, metrics, open questions

v1 ships every P0 item above on macOS only. Not in v1: shared notes, AI summaries, Apple Reminders integration, desktop widgets. iPhone and iPad follow in phase 2 (section above).

| Proposed success metric                                              | Target           |
| -------------------------------------------------------------------- | ---------------- |
| First note created after install                                     | Under 30 seconds |
| Users who use a reminder, alarm, timer or voice note in week 1       | 40%              |
| Users who connect Drive and have a successful backup within 24 hours | 90%              |
| Crash-free sessions                                                  | 99.5%            |

**Open questions**

- [ ] Final name and mascot style?
- [ ] Mac App Store or direct download? Sandboxing affects alarms that must fire while the app is closed.
- [ ] Import existing Stickies in v1 or v1.1?
- [ ] Optional end-to-end encryption of the Drive backup?
