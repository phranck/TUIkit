#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=toolchain.env
source "$PROJECT_DIR/scripts/toolchain.env"

TOOL=""
DEVELOPER_DIR_PATH=""
OUTPUT_ROOT=""
SEEN_OPTIONS="|"

fail() {
    echo "$1" >&2
    exit 2
}

mark_option() {
    local option="$1"
    case "$SEEN_OPTIONS" in
        *"|$option|"*) fail "Duplicate option: $option" ;;
    esac
    SEEN_OPTIONS="${SEEN_OPTIONS}${option}|"
}

while [[ $# -gt 0 ]]; do
    option="$1"
    case "$option" in
        --tool|--developer-dir|--output-root)
            [[ $# -ge 2 && -n "${2:-}" ]] || fail "Missing value for $option"
            mark_option "$option"
            value="$2"
            shift 2
            ;;
        *)
            fail "Unknown option: $option"
            ;;
    esac

    case "$option" in
        --tool) TOOL="$value" ;;
        --developer-dir) DEVELOPER_DIR_PATH="$value" ;;
        --output-root) OUTPUT_ROOT="$value" ;;
    esac
done

[[ -n "$TOOL" ]] || fail "Missing required option: --tool"
[[ -n "$DEVELOPER_DIR_PATH" ]] || fail "Missing required option: --developer-dir"
[[ -n "$OUTPUT_ROOT" ]] || fail "Missing required option: --output-root"
[[ -d "$DEVELOPER_DIR_PATH" ]] || fail "Directory not found for --developer-dir: $DEVELOPER_DIR_PATH"
[[ -d "$OUTPUT_ROOT" ]] || fail "Directory not found for --output-root: $OUTPUT_ROOT"

export DEVELOPER_DIR="$DEVELOPER_DIR_PATH"

XCODE_VERSION_OUTPUT="$(xcodebuild -version)"
ACTUAL_XCODE_VERSION="$(printf '%s\n' "$XCODE_VERSION_OUTPUT" | sed -n '1s/^Xcode //p')"
ACTUAL_XCODE_BUILD="$(printf '%s\n' "$XCODE_VERSION_OUTPUT" | sed -n '2s/^Build version //p')"
if [[ "$ACTUAL_XCODE_VERSION" != "$SWIFTUI_REFERENCE_XCODE_VERSION" \
    || "$ACTUAL_XCODE_BUILD" != "$SWIFTUI_REFERENCE_XCODE_BUILD" ]]; then
    fail "Expected Xcode $SWIFTUI_REFERENCE_XCODE_VERSION ($SWIFTUI_REFERENCE_XCODE_BUILD), found Xcode $ACTUAL_XCODE_VERSION ($ACTUAL_XCODE_BUILD)"
fi

EXTRACTOR="$(xcrun --find swift-symbolgraph-extract)"
COMPILER_VERSION="$(xcrun swiftc --version | sed -n '1p')"
[[ -n "$COMPILER_VERSION" ]] || fail "Unable to read the reference Swift compiler version"

generate_platform() {
    local platform="$1"
    local sdk_name="$2"
    local target_prefix="$3"
    local sdk_path
    local sdk_version
    local sdk_build
    sdk_path="$(xcrun --sdk "$sdk_name" --show-sdk-path)"
    sdk_version="$(xcrun --sdk "$sdk_name" --show-sdk-version)"
    sdk_build="$(xcrun --sdk "$sdk_name" --show-sdk-build-version)"

    local module
    for module in SwiftUI SwiftUICore; do
        local module_id
        local platform_id
        local source_id
        module_id="$(printf '%s' "$module" | tr '[:upper:]' '[:lower:]')"
        platform_id="$(printf '%s' "$platform" | tr '[:upper:]' '[:lower:]')"
        source_id="$module_id-$platform_id-xcode-$SWIFTUI_REFERENCE_XCODE_VERSION"
        "$PROJECT_DIR/scripts/generate-api-snapshot-source.sh" \
            --tool "$TOOL" \
            --extractor "$EXTRACTOR" \
            --module "$module" \
            --source-id "$source_id" \
            --platform "$platform" \
            --target "$target_prefix$sdk_version" \
            --sdk-name "$sdk_name" \
            --sdk-version "$sdk_version" \
            --sdk-build "$sdk_build" \
            --compiler-version "$COMPILER_VERSION" \
            --output-root "$OUTPUT_ROOT" \
            --sdk-path "$sdk_path"
    done
}

generate_platform macOS macosx arm64-apple-macosx
generate_platform iOS iphoneos arm64-apple-ios
generate_platform tvOS appletvos arm64-apple-tvos
generate_platform watchOS watchos arm64_32-apple-watchos
generate_platform visionOS xros arm64-apple-xros

"$PROJECT_DIR/scripts/assemble-api-snapshot-set.sh" \
    --tool "$TOOL" \
    --name "SwiftUI Xcode $SWIFTUI_REFERENCE_XCODE_VERSION ($SWIFTUI_REFERENCE_XCODE_BUILD)" \
    --coverage "$PROJECT_DIR/Tools/APICompatibility/Configuration/reference-coverage.tsv" \
    --output-root "$OUTPUT_ROOT"
