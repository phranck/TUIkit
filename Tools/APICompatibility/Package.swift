// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "APICompatibility",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "APICompatibilityKit", targets: ["APICompatibilityKit"]),
        .executable(name: "TUIkitAPICheck", targets: ["TUIkitAPICheck"]),
    ],
    targets: [
        .target(name: "APICompatibilityKit"),
        .executableTarget(
            name: "TUIkitAPICheck",
            dependencies: ["APICompatibilityKit"]
        ),
        .testTarget(
            name: "APICompatibilityKitTests",
            dependencies: ["APICompatibilityKit"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
