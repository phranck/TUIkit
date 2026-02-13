// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

public let TUIkitVersion = "0.3.0"

let package = Package(
    name: "TUIkit",
    // Minimum deployment targets for Apple platforms
    // Linux is automatically supported (no platform specification needed)
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TUIkit",
            targets: ["TUIkit"]
        ),
        .executable(
            name: "TUIkitExample",
            targets: ["TUIkitExample"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        .target(
            name: "TUIkit"
        ),
        .executableTarget(
            name: "TUIkitExample",
            dependencies: ["TUIkit"]
        ),
        .testTarget(
            name: "TUIkitTests",
            dependencies: ["TUIkit"]
        ),
    ]
)
