// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TUIKit",
    // Minimum deployment targets for Apple platforms
    // Linux is automatically supported (no platform specification needed)
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "TUIKit",
            targets: ["TUIKit"]
        ),
        .executable(
            name: "TUIKitExample",
            targets: ["TUIKitExample"]
        ),
    ],
    targets: [
        .target(
            name: "TUIKit"
        ),
        .executableTarget(
            name: "TUIKitExample",
            dependencies: ["TUIKit"]
        ),
        .testTarget(
            name: "TUIKitTests",
            dependencies: ["TUIKit"]
        ),
    ]
)
