import SwiftUI

public struct PaperCurlShape: Shape {
    public var curlSize: CGFloat = 16

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top-left start
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: w, y: 0))
        path.addLine(to: CGPoint(x: w, y: h - curlSize))
        path.addLine(to: CGPoint(x: w - curlSize, y: h))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.closeSubpath()

        return path
    }
}

public struct PaperCurlOverlay: View {
    public var size: CGFloat = 18
    public var isDark: Bool = false

    public init(size: CGFloat = 18, isDark: Bool = false) {
        self.size = size
        self.isDark = isDark
    }

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            // Triangle curl
            Path { path in
                path.move(to: CGPoint(x: w - size, y: h))
                path.addLine(to: CGPoint(x: w, y: h - size))
                path.addLine(to: CGPoint(x: w - size, y: h - size))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [
                        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.08),
                        isDark ? Color.white.opacity(0.04) : Color.white.opacity(0.35)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: -1, y: -1)
        }
        .allowsHitTesting(false)
    }
}
