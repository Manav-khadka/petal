import SwiftUI

public enum MascotMood {
    case awake
    case sleeping
    case celebrating
}

public struct MascotFaceView: View {
    public var mood: MascotMood
    public var tint: Color
    public var size: CGFloat

    @State private var isBlinking = false
    @State private var blinkTimer: Timer?

    public init(mood: MascotMood = .awake, tint: Color = Color(hex: "#2C2D30"), size: CGFloat = 28) {
        self.mood = mood
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size * 0.28) {
            // Left Eye
            eyeView

            // Right Eye
            eyeView
        }
        .overlay(alignment: .bottom) {
            smileView
                .offset(y: size * 0.38)
        }
        .frame(width: size, height: size * 0.7)
        .onAppear {
            startBlinkLoop()
        }
        .onDisappear {
            blinkTimer?.invalidate()
        }
    }

    @ViewBuilder
    private var eyeView: some View {
        let eyeWidth = size * 0.16
        let eyeHeight = size * 0.38

        switch mood {
        case .awake:
            RoundedRectangle(cornerRadius: eyeWidth / 2)
                .fill(tint)
                .frame(width: eyeWidth, height: isBlinking ? 2 : eyeHeight)
                .animation(.easeInOut(duration: 0.12), value: isBlinking)

        case .sleeping:
            // Closed eye arc
            Circle()
                .trim(from: 0.5, to: 1.0)
                .stroke(tint, style: StrokeStyle(lineWidth: eyeWidth * 0.8, lineCap: .round))
                .frame(width: eyeWidth * 1.5, height: eyeHeight * 0.8)
                .offset(y: 2)

        case .celebrating:
            // Happy inverted arch ^
            Circle()
                .trim(from: 0.0, to: 0.5)
                .stroke(tint, style: StrokeStyle(lineWidth: eyeWidth * 0.8, lineCap: .round))
                .frame(width: eyeWidth * 1.5, height: eyeHeight * 0.8)
                .rotationEffect(.degrees(180))
        }
    }

    private var smileView: some View {
        let smileWidth = size * 0.34
        let smileHeight = size * 0.2

        return Circle()
            .trim(from: 0.1, to: 0.9)
            .stroke(tint, style: StrokeStyle(lineWidth: size * 0.11, lineCap: .round))
            .frame(width: smileWidth, height: smileHeight)
    }

    private func startBlinkLoop() {
        guard mood == .awake else { return }
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            Task { @MainActor in
                isBlinking = true
                try? await Task.sleep(nanoseconds: 140_000_000)
                isBlinking = false
            }
        }
    }
}
