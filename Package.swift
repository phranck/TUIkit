// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

// SwiftLint runs as a build plugin on local builds only.
// Set DISABLE_SWIFTLINT=1 to skip it (used in CI where the
// prebuild plugin cannot execute binary artifacts).
let enableSwiftLint = ProcessInfo.processInfo.environment["DISABLE_SWIFTLINT"] == nil

let swiftLintPlugin: [Target.PluginUsage] = enableSwiftLint
    ? [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
    : []

let package = Package(
    name: "TUIKit",
    // Minimum deployment targets for Apple platforms
    // Linux is automatically supported (no platform specification needed)
    platforms: [
        .macOS(.v14)
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
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.58.2"),
    ],
    targets: [
        .target(
            name: "TUIKit",
            plugins: swiftLintPlugin
        ),
        .executableTarget(
            name: "TUIKitExample",
            dependencies: ["TUIKit"],
            plugins: swiftLintPlugin
        ),
        .testTarget(
            name: "TUIKitTests",
            dependencies: ["TUIKit"]
        ),
    ]
)
