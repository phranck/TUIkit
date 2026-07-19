// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BoundaryFixture",
    targets: [
        .testTarget(name: "TUIkitCoreTests", dependencies: ["TUIkitCore"]),
        .testTarget(name: "TUIkitStylingTests", dependencies: ["TUIkitStyling"]),
        .testTarget(name: "TUIkitViewTests", dependencies: ["TUIkitCore", "TUIkitView"]),
        .testTarget(name: "TUIkitImageTests", dependencies: ["TUIkitImage"]),
    ]
)
