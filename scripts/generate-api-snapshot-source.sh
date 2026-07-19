#!/usr/bin/env bash

set -euo pipefail

TOOL=""
EXTRACTOR=""
MODULE=""
SOURCE_ID=""
PLATFORM=""
TARGET=""
SDK_NAME=""
SDK_VERSION=""
SDK_BUILD=""
COMPILER_VERSION=""
OUTPUT_ROOT=""
SDK_PATH=""
SWIFT_MODULE_PATH=""
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

require_value() {
    local option="$1"
    local count="$2"
    local value="${3:-}"
    [[ "$count" -ge 2 && -n "$value" ]] || fail "Missing value for $option"
}

while [[ $# -gt 0 ]]; do
    option="$1"
    case "$option" in
        --tool|--extractor|--module|--source-id|--platform|--target|--sdk-name|--sdk-version|--sdk-build|--compiler-version|--output-root|--sdk-path|--swift-module-path|--clang-module-path)
            require_value "$option" "$#" "${2:-}"
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
        --extractor) EXTRACTOR="$value" ;;
        --module) MODULE="$value" ;;
        --source-id) SOURCE_ID="$value" ;;
        --platform) PLATFORM="$value" ;;
        --target) TARGET="$value" ;;
        --sdk-name) SDK_NAME="$value" ;;
        --sdk-version) SDK_VERSION="$value" ;;
        --sdk-build) SDK_BUILD="$value" ;;
        --compiler-version) COMPILER_VERSION="$value" ;;
        --output-root) OUTPUT_ROOT="$value" ;;
        --sdk-path) SDK_PATH="$value" ;;
        --swift-module-path) SWIFT_MODULE_PATH="$value" ;;
        --clang-module-path) CLANG_MODULE_PATH="$value" ;;
    esac
done

require_option() {
    local value="$1"
    local option="$2"
    [[ -n "$value" ]] || fail "Missing required option: $option"
}

require_option "$TOOL" --tool
require_option "$EXTRACTOR" --extractor
require_option "$MODULE" --module
require_option "$SOURCE_ID" --source-id
require_option "$PLATFORM" --platform
require_option "$TARGET" --target
require_option "$SDK_NAME" --sdk-name
require_option "$SDK_VERSION" --sdk-version
require_option "$SDK_BUILD" --sdk-build
require_option "$COMPILER_VERSION" --compiler-version
require_option "$OUTPUT_ROOT" --output-root

if [[ ! "$SOURCE_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    fail "Invalid --source-id: $SOURCE_ID"
fi

validate_metadata() {
    local option="$1"
    local value="$2"
    case "$value" in
        *$'\t'*|*$'\r'*|*$'\n'*) fail "Invalid control character in $option" ;;
        [[:space:]]*|*[[:space:]]) fail "Padded value for $option" ;;
    esac
}

validate_metadata --module "$MODULE"
validate_metadata --source-id "$SOURCE_ID"
validate_metadata --platform "$PLATFORM"
validate_metadata --target "$TARGET"
validate_metadata --sdk-name "$SDK_NAME"
validate_metadata --sdk-version "$SDK_VERSION"
validate_metadata --sdk-build "$SDK_BUILD"
validate_metadata --compiler-version "$COMPILER_VERSION"

resolve_executable() {
    local option="$1"
    local executable="$2"
    local resolved=""
    if [[ "$executable" == */* ]]; then
        [[ -f "$executable" && -x "$executable" ]] || {
            fail "Executable not found for $option: $executable"
        }
        printf '%s\n' "$executable"
        return
    fi
    resolved="$(command -v "$executable" 2>/dev/null || true)"
    [[ -n "$resolved" && -f "$resolved" && -x "$resolved" ]] || {
        fail "Executable not found for $option: $executable"
    }
    printf '%s\n' "$resolved"
}

require_directory() {
    local option="$1"
    local directory="$2"
    [[ -d "$directory" ]] || fail "Directory not found for $option: $directory"
}

TOOL="$(resolve_executable --tool "$TOOL")"
EXTRACTOR="$(resolve_executable --extractor "$EXTRACTOR")"
require_directory --output-root "$OUTPUT_ROOT"
if [[ -n "$SDK_PATH" ]]; then
    require_directory --sdk-path "$SDK_PATH"
fi
if [[ -n "$SWIFT_MODULE_PATH" ]]; then
    require_directory --swift-module-path "$SWIFT_MODULE_PATH"
fi
if [[ -n "$CLANG_MODULE_PATH" ]]; then
    require_directory --clang-module-path "$CLANG_MODULE_PATH"
fi

RAW_PARENT="$OUTPUT_ROOT/raw"
SNAPSHOT_PARENT="$OUTPUT_ROOT/snapshots"
SOURCE_PARENT="$OUTPUT_ROOT/sources"
RAW_OUTPUT="$RAW_PARENT/$SOURCE_ID"
SNAPSHOT_OUTPUT="$SNAPSHOT_PARENT/$SOURCE_ID.json"
SOURCE_OUTPUT="$SOURCE_PARENT/$SOURCE_ID.tsv"

mkdir -p "$RAW_PARENT" "$SNAPSHOT_PARENT" "$SOURCE_PARENT"
for output in "$RAW_OUTPUT" "$SNAPSHOT_OUTPUT" "$SOURCE_OUTPUT"; do
    [[ ! -e "$output" && ! -L "$output" ]] || fail "Output already exists: $output"
done
mkdir "$RAW_OUTPUT"

EXTRACT_ARGUMENTS=(
    extract
    --extractor "$EXTRACTOR"
    --module "$MODULE"
    --target "$TARGET"
    --output "$RAW_OUTPUT"
)
if [[ -n "$SDK_PATH" ]]; then
    EXTRACT_ARGUMENTS+=(--sdk "$SDK_PATH")
fi
if [[ -n "$SWIFT_MODULE_PATH" ]]; then
    EXTRACT_ARGUMENTS+=(--swift-module-path "$SWIFT_MODULE_PATH")
fi
if [[ -n "$CLANG_MODULE_PATH" ]]; then
    EXTRACT_ARGUMENTS+=(--clang-module-path "$CLANG_MODULE_PATH")
fi

"$TOOL" "${EXTRACT_ARGUMENTS[@]}"
"$TOOL" canonicalize \
    --module "$MODULE" \
    --symbol-graphs "$RAW_OUTPUT" \
    --output "$SNAPSHOT_OUTPUT" \
    --extension-provenance strict \
    --platform "$PLATFORM" \
    --target "$TARGET" \
    --sdk-name "$SDK_NAME" \
    --sdk-version "$SDK_VERSION" \
    --sdk-build "$SDK_BUILD" \
    --compiler-version "$COMPILER_VERSION"

[[ -f "$SNAPSHOT_OUTPUT" ]] || fail "Snapshot was not created: $SNAPSHOT_OUTPUT"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$SOURCE_ID" \
    "$MODULE" \
    "$PLATFORM" \
    "$TARGET" \
    "$SDK_NAME" \
    "$SDK_VERSION" \
    "$SDK_BUILD" \
    "$COMPILER_VERSION" \
    "snapshots/$SOURCE_ID.json" \
    > "$SOURCE_OUTPUT"
