#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
VERIFY_SCRIPT="$PROJECT_DIR/scripts/verify-compatibility-manifest.sh"
TEST_TEMP_DIR="$(mktemp -d)"
FAILURE_INDEX=0

cleanup() {
    find "$TEST_TEMP_DIR" -type f -delete
    find "$TEST_TEMP_DIR" -depth -type d -delete
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
    local stdout_file="$TEST_TEMP_DIR/failure-$FAILURE_INDEX.stdout"
    local stderr_file="$TEST_TEMP_DIR/failure-$FAILURE_INDEX.stderr"
    local status=0
    "$@" > "$stdout_file" 2> "$stderr_file" || status=$?

    [[ "$status" -ne 0 ]] || fail "command unexpectedly succeeded: $*"
    local actual
    actual="$(tail -n 1 "$stderr_file")"
    [[ "$actual" == "$expected" ]] || {
        fail "expected diagnostic '$expected', found '$actual'"
    }
}

make_fake_tool() {
    local root="$1"
    local bin_dir="$root/bin with spaces"
    mkdir -p "$bin_dir"
    local fake_api_tool="$bin_dir/fake-api-tool"

    cat > "$fake_api_tool" <<'FAKE_API_TOOL'
#!/usr/bin/env bash

set -euo pipefail

{
    for argument in "$@"; do
        printf '<%s>' "$argument"
    done
    printf '\n'
} >> "${FAKE_API_TOOL_LOG:?}"

command_name="${1:-}"
shift || true
case "$command_name" in
    generate-manifest)
        [[ "${FAKE_API_TOOL_MODE:-success}" != "generation-failure" ]] || exit 41
        output=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --policy|--owner-registry|--reference-set|--tuikit-set)
                    shift 2
                    ;;
                --output)
                    output="$2"
                    shift 2
                    ;;
                *) exit 97 ;;
            esac
        done
        [[ -n "$output" ]]
        if [[ "${FAKE_API_TOOL_MODE:-success}" == "drift" ]]; then
            printf '%s\n' '{"manifest":"drifted"}' > "$output"
        else
            cp "${FAKE_GENERATED_MANIFEST:?}" "$output"
        fi
        ;;
    validate-manifest)
        [[ "${FAKE_API_TOOL_MODE:-success}" != "validation-failure" ]] || exit 42
        [[ "$#" -eq 8 ]]
        ;;
    *) exit 98 ;;
esac
FAKE_API_TOOL
    chmod +x "$fake_api_tool"
}

prepare_case() {
    local name="$1"
    local root="$TEST_TEMP_DIR/$name with spaces"
    mkdir -p "$root"
    printf '%s\n' '{"manifest":"current"}' > "$root/compatibility-manifest.json"
    cp "$root/compatibility-manifest.json" "$root/generated-manifest.json"
    : > "$root/review-policy.json"
    : > "$root/owners.json"
    : > "$root/reference-set.json"
    : > "$root/tuikit-set.json"
    : > "$root/contracts.json"
    make_fake_tool "$root"
    printf '%s\n' "$root"
}

invoke_verifier() {
    local root="$1"
    shift
    local fake_api_tool="$root/bin with spaces/fake-api-tool"

    FAKE_API_TOOL_LOG="$root/tool.log" \
        FAKE_GENERATED_MANIFEST="$root/generated-manifest.json" \
        "$VERIFY_SCRIPT" \
        --tool "$fake_api_tool" \
        --policy "$root/review-policy.json" \
        --owner-registry "$root/owners.json" \
        --reference-set "$root/reference-set.json" \
        --tuikit-set "$root/tuikit-set.json" \
        --contracts "$root/contracts.json" \
        --manifest "$root/compatibility-manifest.json" \
        "$@"
}

test_regenerates_compares_and_validates_manifest() {
    local root
    root="$(prepare_case success)"

    local output
    output="$(invoke_verifier "$root")"

    [[ "$output" == "Compatibility manifest matches the current API snapshots." ]] || {
        fail "unexpected success output: $output"
    }
    [[ "$(wc -l < "$root/tool.log" | tr -d ' ')" == "2" ]] || {
        fail "API tool was not called exactly twice"
    }
    grep -Fq '<generate-manifest><--policy>' "$root/tool.log" || {
        fail "manifest generation was not invoked"
    }
    grep -Fq '<validate-manifest><--manifest>' "$root/tool.log" || {
        fail "manifest validation was not invoked"
    }
}

test_rejects_drift_before_validation() {
    local root
    root="$(prepare_case drift)"

    FAKE_API_TOOL_MODE=drift expect_failure \
        "Compatibility manifest is stale; regenerate it from the current API snapshots" \
        invoke_verifier "$root"
    [[ "$(wc -l < "$root/tool.log" | tr -d ' ')" == "1" ]] || {
        fail "validation ran after manifest drift"
    }
}

test_reports_generation_and_validation_failures() {
    local root
    root="$(prepare_case failures)"

    FAKE_API_TOOL_MODE=generation-failure expect_failure \
        "Unable to generate compatibility manifest from the current API snapshots" \
        invoke_verifier "$root"
    FAKE_API_TOOL_MODE=validation-failure expect_failure \
        "Generated compatibility manifest failed validation" \
        invoke_verifier "$root"
}

test_validates_required_options_and_paths() {
    local root
    root="$(prepare_case options)"

    expect_failure "Missing required option: --manifest" \
        "$VERIFY_SCRIPT" \
        --tool "$root/bin with spaces/fake-api-tool" \
        --policy "$root/review-policy.json" \
        --owner-registry "$root/owners.json" \
        --reference-set "$root/reference-set.json" \
        --tuikit-set "$root/tuikit-set.json" \
        --contracts "$root/contracts.json"
    expect_failure "Duplicate option: --manifest" \
        invoke_verifier "$root" --manifest "$root/compatibility-manifest.json"
    expect_failure "Unknown option: --unexpected" \
        invoke_verifier "$root" --unexpected value
    expect_failure "Input file not found for --contracts: $root/missing.json" \
        "$VERIFY_SCRIPT" \
        --tool "$root/bin with spaces/fake-api-tool" \
        --policy "$root/review-policy.json" \
        --owner-registry "$root/owners.json" \
        --reference-set "$root/reference-set.json" \
        --tuikit-set "$root/tuikit-set.json" \
        --contracts "$root/missing.json" \
        --manifest "$root/compatibility-manifest.json"
}

test_regenerates_compares_and_validates_manifest
test_rejects_drift_before_validation
test_reports_generation_and_validation_failures
test_validates_required_options_and_paths

echo "Compatibility manifest verification tests passed"
