import SwiftUI

public struct SparkleParticle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var scale: CGFloat
    public var opacity: Double
}

public struct SparkleBurstView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particles: [SparkleParticle] = []
    public var tint: Color

    public init(tint: Color = Color.orange) {
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            ForEach(particles) { p in
                Image(systemName: "sparkle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(tint)
                    .frame(width: 14 * p.scale, height: 14 * p.scale)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            triggerSparkles()
        }
    }

    private func triggerSparkles() {
        guard !reduceMotion else { return }
        var list: [SparkleParticle] = []
        for _ in 0 ..< 7 {
            let angle = Double.random(in: 0 ... (2 * .pi))
            let dist = CGFloat.random(in: 12 ... 28)
            let x = 16 + cos(angle) * dist
            let y = 16 + sin(angle) * dist
            list.append(SparkleParticle(x: x, y: y, scale: 0.2, opacity: 1.0))
        }
        particles = list

        withAnimation(.easeOut(duration: 0.55)) {
            particles = particles.map { p in
                var mod = p
                mod.scale = CGFloat.random(in: 0.8 ... 1.3)
                mod.opacity = 0.0
                return mod
            }
        }
    }
}
