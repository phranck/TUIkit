#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=toolchain.env
source "$PROJECT_DIR/scripts/toolchain.env"

SWIFTLINT_BIN="${SWIFTLINT_BIN:-${1:-}}"
if [[ -z "$SWIFTLINT_BIN" || ! -x "$SWIFTLINT_BIN" ]]; then
    echo "SWIFTLINT_BIN must point to an executable SwiftLint binary" >&2
    exit 1
fi

ACTIONLINT_BIN="${ACTIONLINT_BIN:-${2:-}}"
if [[ -z "$ACTIONLINT_BIN" || ! -x "$ACTIONLINT_BIN" ]]; then
    echo "ACTIONLINT_BIN must point to an executable actionlint binary" >&2
    exit 1
fi

ACTUAL_SWIFT_VERSION="$(swift --version | sed -nE 's/.*Swift version ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' | sed -n '1p')"
if [[ "$ACTUAL_SWIFT_VERSION" != "$SWIFT_VERSION" ]]; then
    echo "Expected Swift $SWIFT_VERSION, found ${ACTUAL_SWIFT_VERSION:-unknown}" >&2
    exit 1
fi

ACTUAL_SWIFTLINT_VERSION="$($SWIFTLINT_BIN version)"
if [[ "$ACTUAL_SWIFTLINT_VERSION" != "$SWIFTLINT_VERSION" ]]; then
    echo "Expected SwiftLint $SWIFTLINT_VERSION, found $ACTUAL_SWIFTLINT_VERSION" >&2
    exit 1
fi

ACTUAL_ACTIONLINT_VERSION="$($ACTIONLINT_BIN -version | sed -n '1p')"
if [[ "$ACTUAL_ACTIONLINT_VERSION" != "$ACTIONLINT_VERSION" ]]; then
    echo "Expected actionlint $ACTIONLINT_VERSION, found $ACTUAL_ACTIONLINT_VERSION" >&2
    exit 1
fi

echo "Swift $ACTUAL_SWIFT_VERSION"
echo "SwiftLint $ACTUAL_SWIFTLINT_VERSION"
echo "actionlint $ACTUAL_ACTIONLINT_VERSION"
