// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let vendoredPNGSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v5),
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
]
let vendoredHashSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableExperimentalFeature("StrictConcurrency"),
    .define("DEBUG", .when(configuration: .debug)),
]

let package = Package(
    name: "TUIkit",
    // Minimum deployment targets for Apple platforms
    // Linux is automatically supported (no platform specification needed)
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // ── Low-level (no deps) ─────────────────────────────────────────────────────────────────────────
        .library(name: "TUIkitCore", targets: ["TUIkitCore"]),
        .library(name: "TUIkitStyling", targets: ["TUIkitStyling"]),

        // ── Mid-level ───────────────────────────────────────────────────────────────────────────────────
        .library(name: "TUIkitView", targets: ["TUIkitView"]),
        .library(name: "TUIkitImage", targets: ["TUIkitImage"]),

        // ── High-level (aggregates all) ─────────────────────────────────────────────────────────────────
        .library(name: "TUIkit", targets: ["TUIkit"]),

        // ── App ─────────────────────────────────────────────────────────────────────────────────────────
        .executable(name: "TUIkitExample", targets: ["TUIkitExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    ],
    targets: [
        // ── Vendored pure Swift image codecs ────────────────────────────────────────────────────────────
        .target(
            name: "TUIkitVendorBaseDigits",
            path: "Vendor/swift-hash/Sources/BaseDigits",
            swiftSettings: vendoredHashSettings
        ),
        .target(
            name: "TUIkitVendorBase16",
            dependencies: ["TUIkitVendorBaseDigits"],
            path: "Vendor/swift-hash/Sources/Base16",
            swiftSettings: vendoredHashSettings
        ),
        .target(
            name: "TUIkitVendorCRC",
            dependencies: ["TUIkitVendorBase16"],
            path: "Vendor/swift-hash/Sources/CRC",
            swiftSettings: vendoredHashSettings
        ),
        .target(
            name: "TUIkitVendorLZ77",
            dependencies: ["TUIkitVendorCRC"],
            path: "Vendor/swift-png/Sources/LZ77",
            swiftSettings: vendoredPNGSettings
        ),
        .target(
            name: "TUIkitVendorPNG",
            dependencies: ["TUIkitVendorLZ77", "TUIkitVendorCRC"],
            path: "Vendor/swift-png/Sources/PNG",
            swiftSettings: vendoredPNGSettings
        ),
        .target(
            name: "TUIkitVendorJPEG",
            path: "Vendor/swift-jpeg/Sources/JPEG",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        // ── Low-level (no deps) ─────────────────────────────────────────────────────────────────────────
        .target(name: "CSTBImage", publicHeadersPath: "include"),
        .target(name: "TUIkitCore"),
        .target(name: "TUIkitStyling"),

        // ── Mid-level ───────────────────────────────────────────────────────────────────────────────────
        .target(name: "TUIkitView", dependencies: ["TUIkitCore"]),
        .target(name: "TUIkitImage", dependencies: ["CSTBImage", "TUIkitStyling"]),

        // ── High-level (aggregates all) ─────────────────────────────────────────────────────────────────
        .target(
            name: "TUIkit",
            dependencies: ["TUIkitCore", "TUIkitStyling", "TUIkitImage", "TUIkitView"],
            resources: [.copy("Localization/translations"), .copy("VERSION")]
        ),

        // ── App & Tests ─────────────────────────────────────────────────────────────────────────────────
        .executableTarget(
            name: "TUIkitExample",
            dependencies: ["TUIkit"],
            resources: [.copy("Resources")]
        ),
        .target(
            name: "TUIkitTestSupport",
            path: "Tests/TUIkitTestSupport"
        ),
        .testTarget(
            name: "TUIkitTests",
            dependencies: ["TUIkit", "TUIkitTestSupport"]
        ),
    ]
)
