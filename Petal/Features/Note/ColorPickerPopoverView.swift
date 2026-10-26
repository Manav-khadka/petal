import AppKit
import PetalKit
import SwiftUI

public struct ColorPickerPopoverView: View {
    @Bindable var viewModel: NoteViewModel
    @AppStorage("myColors") private var myColorsData: String = ""
    @State private var customHexInput: String = ""
    @State private var selectedNewFontChoice: String = "#1C1D21"

    public init(viewModel: NoteViewModel) {
        self.viewModel = viewModel
    }

    private struct CustomColorEntry: Hashable, Identifiable {
        let id: String
        let bgHex: String
        let fontHex: String

        init(raw: String) {
            let parts = raw.components(separatedBy: ":")
            let bg = NoteColor.normalize(hex: parts[0])
            let font: String
            if parts.count > 1 && !parts[1].isEmpty {
                font = NoteColor.normalize(hex: parts[1])
            } else {
                let temp = NoteColor(hex: bg)
                font = temp.requiresDarkText ? "#1C1D21" : "#F7F7F9"
            }
            self.id = "\(bg):\(font)"
            self.bgHex = bg
            self.fontHex = font
        }

        var rawString: String {
            "\(bgHex):\(fontHex)"
        }
    }

    private var myCustomColors: [CustomColorEntry] {
        myColorsData
            .components(separatedBy: ",")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { CustomColorEntry(raw: $0) }
    }

    private func saveCustomColor(bg: String, font: String) {
        var current = myCustomColors
        let entry = CustomColorEntry(raw: "\(bg):\(font)")
        if !current.contains(where: { $0.bgHex == entry.bgHex && $0.fontHex == entry.fontHex }) {
            current.insert(entry, at: 0)
            if current.count > 8 {
                current = Array(current.prefix(8))
            }
            myColorsData = current.map(\.rawString).joined(separator: ",")
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Note Theme")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                Text(viewModel.note.color.isCustom ? "Custom" : "Preset")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Presets section
            VStack(alignment: .leading, spacing: 5) {
                Text("Strict Presets (Charcoal Ink)")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(NoteColor.presets) { preset in
                        swatchButton(
                            color: Color(hex: preset.hex),
                            isSelected: !viewModel.note.color.isCustom && viewModel.note.color.hex == preset.hex
                        ) {
                            viewModel.setColor(preset)
                        }
                    }
                }
            }

            // If current note is a custom color: allow choosing its font color
            if viewModel.note.color.isCustom {
                Divider().opacity(0.15)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Font Ink Color")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Button(action: {
                            let updated = NoteColor(
                                hex: viewModel.note.color.hex,
                                name: viewModel.note.color.name,
                                isCustom: true,
                                customInkHex: "#1C1D21"
                            )
                            viewModel.setColor(updated)
                        }) {
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: "#1C1D21")).frame(width: 8, height: 8)
                                Text("Dark Ink")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4.5)
                            .background(
                                (viewModel.note.color.customInkHex == "#1C1D21" || (viewModel.note.color.customInkHex == nil && viewModel.note.color.requiresDarkText))
                                    ? Color.black.opacity(0.12)
                                    : Color.black.opacity(0.04)
                            )
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        Color.primary.opacity((viewModel.note.color.customInkHex == "#1C1D21" || (viewModel.note.color.customInkHex == nil && viewModel.note.color.requiresDarkText)) ? 0.35 : 0),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            let updated = NoteColor(
                                hex: viewModel.note.color.hex,
                                name: viewModel.note.color.name,
                                isCustom: true,
                                customInkHex: "#F7F7F9"
                            )
                            viewModel.setColor(updated)
                        }) {
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: "#F7F7F9")).frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.8))
                                Text("Light Ink")
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4.5)
                            .background(
                                (viewModel.note.color.customInkHex == "#F7F7F9" || (viewModel.note.color.customInkHex == nil && !viewModel.note.color.requiresDarkText))
                                    ? Color.black.opacity(0.12)
                                    : Color.black.opacity(0.04)
                            )
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        Color.primary.opacity((viewModel.note.color.customInkHex == "#F7F7F9" || (viewModel.note.color.customInkHex == nil && !viewModel.note.color.requiresDarkText)) ? 0.35 : 0),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // My Custom Themes
            if !myCustomColors.isEmpty {
                Divider().opacity(0.15)

                VStack(alignment: .leading, spacing: 5) {
                    Text("My Custom Themes")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        ForEach(myCustomColors) { entry in
                            let isSel = viewModel.note.color.isCustom &&
                                viewModel.note.color.hex == entry.bgHex &&
                                viewModel.note.color.inkHex == entry.fontHex

                            Button(action: {
                                viewModel.setColor(NoteColor(
                                    hex: entry.bgHex,
                                    name: "Custom",
                                    isCustom: true,
                                    customInkHex: entry.fontHex
                                ))
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: entry.bgHex))
                                        .frame(width: 22, height: 22)
                                        .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))

                                    // Inner dot showing the font color
                                    Circle()
                                        .fill(Color(hex: entry.fontHex))
                                        .frame(width: 6, height: 6)
                                        .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.5))

                                    if isSel {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 2)
                                            .frame(width: 26, height: 26)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .help("Custom \(entry.bgHex) with \(entry.fontHex == "#1C1D21" ? "Dark" : "Light") font")
                        }
                    }
                }
            }

            Divider().opacity(0.15)

            // Add Custom Theme with Font Selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Add Custom Theme")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    TextField("#HEX", text: $customHexInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 74)
                        .font(.system(size: 11, design: .monospaced))

                    // Font ink selection for the new custom color
                    Button(action: {
                        selectedNewFontChoice = (selectedNewFontChoice == "#1C1D21") ? "#F7F7F9" : "#1C1D21"
                    }) {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(Color(hex: selectedNewFontChoice))
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 0.5))
                            Text(selectedNewFontChoice == "#1C1D21" ? "Dark Font" : "Light Font")
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.06))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Toggle font color: Dark or Light ink")

                    Spacer()

                    Button("Add") {
                        let clean = customHexInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !clean.isEmpty {
                            let normalized = NoteColor.normalize(hex: clean)
                            saveCustomColor(bg: normalized, font: selectedNewFontChoice)
                            viewModel.setColor(NoteColor(
                                hex: normalized,
                                name: "Custom",
                                isCustom: true,
                                customInkHex: selectedNewFontChoice
                            ))
                            customHexInput = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))

                    Button {
                        NSColorPanel.shared.orderFront(nil)
                    } label: {
                        Image(systemName: "eyedropper.halffull")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("System Color Eyedropper")
                }
            }
        }
        .padding(Spacing.m)
        .frame(width: 250)
    }

    private func swatchButton(color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))

                if isSelected {
                    Circle()
                        .stroke(Color.primary, lineWidth: 2)
                        .frame(width: 26, height: 26)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
