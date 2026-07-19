#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

if [[ -z "${SWIFTLINT_BIN:-}" ]]; then
    case "$(uname -s)" in
        Darwin)
            SWIFTLINT_BIN="$("$PROJECT_DIR/scripts/install-swiftlint.sh" macos)"
            ;;
        Linux)
            SWIFTLINT_BIN="$("$PROJECT_DIR/scripts/install-swiftlint.sh" linux-amd64)"
            ;;
        *)
            echo "Unsupported platform: $(uname -s)" >&2
            exit 1
            ;;
    esac
fi
export SWIFTLINT_BIN

if [[ -z "${ACTIONLINT_BIN:-}" ]]; then
    case "$(uname -s)" in
        Darwin)
            ACTIONLINT_BIN="$("$PROJECT_DIR/scripts/install-actionlint.sh" macos)"
            ;;
        Linux)
            ACTIONLINT_BIN="$("$PROJECT_DIR/scripts/install-actionlint.sh" linux-amd64)"
            ;;
        *)
            echo "Unsupported platform: $(uname -s)" >&2
            exit 1
            ;;
    esac
fi
export ACTIONLINT_BIN

SWIFT_ARGUMENTS=(--package-path "$PROJECT_DIR")
if [[ -n "${TUIKIT_BUILD_PATH:-}" ]]; then
    SWIFT_ARGUMENTS+=(--build-path "$TUIKIT_BUILD_PATH")
fi

API_SWIFT_ARGUMENTS=(--package-path "$PROJECT_DIR/Tools/APICompatibility")
API_BUILD_PATH="${TUIKIT_API_BUILD_PATH:-$PROJECT_DIR/.build/api-compatibility}"
API_SWIFT_ARGUMENTS+=(--build-path "$API_BUILD_PATH")
API_TOOL="${TUIKIT_API_TOOL:-}"
SWIFTC_BIN="${TUIKIT_SWIFTC_BIN:-}"
SWIFT_MODULE_PATH="${TUIKIT_SWIFT_MODULE_PATH:-}"
CLANG_MODULE_PATH="${TUIKIT_CLANG_MODULE_PATH:-$PROJECT_DIR}"
CONTRACT_REGISTRY="$PROJECT_DIR/Tools/APICompatibility/Configuration/contracts.json"
COMPILE_FIXTURES="$PROJECT_DIR/Tools/APICompatibility/Configuration/CompileContracts"

TEST_LIST_OUTPUT="${TUIKIT_TEST_LIST_OUTPUT:-$PROJECT_DIR/.build/quality/test-list.txt}"
TEST_EVENT_STREAM_OUTPUT="${TUIKIT_TEST_EVENT_STREAM_OUTPUT:-$PROJECT_DIR/.build/quality/test-events.jsonl}"
DOCC_OUTPUT="${TUIKIT_DOCC_OUTPUT:-$PROJECT_DIR/docc-output}"
mkdir -p "$(dirname "$TEST_LIST_OUTPUT")"
mkdir -p "$(dirname "$TEST_EVENT_STREAM_OUTPUT")"

./scripts/assert-tool-versions.sh
./scripts/tests/test-tooling.sh
./scripts/validate-test-boundaries.sh

"$SWIFTLINT_BIN" lint --strict --no-cache
swift build "${API_SWIFT_ARGUMENTS[@]}" -Xswiftc -warnings-as-errors
swift test "${API_SWIFT_ARGUMENTS[@]}" -Xswiftc -warnings-as-errors
swift build "${SWIFT_ARGUMENTS[@]}" -Xswiftc -warnings-as-errors
if [[ -z "$API_TOOL" ]]; then
    API_TOOL="$(swift build "${API_SWIFT_ARGUMENTS[@]}" --show-bin-path)/TUIkitAPICheck"
fi
if [[ -z "$SWIFTC_BIN" ]]; then
    SWIFTC_BIN="$(command -v swiftc)"
fi
if [[ -z "$SWIFT_MODULE_PATH" ]]; then
    SWIFT_MODULE_PATH="$(swift build "${SWIFT_ARGUMENTS[@]}" --show-bin-path)/Modules"
fi
"$API_TOOL" run-compile-contracts \
    --registry "$CONTRACT_REGISTRY" \
    --fixtures "$COMPILE_FIXTURES" \
    --swiftc "$SWIFTC_BIN" \
    --swift-module-path "$SWIFT_MODULE_PATH" \
    --clang-module-path "$CLANG_MODULE_PATH"
./scripts/verify-versioned-consumer.sh
rm -f "$TEST_EVENT_STREAM_OUTPUT"
swift test "${SWIFT_ARGUMENTS[@]}" -Xswiftc -warnings-as-errors \
    --event-stream-version 0 \
    --event-stream-output-path "$TEST_EVENT_STREAM_OUTPUT"
if [[ ! -s "$TEST_EVENT_STREAM_OUTPUT" ]]; then
    echo "Swift Testing did not produce a nonempty event stream at $TEST_EVENT_STREAM_OUTPUT" >&2
    exit 1
fi
"$API_TOOL" validate-contracts \
    --registry "$CONTRACT_REGISTRY" \
    --event-stream "$TEST_EVENT_STREAM_OUTPUT"
swift test list "${SWIFT_ARGUMENTS[@]}" --skip-build > "$TEST_LIST_OUTPUT"
./scripts/generate-documentation.sh "$DOCC_OUTPUT"

TEST_COUNT="$(
    ./scripts/update-test-count.sh \
        --count-only \
        --test-list "$TEST_LIST_OUTPUT" \
        --expected-test-target TUIkitCoreTests \
        --expected-test-target TUIkitStylingTests \
        --expected-test-target TUIkitViewTests \
        --expected-test-target TUIkitImageTests \
        --expected-test-target TUIkitTests
)"
echo "Quality gate passed with $TEST_COUNT discovered tests"
