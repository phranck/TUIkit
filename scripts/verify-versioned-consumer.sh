#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
PACKAGE_REPOSITORY="$TEMP_DIR/TUIkit"
CONSUMER_DIR="$TEMP_DIR/Consumer"

cleanup() {
    find "$TEMP_DIR" -type f -delete
    find "$TEMP_DIR" -type l -delete
    find "$TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

mkdir -p "$PACKAGE_REPOSITORY" "$CONSUMER_DIR/Sources/Consumer"
cp "$PROJECT_DIR/Package.swift" "$PROJECT_DIR/Package.resolved" "$PACKAGE_REPOSITORY/"
cp -R "$PROJECT_DIR/Sources" "$PROJECT_DIR/Tests" "$PROJECT_DIR/Vendor" "$PACKAGE_REPOSITORY/"

git -C "$PACKAGE_REPOSITORY" init --quiet
git -C "$PACKAGE_REPOSITORY" config user.name "TUIkit Consumer Gate"
git -C "$PACKAGE_REPOSITORY" config user.email "consumer-gate@localhost"
git -C "$PACKAGE_REPOSITORY" add Package.swift Package.resolved Sources Tests Vendor
git -C "$PACKAGE_REPOSITORY" commit --quiet -m "Test versioned package"
git -C "$PACKAGE_REPOSITORY" tag 1.0.0

cat > "$CONSUMER_DIR/Package.swift" <<EOF
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TUIkitConsumer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "file://$PACKAGE_REPOSITORY", exact: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Consumer",
            dependencies: [
                .product(name: "TUIkit", package: "TUIkit"),
            ]
        ),
    ]
)
EOF

cat > "$CONSUMER_DIR/Sources/Consumer/main.swift" <<'EOF'
import TUIkit

print("TUIkit versioned consumer resolved")
EOF

swift package --package-path "$CONSUMER_DIR" resolve
swift build --package-path "$CONSUMER_DIR"

echo "Versioned SwiftPM consumer gate passed"
