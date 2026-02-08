// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "___VARIABLE_productName___",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIkit.git", branch: "main"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.0")
    ],
    targets: [
        .executableTarget(
            name: "___VARIABLE_productName___",
            dependencies: [
                .product(name: "TUIkit", package: "TUIkit"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources"
        )
    ]
)
