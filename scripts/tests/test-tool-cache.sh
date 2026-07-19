#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES_DIR="$PROJECT_DIR/scripts/tests/fixtures/tool-cache"
TEMP_DIR="$(mktemp -d)"
TEST_CASE="${1:-all}"
FAILURE_INDEX=0

# shellcheck source=../toolchain.env
source "$PROJECT_DIR/scripts/toolchain.env"

cleanup() {
    find "$TEMP_DIR" -type f -delete
    find "$TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

expect_failure() {
    local expected="$1"
    shift

    FAILURE_INDEX=$((FAILURE_INDEX + 1))
    local stdout_file="$TEMP_DIR/failure-$FAILURE_INDEX.stdout"
    local stderr_file="$TEMP_DIR/failure-$FAILURE_INDEX.stderr"
    local status=0
    "$@" > "$stdout_file" 2> "$stderr_file" || status=$?

    [[ "$status" -ne 0 ]] || fail "command unexpectedly succeeded: $*"

    local actual
    actual="$(tail -n 1 "$stderr_file")"
    [[ "$actual" == "$expected" ]] || {
        fail "expected diagnostic '$expected', found '$actual'"
    }
}

write_corrupted_binary() {
    local path="$1"
    mkdir -p "$(dirname "$path")"
    printf '#!/usr/bin/env bash\nexit 0\n' > "$path"
    chmod +x "$path"
}

test_swiftlint_cache_hit_is_verified() {
    local cache="$TEMP_DIR/swiftlint-cache"
    write_corrupted_binary "$cache/swiftlint/$SWIFTLINT_VERSION/linux-amd64/swiftlint"

    expect_failure "SwiftLint cached binary checksum mismatch" \
        env TUIKIT_TOOL_CACHE="$cache" \
        "$PROJECT_DIR/scripts/install-swiftlint.sh" linux-amd64
}

test_swiftlint_extracted_binary_is_verified() {
    local cache="$TEMP_DIR/swiftlint-extract"

    expect_failure "SwiftLint extracted binary checksum mismatch" \
        env PATH="$FIXTURES_DIR/bin:$PATH" \
        STUB_ARCHIVE_SHA="$SWIFTLINT_LINUX_AMD64_SHA256" \
        TUIKIT_TOOL_CACHE="$cache" \
        "$PROJECT_DIR/scripts/install-swiftlint.sh" linux-amd64
}

test_actionlint_cache_hit_is_verified() {
    local cache="$TEMP_DIR/actionlint-cache"
    write_corrupted_binary "$cache/actionlint/$ACTIONLINT_VERSION/linux_amd64/actionlint"

    expect_failure "actionlint cached binary checksum mismatch" \
        env TUIKIT_TOOL_CACHE="$cache" \
        "$PROJECT_DIR/scripts/install-actionlint.sh" linux-amd64
}

test_actionlint_extracted_binary_is_verified() {
    local cache="$TEMP_DIR/actionlint-extract"

    expect_failure "actionlint extracted binary checksum mismatch" \
        env PATH="$FIXTURES_DIR/bin:$PATH" \
        STUB_ARCHIVE_SHA="$ACTIONLINT_LINUX_AMD64_SHA256" \
        TUIKIT_TOOL_CACHE="$cache" \
        "$PROJECT_DIR/scripts/install-actionlint.sh" linux-amd64
}

run_case() {
    local name="$1"
    local function_name="$2"

    if [[ "$TEST_CASE" == "all" || "$TEST_CASE" == "$name" ]]; then
        "$function_name"
    fi
}

run_case swiftlint-cache test_swiftlint_cache_hit_is_verified
run_case swiftlint-extract test_swiftlint_extracted_binary_is_verified
run_case actionlint-cache test_actionlint_cache_hit_is_verified
run_case actionlint-extract test_actionlint_extracted_binary_is_verified

echo "Tool cache self-tests passed"
