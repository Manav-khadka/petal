# AGENTS.md

Rules, architecture decisions, and workflow commands for Petal.

## Core Decisions & Tech Stack

- **Target OS**: macOS 14.0+ (Universal / arm64 & x86_64).
- **Language**: Swift 6.2 with strict concurrency (`Sendable`, `async/await`, no completion handlers).
- **Architecture**:
  - `PetalKit`: Local Swift package containing pure domain logic, scheduling algorithms, sync rules, and service protocols. Free of AppKit/UI dependencies.
  - `Petal`: Native macOS AppKit (`NSPanel`, `NSStatusItem`) + SwiftUI view layer with `@Observable` view models.
- **Project Generation**: XcodeGen via `project.yml`. Do NOT manually edit `.xcodeproj` or `.pbxproj`. Run `just gen` or `xcodegen generate`.
- **Styling**: Pastel colors, 16px corner radius, subtle paper curl, SF Pro Rounded, Caveat/handwritten title, cute mascot face.

## Daily Commands (`just`)

- `just gen`: Regenerate Xcode project from `project.yml`.
- `just build`: Build macOS target via xcodebuild.
- `just test`: Run `PetalKit` unit tests (`swift test --package-path PetalKit`).
- `just run`: Build and launch `Petal.app`.
- `just lint`: Format and lint Swift files.
- `just shot`: Capture a screen capture of running UI.
