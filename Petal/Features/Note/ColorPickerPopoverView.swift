import AppKit
import PetalKit
import SwiftUI

public struct ColorPickerPopoverView: View {
    @Bindable var viewModel: NoteViewModel
    @AppStorage("myColors") private var myColorsData: String = ""
    @State private var customHexInput: String = ""

    public init(viewModel: NoteViewModel) {
        self.viewModel = viewModel
    }

    private var myColors: [String] {
        myColorsData.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    private func saveCustomColor(_ hex: String) {
        var current = myColors
        let normalized = NoteColor.normalize(hex: hex)
        if !current.contains(normalized) {
            current.insert(normalized, at: 0)
            if current.count > 8 {
                current = Array(current.prefix(8))
            }
            myColorsData = current.joined(separator: ",")
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Note Color")
                .font(.system(.subheadline, design: .rounded).bold())

            // 6 Presets
            HStack(spacing: 8) {
                ForEach(NoteColor.presets) { preset in
                    swatchButton(color: Color(hex: preset.hex), isSelected: viewModel.note.color.hex == preset.hex) {
                        viewModel.setColor(preset)
                    }
                }
            }

            // My Colors Row
            if !myColors.isEmpty {
                Divider()
                Text("My Colors")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack(spacing: 6) {
                    ForEach(myColors, id: \.self) { hex in
                        swatchButton(color: Color(hex: hex), isSelected: viewModel.note.color.hex == hex) {
                            viewModel.setColor(NoteColor(hex: hex, isCustom: true))
                        }
                    }
                }
            }

            Divider()

            // Hex input / System picker
            HStack(spacing: 6) {
                TextField("#HEX", text: $customHexInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .font(.system(.caption, design: .monospaced))

                Button("Add") {
                    if !customHexInput.isEmpty {
                        let normalized = NoteColor.normalize(hex: customHexInput)
                        saveCustomColor(normalized)
                        viewModel.setColor(NoteColor(hex: normalized, isCustom: true))
                        customHexInput = ""
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)

                Spacer()

                Button {
                    NSColorPanel.shared.orderFront(nil)
                } label: {
                    Image(systemName: "eyedropper.halffull")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Spacing.m)
        .frame(width: 220)
    }

    private func swatchButton(color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))

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
