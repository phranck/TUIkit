// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftTUI",
    // Minimum deployment targets for Apple platforms
    // Linux is automatically supported (no platform specification needed)
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftTUI",
            targets: ["SwiftTUI"]
        ),
        .executable(
            name: "SwiftTUIExample",
            targets: ["SwiftTUIExample"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftTUI"
        ),
        .executableTarget(
            name: "SwiftTUIExample",
            dependencies: ["SwiftTUI"]
        ),
        .testTarget(
            name: "SwiftTUITests",
            dependencies: ["SwiftTUI"]
        ),
    ]
)
