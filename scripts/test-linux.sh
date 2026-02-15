#!/usr/bin/env bash
#
# Cross-platform build & test runner for TUIkit.
# Runs swift build + swift test on both macOS (native) and Linux (Docker).
#
# Usage:
#   ./scripts/test-linux.sh          # Run both macOS and Linux
#   ./scripts/test-linux.sh linux    # Run Linux only
#   ./scripts/test-linux.sh macos    # Run macOS only
#   ./scripts/test-linux.sh shell    # Open interactive shell in Linux container
#
# Requirements:
#   - Docker Desktop (or compatible runtime) for Linux tests
#   - Swift 6.0+ toolchain for macOS tests

set -euo pipefail

SWIFT_IMAGE="swift:6.0"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${1:-all}"
# Separate build directory inside the container to avoid permission conflicts
# with the host's .build directory (different Swift versions, different UIDs).
LINUX_BUILD_PATH="/tmp/tui-build"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

header() {
    echo ""
    echo -e "${BOLD}━━━ $1 ━━━${RESET}"
    echo ""
}

success() {
    echo -e "${GREEN}✓ $1${RESET}"
}

fail() {
    echo -e "${RED}✗ $1${RESET}"
}

check_docker() {
    if ! docker info &>/dev/null; then
        echo -e "${RED}Error: Docker is not running.${RESET}"
        echo "Start Docker Desktop and try again."
        exit 1
    fi
}

run_macos() {
    header "macOS: swift build"
    if swift build 2>&1; then
        success "macOS build passed"
    else
        fail "macOS build failed"
        exit 1
    fi

    header "macOS: swift test"
    if swift test 2>&1; then
        success "macOS tests passed"
    else
        fail "macOS tests failed"
        exit 1
    fi
}

run_linux() {
    check_docker

    header "Linux ($SWIFT_IMAGE): swift build + swift test"
    if docker run --rm \
        -v "$PROJECT_DIR:/workspace:ro" \
        -w /tmp/src \
        "$SWIFT_IMAGE" \
        bash -c "cp -a /workspace/. . && swift build --build-path $LINUX_BUILD_PATH && swift test --build-path $LINUX_BUILD_PATH" 2>&1; then
        success "Linux build + tests passed"
    else
        fail "Linux build or tests failed"
        exit 1
    fi
}

run_shell() {
    check_docker
    header "Opening interactive shell in $SWIFT_IMAGE"
    echo -e "${YELLOW}Project mounted read-only at /workspace, working copy at /tmp/src${RESET}"
    echo -e "${YELLOW}Run: swift build --build-path $LINUX_BUILD_PATH${RESET}"
    echo -e "${YELLOW}Type 'exit' to leave the container${RESET}"
    echo ""
    docker run --rm -it \
        -v "$PROJECT_DIR:/workspace:ro" \
        -w /tmp/src \
        "$SWIFT_IMAGE" \
        bash -c "cp -a /workspace/. . && exec /bin/bash"
}

case "$TARGET" in
    macos)
        run_macos
        ;;
    linux)
        run_linux
        ;;
    shell)
        run_shell
        ;;
    all)
        run_macos
        run_linux
        ;;
    *)
        echo "Usage: $0 [all|macos|linux|shell]"
        exit 1
        ;;
esac

header "Done"
success "All checks passed!"
