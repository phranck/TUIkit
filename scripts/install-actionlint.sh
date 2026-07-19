#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=toolchain.env
source "$PROJECT_DIR/scripts/toolchain.env"

TARGET="${1:-}"
TOOL_CACHE="${TUIKIT_TOOL_CACHE:-$PROJECT_DIR/.build/tooling}"

case "$TARGET" in
    macos)
        case "$(uname -m)" in
            x86_64)
                ASSET_PLATFORM="darwin_amd64"
                ARCHIVE_SHA256="$ACTIONLINT_MACOS_AMD64_SHA256"
                BINARY_SHA256="$ACTIONLINT_MACOS_AMD64_BINARY_SHA256"
                ;;
            arm64)
                ASSET_PLATFORM="darwin_arm64"
                ARCHIVE_SHA256="$ACTIONLINT_MACOS_ARM64_SHA256"
                BINARY_SHA256="$ACTIONLINT_MACOS_ARM64_BINARY_SHA256"
                ;;
            *)
                echo "Unsupported macOS architecture: $(uname -m)" >&2
                exit 1
                ;;
        esac
        ;;
    linux-amd64)
        ASSET_PLATFORM="linux_amd64"
        ARCHIVE_SHA256="$ACTIONLINT_LINUX_AMD64_SHA256"
        BINARY_SHA256="$ACTIONLINT_LINUX_AMD64_BINARY_SHA256"
        ;;
    *)
        echo "Usage: $0 [macos|linux-amd64]" >&2
        exit 2
        ;;
esac

INSTALL_DIR="$TOOL_CACHE/actionlint/$ACTIONLINT_VERSION/$ASSET_PLATFORM"
ACTIONLINT_BIN="$INSTALL_DIR/actionlint"

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

if [[ -x "$ACTIONLINT_BIN" ]]; then
    [[ "$(sha256_file "$ACTIONLINT_BIN")" == "$BINARY_SHA256" ]] || {
        echo "actionlint cached binary checksum mismatch" >&2
        exit 1
    }
    if [[ "$TARGET" == "linux-amd64" ]] || [[ "$($ACTIONLINT_BIN -version | sed -n '1p')" == "$ACTIONLINT_VERSION" ]]; then
        printf '%s\n' "$ACTIONLINT_BIN"
        exit 0
    fi
fi

for required_tool in curl tar; do
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

ARCHIVE_NAME="actionlint_${ACTIONLINT_VERSION}_${ASSET_PLATFORM}.tar.gz"
ARCHIVE_URL="https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/${ARCHIVE_NAME}"
ARCHIVE_PATH="$TEMP_DIR/$ARCHIVE_NAME"
curl --proto '=https' --tlsv1.2 --fail --silent --show-error --location \
    "$ARCHIVE_URL" --output "$ARCHIVE_PATH"

ACTUAL_SHA256="$(sha256_file "$ARCHIVE_PATH")"
[[ "$ACTUAL_SHA256" == "$ARCHIVE_SHA256" ]] || {
    echo "actionlint archive checksum mismatch" >&2
    exit 1
}

mkdir -p "$INSTALL_DIR"
tar -xzf "$ARCHIVE_PATH" -C "$INSTALL_DIR" actionlint
chmod +x "$ACTIONLINT_BIN"
[[ "$(sha256_file "$ACTIONLINT_BIN")" == "$BINARY_SHA256" ]] || {
    echo "actionlint extracted binary checksum mismatch" >&2
    exit 1
}
if [[ "$TARGET" == "macos" ]]; then
    [[ "$($ACTIONLINT_BIN -version | sed -n '1p')" == "$ACTIONLINT_VERSION" ]] || {
        echo "Installed actionlint version does not match $ACTIONLINT_VERSION" >&2
        exit 1
    }
fi

printf '%s\n' "$ACTIONLINT_BIN"
