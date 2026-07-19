#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=toolchain.env
source "$PROJECT_DIR/scripts/toolchain.env"

TOOL=""
PLATFORM=""
OUTPUT_ROOT=""
BUILD_PATH=""
CLANG_MODULE_PATH=""
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
        --tool|--platform|--output-root|--build-path|--clang-module-path)
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
        --platform) PLATFORM="$value" ;;
        --output-root) OUTPUT_ROOT="$value" ;;
        --build-path) BUILD_PATH="$value" ;;
        --clang-module-path) CLANG_MODULE_PATH="$value" ;;
    esac
done

[[ -n "$TOOL" ]] || fail "Missing required option: --tool"
[[ -n "$PLATFORM" ]] || fail "Missing required option: --platform"
[[ -n "$OUTPUT_ROOT" ]] || fail "Missing required option: --output-root"
[[ -n "$BUILD_PATH" ]] || fail "Missing required option: --build-path"
[[ -d "$OUTPUT_ROOT" ]] || fail "Directory not found for --output-root: $OUTPUT_ROOT"
if [[ -n "$CLANG_MODULE_PATH" && ! -d "$CLANG_MODULE_PATH" ]]; then
    fail "Directory not found for --clang-module-path: $CLANG_MODULE_PATH"
fi

HOST_SYSTEM="$(uname -s)"
case "$PLATFORM:$HOST_SYSTEM" in
    macOS:Darwin|Linux:Linux) ;;
    macOS:*|Linux:*) fail "Requested platform $PLATFORM does not match host $HOST_SYSTEM" ;;
    *) fail "Unsupported --platform: $PLATFORM" ;;
esac

COMPILER_VERSION="$(swiftc --version | sed -n '1p')"
if [[ "$COMPILER_VERSION" != *"Swift version $SWIFT_VERSION"* ]]; then
    fail "Expected Swift $SWIFT_VERSION, found $COMPILER_VERSION"
fi
TARGET="$(swiftc -print-target-info \
    | sed -n 's/.*"triple"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | sed -n '1p')"
[[ -n "$TARGET" ]] || fail "Unable to read the Swift target triple"

cd "$PROJECT_DIR"
swift build --build-path "$BUILD_PATH" -Xswiftc -warnings-as-errors
BIN_PATH="$(swift build --build-path "$BUILD_PATH" --show-bin-path)"
SWIFT_MODULE_PATH="$BIN_PATH/Modules"
[[ -d "$SWIFT_MODULE_PATH" ]] || fail "Swift module directory not found: $SWIFT_MODULE_PATH"

SDK_ARGUMENTS=()
case "$PLATFORM" in
    macOS)
        EXTRACTOR="$(xcrun --find swift-symbolgraph-extract)"
        SDK_NAME="macosx"
        SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"
        SDK_VERSION="$(xcrun --sdk "$SDK_NAME" --show-sdk-version)"
        SDK_BUILD="$(xcrun --sdk "$SDK_NAME" --show-sdk-build-version)"
        SDK_ARGUMENTS+=(--sdk-path "$SDK_PATH")
        PLATFORM_ID="macos"
        ;;
    Linux)
        EXTRACTOR="$(command -v swift-symbolgraph-extract 2>/dev/null || true)"
        [[ -n "$EXTRACTOR" ]] || fail "swift-symbolgraph-extract is not available"
        SDK_NAME="swift-linux"
        SDK_VERSION="$SWIFT_VERSION"
        SDK_BUILD="${SWIFT_LINUX_IMAGE##*@sha256:}"
        PLATFORM_ID="linux"
        ;;
esac

if [[ -n "$CLANG_MODULE_PATH" ]]; then
    SDK_ARGUMENTS+=(--clang-module-path "$CLANG_MODULE_PATH")
fi

for module in TUIkit TUIkitCore TUIkitImage TUIkitStyling TUIkitView; do
    module_id="$(printf '%s' "$module" | tr '[:upper:]' '[:lower:]')"
    SOURCE_ARGUMENTS=(
        --tool "$TOOL"
        --extractor "$EXTRACTOR"
        --module "$module"
        --source-id "$module_id-$PLATFORM_ID-swift-$SWIFT_VERSION"
        --platform "$PLATFORM"
        --target "$TARGET"
        --sdk-name "$SDK_NAME"
        --sdk-version "$SDK_VERSION"
        --sdk-build "$SDK_BUILD"
        --compiler-version "$COMPILER_VERSION"
        --output-root "$OUTPUT_ROOT"
        --swift-module-path "$SWIFT_MODULE_PATH"
    )
    if [[ ${#SDK_ARGUMENTS[@]} -gt 0 ]]; then
        SOURCE_ARGUMENTS+=("${SDK_ARGUMENTS[@]}")
    fi
    "$PROJECT_DIR/scripts/generate-api-snapshot-source.sh" "${SOURCE_ARGUMENTS[@]}"
done
