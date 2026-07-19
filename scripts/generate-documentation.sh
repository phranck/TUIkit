#!/usr/bin/env bash
#
# Generates the deployable TUIkit DocC archive.
#
# Usage:
#   ./scripts/generate-documentation.sh [output-path]
#
# The output path defaults to docc-output in the repository root.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_PATH="${1:-docc-output}"
SYMBOL_GRAPH_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tuikit-docc-symbols.XXXXXX")"

cleanup() {
    find "$SYMBOL_GRAPH_DIR" -type f -delete
    find "$SYMBOL_GRAPH_DIR" -depth -type d -delete
}
trap cleanup EXIT

cd "$PROJECT_DIR"

SWIFT_BUILD_ARGUMENTS=()
if [[ -n "${TUIKIT_BUILD_PATH:-}" ]]; then
    SWIFT_BUILD_ARGUMENTS+=(--build-path "$TUIKIT_BUILD_PATH")
fi

swift build "${SWIFT_BUILD_ARGUMENTS[@]}" --target TUIkit -Xswiftc -warnings-as-errors
BIN_PATH="$(swift build "${SWIFT_BUILD_ARGUMENTS[@]}" --show-bin-path)"
if [[ -e "$BIN_PATH/Modules/TUIkit.swiftmodule" ]]; then
    MODULES_PATH="$BIN_PATH/Modules"
elif [[ -e "$BIN_PATH/TUIkit.swiftmodule" ]]; then
    MODULES_PATH="$BIN_PATH"
else
    echo "Unable to find the built TUIkit module below $BIN_PATH" >&2
    exit 1
fi

TARGET_TRIPLE="$(swift -print-target-info | awk -F'"' '/"triple"/ { print $4; exit }')"
if [[ -z "$TARGET_TRIPLE" ]]; then
    echo "Unable to determine the Swift target triple" >&2
    exit 1
fi

SYMBOLGRAPH_EXTRACT=(swift-symbolgraph-extract)
DOCC=(docc)
SDK_ARGUMENTS=()
if [[ "$(uname -s)" == "Darwin" ]]; then
    SYMBOLGRAPH_EXTRACT=(xcrun swift-symbolgraph-extract)
    DOCC=(xcrun docc)
    SDK_ARGUMENTS=(-sdk "$(xcrun --show-sdk-path)")
fi

"${SYMBOLGRAPH_EXTRACT[@]}" \
    -module-name TUIkit \
    -I "$MODULES_PATH" \
    -target "$TARGET_TRIPLE" \
    -output-dir "$SYMBOL_GRAPH_DIR" \
    -minimum-access-level public \
    -experimental-allowed-reexported-modules=TUIkitCore,TUIkitStyling,TUIkitImage,TUIkitView \
    "${SDK_ARGUMENTS[@]}"

"${DOCC[@]}" convert Sources/TUIkit/TUIkit.docc \
    --additional-symbol-graph-dir "$SYMBOL_GRAPH_DIR" \
    --output-path "$OUTPUT_PATH" \
    --transform-for-static-hosting \
    --warnings-as-errors

cp Sources/TUIkit/TUIkit.docc/theme-overrides.css "$OUTPUT_PATH/theme-overrides.css"

swift -warnings-as-errors - "$OUTPUT_PATH" <<'SWIFT'
import Foundation

let fileManager = FileManager.default
let outputURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let stylesheet = #"<link rel="stylesheet" href="/theme-overrides.css">"#

guard let enumerator = fileManager.enumerator(
    at: outputURL,
    includingPropertiesForKeys: nil
) else {
    fatalError("Unable to enumerate \(outputURL.path)")
}

for case let path as URL in enumerator where path.pathExtension == "html" {
    var content = try String(contentsOf: path, encoding: .utf8)
    guard !content.contains(stylesheet), content.contains("</head>") else { continue }
    content = content.replacingOccurrences(
        of: "</head>",
        with: "  \(stylesheet)\n</head>"
    )
    try content.write(to: path, atomically: true, encoding: .utf8)
}

let indexURL = outputURL.appendingPathComponent("index.html")
let fallbackURL = outputURL.appendingPathComponent("404.html")
if fileManager.fileExists(atPath: fallbackURL.path) {
    try fileManager.removeItem(at: fallbackURL)
}
try fileManager.copyItem(at: indexURL, to: fallbackURL)

let redirect = """
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=/documentation/tuikit/">
  <link rel="canonical" href="/documentation/tuikit/">
  <title>Redirecting to TUIkit Documentation</title>
</head>
<body>
  <p>Redirecting to <a href="/documentation/tuikit/">TUIkit Documentation</a>...</p>
</body>
</html>
"""
try redirect.write(to: indexURL, atomically: true, encoding: .utf8)
SWIFT
