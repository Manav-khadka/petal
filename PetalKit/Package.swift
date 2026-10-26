// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PetalKit",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PetalKit",
            targets: ["PetalKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PetalKit",
            dependencies: [],
            path: "Sources/PetalKit"
        ),
        .testTarget(
            name: "PetalKitTests",
            dependencies: ["PetalKit"],
            path: "Tests/PetalKitTests"
        )
    ]
)
