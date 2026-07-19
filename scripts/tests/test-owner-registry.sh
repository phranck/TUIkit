#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
VERIFY_SCRIPT="$PROJECT_DIR/scripts/verify-compatibility-owner-registry.sh"
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

write_registry_tsv() {
    local output="$1"
    local repository="$2"
    local first_title="${3:-Establish View foundations}"

    printf '%s\t%s\t%s\t%s\n' repository issueNumber title url > "$output"
    printf '%s\t%s\t%s\t%s\n' \
        "$repository" \
        17 \
        "$first_title" \
        "https://github.com/$repository/issues/17" \
        >> "$output"
    printf '%s\t%s\t%s\t%s\n' \
        "$repository" \
        18 \
        "Establish data-flow foundations" \
        "https://github.com/$repository/issues/18" \
        >> "$output"
}

make_fake_tools() {
    local root="$1"
    local bin_dir="$root/bin with spaces"
    mkdir -p "$bin_dir"
    FAKE_API_TOOL="$bin_dir/fake-api-tool"
    FAKE_GH="$bin_dir/fake-gh"

    cat > "$FAKE_API_TOOL" <<'FAKE_API_TOOL'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "${FAKE_API_TOOL_LOG:?}"
[[ "$#" -eq 3 && "$1" == "list-owner-registry" && "$2" == "--owner-registry" ]]
cat "${FAKE_REGISTRY_TSV:?}"
FAKE_API_TOOL
    chmod +x "$FAKE_API_TOOL"

    cat > "$FAKE_GH" <<'FAKE_GH'
#!/usr/bin/env bash

set -euo pipefail

{
    for argument in "$@"; do
        printf '<%s>' "$argument"
    done
    printf '\n'
} >> "${FAKE_GH_LOG:?}"
[[ "$#" -eq 9 && "$1" == "issue" && "$2" == "view" ]]
number="$3"
repository="$5"
if [[ "${FAKE_GH_MODE:-success}" == "missing" && "$number" == "17" ]]; then
    exit 1
fi
actual_number="$number"
case "${FAKE_GH_MODE:-success}" in
    wrong-number) [[ "$number" == "17" ]] && actual_number=99 ;;
esac
case "$number" in
    17) title="${FAKE_GH_TITLE:-Establish View foundations}" ;;
    18) title="Establish data-flow foundations" ;;
    *) exit 1 ;;
esac
if [[ "${FAKE_GH_MODE:-success}" == "wrong-title" && "$number" == "17" ]]; then
    title="Wrong title"
fi
url="https://github.com/$repository/issues/$number"
if [[ "${FAKE_GH_MODE:-success}" == "wrong-url" && "$number" == "17" ]]; then
    url="https://github.com/other/project/issues/17"
fi
printf '%s\t%s\t%s\n' "$actual_number" "$title" "$url"
FAKE_GH
    chmod +x "$FAKE_GH"
}

invoke_verifier() {
    local root="$1"
    shift

    FAKE_API_TOOL_LOG="$root/api-tool.log" \
        FAKE_GH_LOG="$root/gh.log" \
        FAKE_REGISTRY_TSV="$root/registry.tsv" \
        "$VERIFY_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --registry "$root/owners.json" \
        --repository phranck/TUIkit \
        --gh "$FAKE_GH" \
        "$@"
}

test_verifies_each_registered_issue_exactly() {
    local root="$TEST_TEMP_DIR/success"
    mkdir -p "$root"
    : > "$root/owners.json"
    write_registry_tsv "$root/registry.tsv" phranck/TUIkit
    make_fake_tools "$root"

    local output
    output="$(invoke_verifier "$root")"

    [[ "$output" == "Verified 2 compatibility owner issues in phranck/TUIkit." ]] || {
        fail "unexpected success output: $output"
    }
    grep -Fqx "list-owner-registry --owner-registry $root/owners.json" "$root/api-tool.log" || {
        fail "API tool did not receive the exact registry path"
    }
    grep -Fq '<issue><view><17><--repo><phranck/TUIkit><--json><number,title,url><--template>' \
        "$root/gh.log" || fail "gh did not receive the expected issue-view arguments"
    [[ "$(wc -l < "$root/gh.log" | tr -d ' ')" == "2" ]] || {
        fail "gh was not called once per issue"
    }
}

test_rejects_missing_or_mismatched_issues() {
    local root="$TEST_TEMP_DIR/mismatch"
    mkdir -p "$root"
    : > "$root/owners.json"
    write_registry_tsv "$root/registry.tsv" phranck/TUIkit
    make_fake_tools "$root"

    FAKE_GH_MODE=missing expect_failure \
        "Unable to read owner issue #17 from phranck/TUIkit" \
        invoke_verifier "$root"
    FAKE_GH_MODE=wrong-number expect_failure \
        "Owner issue #17 returned number '99'" \
        invoke_verifier "$root"
    FAKE_GH_MODE=wrong-title expect_failure \
        "Owner issue #17 title does not match the registry" \
        invoke_verifier "$root"
    FAKE_GH_MODE=wrong-url expect_failure \
        "Owner issue #17 URL does not match the registry" \
        invoke_verifier "$root"

    write_registry_tsv "$root/registry.tsv" other/TUIkit
    expect_failure \
        "Owner registry repository 'other/TUIkit' does not match expected repository 'phranck/TUIkit'" \
        invoke_verifier "$root"
}

test_validates_options_and_resolves_executables() {
    local root="$TEST_TEMP_DIR/options"
    mkdir -p "$root"
    : > "$root/owners.json"
    write_registry_tsv "$root/registry.tsv" phranck/TUIkit
    make_fake_tools "$root"

    expect_failure "Missing required option: --gh" \
        "$VERIFY_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --registry "$root/owners.json" \
        --repository phranck/TUIkit
    expect_failure "Duplicate option: --gh" \
        invoke_verifier "$root" --gh "$FAKE_GH"
    expect_failure "Unknown option: --unexpected" \
        invoke_verifier "$root" --unexpected value
    expect_failure "Missing value for --gh" \
        "$VERIFY_SCRIPT" --gh

    local bin_dir
    bin_dir="$(dirname "$FAKE_GH")"
    local output
    output="$(
        PATH="$bin_dir:$PATH" \
            FAKE_API_TOOL_LOG="$root/api-tool.log" \
            FAKE_GH_LOG="$root/gh.log" \
            FAKE_REGISTRY_TSV="$root/registry.tsv" \
            "$VERIFY_SCRIPT" \
            --tool fake-api-tool \
            --registry "$root/owners.json" \
            --repository phranck/TUIkit \
            --gh fake-gh
    )"
    [[ "$output" == "Verified 2 compatibility owner issues in phranck/TUIkit." ]] || {
        fail "PATH-resolved tools did not succeed"
    }
}

test_never_evaluates_registry_data_or_paths() {
    local root="$TEST_TEMP_DIR/injection"
    mkdir -p "$root"
    local data_marker="$root/evaluated-data"
    local path_marker="$root/evaluated-path"
    local payload
    payload="\$(touch $data_marker); \`touch $data_marker\`"
    local backtick=$'\x60'
    local registry_name="owners;${backtick}touch evaluated-path${backtick}.json"
    local registry="$root/$registry_name"
    : > "$registry"
    write_registry_tsv "$root/registry.tsv" phranck/TUIkit "$payload"
    make_fake_tools "$root"

    (
        cd "$root"
        FAKE_API_TOOL_LOG="$root/api-tool.log" \
            FAKE_GH_LOG="$root/gh.log" \
            FAKE_GH_TITLE="$payload" \
            FAKE_REGISTRY_TSV="$root/registry.tsv" \
            "$VERIFY_SCRIPT" \
            --tool "$FAKE_API_TOOL" \
            --registry "$registry_name" \
            --repository phranck/TUIkit \
            --gh "$FAKE_GH" \
            > "$root/result"
    )

    [[ ! -e "$data_marker" ]] || fail "registry data was evaluated by the shell"
    [[ ! -e "$path_marker" ]] || fail "registry path was evaluated by the shell"
    grep -Fq "$payload" "$root/registry.tsv" || fail "injection fixture was not preserved"
}

test_verifies_each_registered_issue_exactly
test_rejects_missing_or_mismatched_issues
test_validates_options_and_resolves_executables
test_never_evaluates_registry_data_or_paths

echo "Owner registry verification tests passed"
