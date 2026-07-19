#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=toolchain.env
source "$PROJECT_DIR/scripts/toolchain.env"

TARGET="${1:-}"
TOOL_CACHE="${TUIKIT_TOOL_CACHE:-$PROJECT_DIR/.build/tooling}"

case "$TARGET" in
    macos)
        ARCHIVE_URL="$SWIFTLINT_MACOS_URL"
        ARCHIVE_SHA256="$SWIFTLINT_MACOS_SHA256"
        BINARY_SHA256="$SWIFTLINT_MACOS_BINARY_SHA256"
        ;;
    linux-amd64)
        ARCHIVE_URL="$SWIFTLINT_LINUX_AMD64_URL"
        ARCHIVE_SHA256="$SWIFTLINT_LINUX_AMD64_SHA256"
        BINARY_SHA256="$SWIFTLINT_LINUX_AMD64_BINARY_SHA256"
        ;;
    *)
        echo "Usage: $0 [macos|linux-amd64]" >&2
        exit 2
        ;;
esac

INSTALL_DIR="$TOOL_CACHE/swiftlint/$SWIFTLINT_VERSION/$TARGET"
SWIFTLINT_BIN="$INSTALL_DIR/swiftlint"

sha256_file() {
    local file="$1"

    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" | awk '{ print $1 }'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$file" | awk '{ print $1 }'
    else
        echo "Required checksum tool is missing: sha256sum or shasum" >&2
        exit 1
    fi
}

if [[ -x "$SWIFTLINT_BIN" ]]; then
    [[ "$(sha256_file "$SWIFTLINT_BIN")" == "$BINARY_SHA256" ]] || {
        echo "SwiftLint cached binary checksum mismatch" >&2
        exit 1
    }
    if [[ "$TARGET" == "linux-amd64" ]] || [[ "$($SWIFTLINT_BIN version)" == "$SWIFTLINT_VERSION" ]]; then
        printf '%s\n' "$SWIFTLINT_BIN"
        exit 0
    fi
fi

for required_tool in curl unzip; do
    if ! command -v "$required_tool" >/dev/null 2>&1; then
        echo "Required tool is missing: $required_tool" >&2
        exit 1
    fi
done

TEMP_DIR="$(mktemp -d)"
cleanup() {
    find "$TEMP_DIR" -type f -delete
    find "$TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

ARCHIVE_PATH="$TEMP_DIR/swiftlint.zip"
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    "$ARCHIVE_URL" --output "$ARCHIVE_PATH"

ACTUAL_SHA256="$(sha256_file "$ARCHIVE_PATH")"
[[ "$ACTUAL_SHA256" == "$ARCHIVE_SHA256" ]] || {
    echo "SwiftLint archive checksum mismatch" >&2
    exit 1
}

mkdir -p "$INSTALL_DIR"
unzip -q -o "$ARCHIVE_PATH" swiftlint -d "$INSTALL_DIR"
chmod +x "$SWIFTLINT_BIN"
[[ "$(sha256_file "$SWIFTLINT_BIN")" == "$BINARY_SHA256" ]] || {
    echo "SwiftLint extracted binary checksum mismatch" >&2
    exit 1
}

if [[ "$TARGET" == "macos" ]]; then
    ACTUAL_VERSION="$($SWIFTLINT_BIN version)"
    if [[ "$ACTUAL_VERSION" != "$SWIFTLINT_VERSION" ]]; then
        echo "Expected SwiftLint $SWIFTLINT_VERSION, found $ACTUAL_VERSION" >&2
        exit 1
    fi
fi

printf '%s\n' "$SWIFTLINT_BIN"
