#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES_DIR="$PROJECT_DIR/scripts/tests/fixtures/quality-gate"
TEMP_DIR="$(mktemp -d)"
TEST_CASE="${1:-all}"

cleanup() {
    find "$TEMP_DIR" -type f -delete
    find "$TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

prepare_project() {
    local name="$1"
    local test_root="$TEMP_DIR/$name"

    mkdir -p "$test_root/bin" "$test_root/scripts/tests"
    cp "$PROJECT_DIR/scripts/quality-gate.sh" "$test_root/scripts/quality-gate.sh"
    cp "$PROJECT_DIR/scripts/assert-tool-versions.sh" "$test_root/scripts/assert-tool-versions.sh"
    cp "$PROJECT_DIR/scripts/toolchain.env" "$test_root/scripts/toolchain.env"
    cp "$FIXTURES_DIR/bin/"* "$test_root/bin/"
    cp "$FIXTURES_DIR/scripts/test-tooling.sh" "$test_root/scripts/tests/test-tooling.sh"
    cp "$FIXTURES_DIR/scripts/validate-test-boundaries.sh" "$test_root/scripts/validate-test-boundaries.sh"
    cp "$FIXTURES_DIR/scripts/generate-documentation.sh" "$test_root/scripts/generate-documentation.sh"
    cp "$FIXTURES_DIR/scripts/update-test-count.sh" "$test_root/scripts/update-test-count.sh"
    cp "$FIXTURES_DIR/scripts/verify-versioned-consumer.sh" "$test_root/scripts/verify-versioned-consumer.sh"
    chmod +x "$test_root/bin/"* "$test_root/scripts/"*.sh "$test_root/scripts/tests/test-tooling.sh"

    printf '%s\n' "$test_root"
}

run_gate() {
    local test_root="$1"
    shift

    env \
        PATH="$test_root/bin:$PATH" \
        QUALITY_GATE_TEST_LOG="$test_root/commands.log" \
        SWIFTLINT_BIN="$test_root/bin/swiftlint" \
        ACTIONLINT_BIN="$test_root/bin/actionlint" \
        TUIKIT_BUILD_PATH="$test_root/build" \
        TUIKIT_API_BUILD_PATH="$test_root/api-build" \
        TUIKIT_API_TOOL="$test_root/bin/TUIkitAPICheck" \
        TUIKIT_SWIFTC_BIN="$test_root/bin/swift" \
        TUIKIT_SWIFT_MODULE_PATH="$test_root/build/Modules" \
        TUIKIT_CLANG_MODULE_PATH="$test_root" \
        TUIKIT_TEST_LIST_OUTPUT="$test_root/test-list.txt" \
        TUIKIT_TEST_EVENT_STREAM_OUTPUT="$test_root/test-events.jsonl" \
        TUIKIT_DOCC_OUTPUT="$test_root/docc-output" \
        "$@" \
        "$test_root/scripts/quality-gate.sh"
}

run_gate_without_build_path() {
    local test_root="$1"

    env -u TUIKIT_BUILD_PATH \
        PATH="$test_root/bin:$PATH" \
        QUALITY_GATE_TEST_LOG="$test_root/commands.log" \
        SWIFTLINT_BIN="$test_root/bin/swiftlint" \
        ACTIONLINT_BIN="$test_root/bin/actionlint" \
        TUIKIT_API_BUILD_PATH="$test_root/api-build" \
        TUIKIT_API_TOOL="$test_root/bin/TUIkitAPICheck" \
        TUIKIT_SWIFTC_BIN="$test_root/bin/swift" \
        TUIKIT_SWIFT_MODULE_PATH="$test_root/build/Modules" \
        TUIKIT_CLANG_MODULE_PATH="$test_root" \
        TUIKIT_TEST_LIST_OUTPUT="$test_root/test-list.txt" \
        TUIKIT_TEST_EVENT_STREAM_OUTPUT="$test_root/test-events.jsonl" \
        TUIKIT_DOCC_OUTPUT="$test_root/docc-output" \
        /bin/bash "$test_root/scripts/quality-gate.sh"
}

assert_log_line() {
    local log="$1"
    local line_number="$2"
    local expected="$3"
    local actual
    actual="$(sed -n "${line_number}p" "$log")"
    [[ "$actual" == "$expected" ]] || {
        fail "log line $line_number: expected '$expected', found '$actual'"
    }
}

assert_not_contains() {
    local file="$1"
    local unexpected="$2"
    if grep -Fq "$unexpected" "$file"; then
        fail "$file unexpectedly contains: $unexpected"
    fi
}

test_runs_every_gate_in_order() {
    local test_root
    test_root="$(prepare_project ordered)"
    local stdout_file="$test_root/stdout"
    local stderr_file="$test_root/stderr"

    run_gate "$test_root" > "$stdout_file" 2> "$stderr_file"

    assert_log_line "$test_root/commands.log" 1 "swift --version"
    assert_log_line "$test_root/commands.log" 2 "swiftlint version"
    assert_log_line "$test_root/commands.log" 3 "actionlint -version"
    assert_log_line "$test_root/commands.log" 4 "test-tooling"
    assert_log_line "$test_root/commands.log" 5 "validate-test-boundaries"
    assert_log_line "$test_root/commands.log" 6 "swiftlint lint --strict --no-cache"
    assert_log_line "$test_root/commands.log" 7 \
        "swift build --package-path $test_root/Tools/APICompatibility --build-path $test_root/api-build -Xswiftc -warnings-as-errors"
    assert_log_line "$test_root/commands.log" 8 \
        "swift test --package-path $test_root/Tools/APICompatibility --build-path $test_root/api-build -Xswiftc -warnings-as-errors"
    assert_log_line "$test_root/commands.log" 9 \
        "swift build --package-path $test_root --build-path $test_root/build -Xswiftc -warnings-as-errors"
    assert_log_line "$test_root/commands.log" 10 \
        "TUIkitAPICheck run-compile-contracts --registry $test_root/Tools/APICompatibility/Configuration/contracts.json --fixtures $test_root/Tools/APICompatibility/Configuration/CompileContracts --swiftc $test_root/bin/swift --swift-module-path $test_root/build/Modules --clang-module-path $test_root"
    assert_log_line "$test_root/commands.log" 11 "verify-versioned-consumer "
    assert_log_line "$test_root/commands.log" 12 \
        "swift test --package-path $test_root --build-path $test_root/build -Xswiftc -warnings-as-errors --event-stream-version 0 --event-stream-output-path $test_root/test-events.jsonl"
    assert_log_line "$test_root/commands.log" 13 \
        "TUIkitAPICheck validate-contracts --registry $test_root/Tools/APICompatibility/Configuration/contracts.json --event-stream $test_root/test-events.jsonl"
    assert_log_line "$test_root/commands.log" 14 \
        "swift test list --package-path $test_root --build-path $test_root/build --skip-build"
    assert_log_line "$test_root/commands.log" 15 "generate-documentation $test_root/docc-output"
    assert_log_line "$test_root/commands.log" 16 \
        "update-test-count --count-only --test-list $test_root/test-list.txt --expected-test-target TUIkitCoreTests --expected-test-target TUIkitStylingTests --expected-test-target TUIkitViewTests --expected-test-target TUIkitImageTests --expected-test-target TUIkitTests"
    [[ "$(wc -l < "$test_root/commands.log" | tr -d '[:space:]')" == "16" ]] || {
        fail "quality gate ran an unexpected number of commands"
    }
    grep -Fq "Quality gate passed with 2 discovered tests" "$stdout_file" || {
        fail "quality gate did not report the discovered test count"
    }
}

test_rejects_wrong_actionlint_version() {
    local test_root
    test_root="$(prepare_project actionlint-version)"
    local stdout_file="$test_root/stdout"
    local stderr_file="$test_root/stderr"
    local status=0

    run_gate "$test_root" TUIKIT_STUB_ACTIONLINT_VERSION=1.7.11 \
        > "$stdout_file" 2> "$stderr_file" || status=$?

    [[ "$status" == "1" ]] || fail "wrong actionlint version exited with $status instead of 1"
    [[ "$(tail -n 1 "$stderr_file")" == "Expected actionlint 1.7.12, found 1.7.11" ]] || {
        fail "wrong actionlint version emitted an unexpected diagnostic"
    }
    assert_not_contains "$test_root/commands.log" "test-tooling"
}

test_propagates_failures_without_running_later_gates() {
    local test_root
    test_root="$(prepare_project fail-fast)"
    local stdout_file="$test_root/stdout"
    local stderr_file="$test_root/stderr"
    local status=0

    run_gate "$test_root" TUIKIT_STUB_FAIL_SWIFT_TEST=42 \
        > "$stdout_file" 2> "$stderr_file" || status=$?

    [[ "$status" == "42" ]] || fail "swift test failure exited with $status instead of 42"
    assert_not_contains "$test_root/commands.log" "swift test list"
    assert_not_contains "$test_root/commands.log" "generate-documentation"
    assert_not_contains "$test_root/commands.log" "update-test-count"
}

test_rejects_a_missing_event_stream_after_removing_stale_output() {
    local test_root
    test_root="$(prepare_project missing-event-stream)"
    local stdout_file="$test_root/stdout"
    local stderr_file="$test_root/stderr"
    local status=0
    printf '%s\n' '{"stale":true}' > "$test_root/test-events.jsonl"

    run_gate "$test_root" TUIKIT_STUB_SKIP_EVENT_STREAM=1 \
        > "$stdout_file" 2> "$stderr_file" || status=$?

    [[ "$status" == "1" ]] || fail "missing event stream exited with $status instead of 1"
    [[ "$(tail -n 1 "$stderr_file")" == "Swift Testing did not produce a nonempty event stream at $test_root/test-events.jsonl" ]] || {
        fail "missing event stream emitted an unexpected diagnostic"
    }
    [[ ! -e "$test_root/test-events.jsonl" ]] || {
        fail "stale event stream survived the quality gate"
    }
    assert_not_contains "$test_root/commands.log" "swift test list"
}

test_rejects_an_empty_event_stream() {
    local test_root
    test_root="$(prepare_project empty-event-stream)"
    local stdout_file="$test_root/stdout"
    local stderr_file="$test_root/stderr"
    local status=0

    run_gate "$test_root" TUIKIT_STUB_EMPTY_EVENT_STREAM=1 \
        > "$stdout_file" 2> "$stderr_file" || status=$?

    [[ "$status" == "1" ]] || fail "empty event stream exited with $status instead of 1"
    [[ "$(tail -n 1 "$stderr_file")" == "Swift Testing did not produce a nonempty event stream at $test_root/test-events.jsonl" ]] || {
        fail "empty event stream emitted an unexpected diagnostic"
    }
    assert_not_contains "$test_root/commands.log" "swift test list"
}

test_runs_under_system_bash_without_optional_build_path() {
    local test_root
    test_root="$(prepare_project system-bash)"

    run_gate_without_build_path "$test_root"

    assert_log_line "$test_root/commands.log" 9 \
        "swift build --package-path $test_root -Xswiftc -warnings-as-errors"
    assert_log_line "$test_root/commands.log" 12 \
        "swift test --package-path $test_root -Xswiftc -warnings-as-errors --event-stream-version 0 --event-stream-output-path $test_root/test-events.jsonl"
}

test_documentation_declares_nonempty_build_arguments() {
    grep -Fq 'SWIFT_BUILD_ARGUMENTS=(--package-path "$PROJECT_DIR")' \
        "$PROJECT_DIR/scripts/generate-documentation.sh" || {
        fail "documentation generation must keep Swift build arguments nonempty"
    }
}

run_case() {
    local name="$1"
    local function_name="$2"

    if [[ "$TEST_CASE" == "all" || "$TEST_CASE" == "$name" ]]; then
        "$function_name"
    fi
}

run_case ordered test_runs_every_gate_in_order
run_case actionlint-version test_rejects_wrong_actionlint_version
run_case fail-fast test_propagates_failures_without_running_later_gates
run_case missing-event-stream test_rejects_a_missing_event_stream_after_removing_stale_output
run_case empty-event-stream test_rejects_an_empty_event_stream
run_case system-bash test_runs_under_system_bash_without_optional_build_path
run_case documentation-build-arguments test_documentation_declares_nonempty_build_arguments

echo "Quality gate integration self-tests passed"
