#!/usr/bin/env bash
#
# Authoritative local quality gate for TUIkit.
#
# Usage:
#   ./scripts/test-linux.sh          # Run macOS and Linux gates
#   ./scripts/test-linux.sh linux    # Run the Linux gate in Docker
#   ./scripts/test-linux.sh macos    # Run the native macOS gate
#   ./scripts/test-linux.sh shell    # Open a shell in the pinned Linux image

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=toolchain.env
source "$PROJECT_DIR/scripts/toolchain.env"

TARGET="${1:-all}"

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
    echo -e "${RED}✗ $1${RESET}" >&2
}

check_docker() {
    if ! docker version >/dev/null 2>&1; then
        echo -e "${RED}Error: Docker is not available.${RESET}" >&2
        exit 1
    fi
}

run_macos() {
    header "macOS: deterministic quality gate"
    local swiftlint_bin
    swiftlint_bin="$($PROJECT_DIR/scripts/install-swiftlint.sh macos)"
    local actionlint_bin
    actionlint_bin="$($PROJECT_DIR/scripts/install-actionlint.sh macos)"

    if SWIFTLINT_BIN="$swiftlint_bin" \
        ACTIONLINT_BIN="$actionlint_bin" \
        TUIKIT_TEST_LIST_OUTPUT="$PROJECT_DIR/.build/quality/test-list.txt" \
        TUIKIT_DOCC_OUTPUT="$PROJECT_DIR/docc-output" \
        "$PROJECT_DIR/scripts/quality-gate.sh"; then
        success "macOS quality gate passed"
    else
        fail "macOS quality gate failed"
        exit 1
    fi

    if [[ -n "${TUIKIT_API_SNAPSHOT_OUTPUT:-}" ]]; then
        mkdir -p "$TUIKIT_API_SNAPSHOT_OUTPUT"
        local api_build_path="${TUIKIT_API_BUILD_PATH:-$PROJECT_DIR/.build/api-compatibility}"
        local tuikit_build_path="${TUIKIT_BUILD_PATH:-$PROJECT_DIR/.build}"
        local api_tool
        api_tool="$(
            swift build \
                --package-path "$PROJECT_DIR/Tools/APICompatibility" \
                --build-path "$api_build_path" \
                --show-bin-path
        )/TUIkitAPICheck"
        "$PROJECT_DIR/scripts/generate-tuikit-api-snapshots.sh" \
            --tool "$api_tool" \
            --platform macOS \
            --output-root "$TUIKIT_API_SNAPSHOT_OUTPUT" \
            --build-path "$tuikit_build_path"
        success "macOS API snapshots generated"
    fi
}

run_linux() {
    check_docker
    header "Linux ($SWIFT_LINUX_IMAGE): deterministic quality gate"

    local swiftlint_bin="${SWIFTLINT_BIN:-}"
    if [[ -z "$swiftlint_bin" ]]; then
        swiftlint_bin="$($PROJECT_DIR/scripts/install-swiftlint.sh linux-amd64)"
    fi
    local actionlint_bin="${ACTIONLINT_BIN:-}"
    if [[ -z "$actionlint_bin" ]]; then
        actionlint_bin="$($PROJECT_DIR/scripts/install-actionlint.sh linux-amd64)"
    fi

    local docker_arguments=(
        run --rm --platform linux/amd64
        -v "$PROJECT_DIR:/workspace:ro"
        -v "$swiftlint_bin:/opt/tuikit/swiftlint:ro"
        -v "$actionlint_bin:/opt/tuikit/actionlint:ro"
    )
    if [[ -n "${TUIKIT_API_SNAPSHOT_OUTPUT:-}" ]]; then
        mkdir -p "$TUIKIT_API_SNAPSHOT_OUTPUT"
        docker_arguments+=(
            -v "$TUIKIT_API_SNAPSHOT_OUTPUT:/api-snapshots"
            -e TUIKIT_CONTAINER_API_SNAPSHOT_OUTPUT=/api-snapshots
        )
    fi

    if docker "${docker_arguments[@]}" \
        "$SWIFT_LINUX_IMAGE" \
        bash -lc '
            set -euo pipefail
            mkdir -p /tmp/src
            tar --exclude=.build --exclude=docc-output -C /workspace -cf - . | tar -C /tmp/src -xf -
            cd /tmp/src
            SWIFTLINT_BIN=/opt/tuikit/swiftlint \
            ACTIONLINT_BIN=/opt/tuikit/actionlint \
            TUIKIT_BUILD_PATH=/tmp/tui-build \
            TUIKIT_API_BUILD_PATH=/tmp/api-build \
            TUIKIT_TEST_LIST_OUTPUT=/tmp/test-list.txt \
            TUIKIT_DOCC_OUTPUT=/tmp/docc-output \
                ./scripts/quality-gate.sh
            if [[ -n "${TUIKIT_CONTAINER_API_SNAPSHOT_OUTPUT:-}" ]]; then
                api_tool="$(
                    swift build \
                        --package-path Tools/APICompatibility \
                        --build-path /tmp/api-build \
                        --show-bin-path
                )/TUIkitAPICheck"
                ./scripts/generate-tuikit-api-snapshots.sh \
                    --tool "$api_tool" \
                    --platform Linux \
                    --output-root "$TUIKIT_CONTAINER_API_SNAPSHOT_OUTPUT" \
                    --build-path /tmp/tui-build
            fi
        '; then
        success "Linux quality gate passed"
    else
        fail "Linux quality gate failed"
        exit 1
    fi
}

run_shell() {
    check_docker
    header "Opening shell in $SWIFT_LINUX_IMAGE"
    echo -e "${YELLOW}Project is copied from /workspace into writable /tmp/src.${RESET}"
    docker run --rm -it --platform linux/amd64 \
        -v "$PROJECT_DIR:/workspace:ro" \
        "$SWIFT_LINUX_IMAGE" \
        bash -lc '
            set -euo pipefail
            mkdir -p /tmp/src
            tar --exclude=.build --exclude=docc-output -C /workspace -cf - . | tar -C /tmp/src -xf -
            cd /tmp/src
            exec /bin/bash
        '
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
        echo "Usage: $0 [all|macos|linux|shell]" >&2
        exit 2
        ;;
esac

header "Done"
success "All requested quality gates passed"
