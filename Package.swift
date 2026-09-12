// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ScrollBack",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ScrollBack",
            path: "Sources/ScrollBack"
        )
    ]
)
