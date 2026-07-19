#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES_DIR="$PROJECT_DIR/scripts/tests/fixtures"
TEMP_DIR="$(mktemp -d)"
TEST_CASE="${1:-all}"
FAILURE_INDEX=0

cleanup() {
    find "$TEMP_DIR" -type f -delete
    find "$TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_contains() {
    local file="$1"
    local expected="$2"

    grep -Fq "$expected" "$file" || fail "$file does not contain: $expected"
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

test_badge_uses_discovered_tests() {
    local readme="$TEMP_DIR/README.md"
    cp "$FIXTURES_DIR/badge/README.md" "$readme"

    "$PROJECT_DIR/scripts/update-test-count.sh" \
        --test-list "$FIXTURES_DIR/badge/swift-test-list.txt" \
        --readme "$readme"

    assert_contains "$readme" "Tests-2_passing"
    assert_contains "$readme" "contains 2 tests"
    assert_contains "$readme" "All 2 tests run"

    local annotation_count
    annotation_count="$(grep -c '@Test' "$FIXTURES_DIR/badge/CommentedTests.swift")"
    [[ "$annotation_count" == "3" ]] || fail "fixture must contain two real tests and one comment annotation"
}

test_badge_check_detects_stale_readme() {
    local readme="$TEMP_DIR/stale-README.md"
    cp "$FIXTURES_DIR/badge/README.md" "$readme"

    expect_failure "README does not report 2 discovered tests" \
        "$PROJECT_DIR/scripts/update-test-count.sh" \
        --check \
        --test-list "$FIXTURES_DIR/badge/swift-test-list.txt" \
        --readme "$readme"
}

test_badge_rejects_duplicate_markers() {
    local readme="$TEMP_DIR/duplicate-badge-README.md"
    cp "$FIXTURES_DIR/badge/DuplicateBadgeREADME.md" "$readme"

    expect_failure "README must contain exactly one shields.io test badge marker" \
        "$PROJECT_DIR/scripts/update-test-count.sh" \
        --test-list "$FIXTURES_DIR/badge/swift-test-list.txt" \
        --readme "$readme"
}

test_badge_rejects_duplicate_test_ids() {
    expect_failure "Test list contains duplicate discovered test ID: FixtureTests/firstRealTest()" \
        "$PROJECT_DIR/scripts/update-test-count.sh" \
        --count-only \
        --test-list "$FIXTURES_DIR/badge/duplicate-test-list.txt"
}

test_badge_rejects_duplicate_project_markers() {
    local readme="$TEMP_DIR/duplicate-project-marker-README.md"
    cp "$FIXTURES_DIR/badge/DuplicateProjectMarkerREADME.md" "$readme"

    expect_failure "README must contain exactly one TUIkitTests project-structure count marker" \
        "$PROJECT_DIR/scripts/update-test-count.sh" \
        --test-list "$FIXTURES_DIR/badge/swift-test-list.txt" \
        --readme "$readme"
}

test_badge_rejects_duplicate_developer_markers() {
    local readme="$TEMP_DIR/duplicate-developer-marker-README.md"
    cp "$FIXTURES_DIR/badge/DuplicateDeveloperMarkerREADME.md" "$readme"

    expect_failure "README must contain exactly one developer test count marker" \
        "$PROJECT_DIR/scripts/update-test-count.sh" \
        --test-list "$FIXTURES_DIR/badge/swift-test-list.txt" \
        --readme "$readme"
}

test_ci_configuration_is_deterministic() {
    "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$FIXTURES_DIR/ci/valid"

    "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$PROJECT_DIR"
}

test_ci_rejects_duplicate_badge_writer() {
    local invalid_root="$TEMP_DIR/invalid-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/second-badge-workflow.yml" \
        "$invalid_root/.github/workflows/update-test-counts.yml"
    expect_failure "CI configuration error: exactly one workflow must update the test count" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_direct_readme_writer() {
    local invalid_root="$TEMP_DIR/direct-readme-writer-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/direct-readme-writer.yml" \
        "$invalid_root/.github/workflows/direct-readme-writer.yml"
    expect_failure "CI configuration error: .github/workflows/direct-readme-writer.yml contains an unauthorized README writer with git push" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_contents_write_outside_badge_job() {
    local invalid_root="$TEMP_DIR/contents-write-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/contents-write-workflow.yml" \
        "$invalid_root/.github/workflows/contents-write-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/contents-write-workflow.yml grants contents: write outside ci.yml update-badge" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_write_all_outside_badge_job() {
    local invalid_root="$TEMP_DIR/write-all-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/write-all-workflow.yml" \
        "$invalid_root/.github/workflows/write-all-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/write-all-workflow.yml grants contents: write outside ci.yml update-badge" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_quoted_contents_write_outside_badge_job() {
    local invalid_root="$TEMP_DIR/quoted-contents-write-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/quoted-contents-write-workflow.yml" \
        "$invalid_root/.github/workflows/quoted-contents-write-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/quoted-contents-write-workflow.yml grants contents: write outside ci.yml update-badge" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_alias_permissions() {
    local invalid_root="$TEMP_DIR/alias-contents-write-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/alias-contents-write-workflow.yml" \
        "$invalid_root/.github/workflows/alias-contents-write-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/alias-contents-write-workflow.yml uses unsupported YAML anchors or aliases" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_indirect_badge_writer() {
    local invalid_root="$TEMP_DIR/indirect-badge-writer-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/indirect-badge-writer.yml" \
        "$invalid_root/.github/workflows/indirect-badge-writer.yml"
    expect_failure "CI configuration error: .github/workflows/indirect-badge-writer.yml contains git push outside ci.yml update-badge" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_git_global_option_push() {
    local invalid_root="$TEMP_DIR/git-global-option-push-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/git-global-option-push-workflow.yml" \
        "$invalid_root/.github/workflows/git-global-option-push-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/git-global-option-push-workflow.yml contains git push outside ci.yml update-badge" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_git_flag_push() {
    local invalid_root="$TEMP_DIR/git-flag-push-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/git-flag-push-workflow.yml" \
        "$invalid_root/.github/workflows/git-flag-push-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/git-flag-push-workflow.yml contains git push outside ci.yml update-badge" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_rejects_git_line_continuation_push() {
    local invalid_root="$TEMP_DIR/git-line-continuation-push-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/git-line-continuation-push-workflow.yml" \
        "$invalid_root/.github/workflows/git-line-continuation-push-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/git-line-continuation-push-workflow.yml contains git push outside ci.yml update-badge" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_allows_read_only_workflow() {
    local valid_root="$TEMP_DIR/read-only-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$valid_root"
    cp "$FIXTURES_DIR/ci/read-only-workflow.yml" \
        "$valid_root/.github/workflows/read-only-workflow.yml"

    "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$valid_root"
}

test_ci_rejects_implicit_workflow_permissions() {
    local invalid_root="$TEMP_DIR/implicit-permissions-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/implicit-permissions-workflow.yml" \
        "$invalid_root/.github/workflows/implicit-permissions-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/implicit-permissions-workflow.yml must explicitly default contents to read-only" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_requires_read_only_default_permissions() {
    local invalid_root="$TEMP_DIR/missing-default-permissions-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/ci-without-default-permissions.yml" \
        "$invalid_root/.github/workflows/ci.yml"
    expect_failure "CI configuration error: CI must default workflow permissions to contents: read" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_requires_concurrency_guard() {
    local invalid_root="$TEMP_DIR/missing-concurrency-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/ci-without-concurrency.yml" \
        "$invalid_root/.github/workflows/ci.yml"
    expect_failure "CI configuration error: CI must define the ref-scoped concurrency guard" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_requires_scoped_badge_permissions() {
    local invalid_root="$TEMP_DIR/missing-badge-permissions-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_root"
    cp "$FIXTURES_DIR/ci/ci-without-badge-permissions.yml" \
        "$invalid_root/.github/workflows/ci.yml"
    expect_failure "CI configuration error: ci.yml update-badge must grant only contents: write" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_root"
}

test_ci_reports_stable_workflow_syntax_error() {
    local invalid_yaml_root="$TEMP_DIR/invalid-yaml-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_yaml_root"
    cat "$FIXTURES_DIR/ci/invalid-yaml-fragment.txt" \
        >> "$invalid_yaml_root/.github/workflows/ci.yml"
    expect_failure "CI configuration error: workflow syntax validation failed" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_yaml_root"
}

test_ci_rejects_non_reexport_aware_docc() {
    local invalid_docc_root="$TEMP_DIR/invalid-docc-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_docc_root"
    cp "$FIXTURES_DIR/ci/non-reexport-aware-documentation.sh" \
        "$invalid_docc_root/scripts/generate-documentation.sh"
    expect_failure "CI configuration error: DocC must include the public re-exported modules" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_docc_root"
}

test_ci_rejects_badge_without_tested_sha_provenance() {
    local invalid_badge_root="$TEMP_DIR/invalid-badge-provenance-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_badge_root"
    cp "$FIXTURES_DIR/ci/badge-without-provenance.yml" \
        "$invalid_badge_root/.github/workflows/ci.yml"
    expect_failure "CI configuration error: badge workflow must checkout the tested github.sha" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_badge_root"
}

test_ci_rejects_unpinned_reusable_workflow() {
    local invalid_reusable_root="$TEMP_DIR/invalid-reusable-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_reusable_root"
    cp "$FIXTURES_DIR/ci/unpinned-reusable-workflow.yml" \
        "$invalid_reusable_root/.github/workflows/unpinned-reusable-workflow.yml"
    expect_failure "CI configuration error: .github/workflows/unpinned-reusable-workflow.yml contains a moving external uses ref: main" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_reusable_root"
}

test_ci_rejects_missing_binary_hashes() {
    local invalid_hash_root="$TEMP_DIR/invalid-tool-hashes-ci"
    cp -R "$FIXTURES_DIR/ci/valid" "$invalid_hash_root"
    cp "$FIXTURES_DIR/ci/toolchain-without-binary-hashes.env" \
        "$invalid_hash_root/scripts/toolchain.env"
    expect_failure "CI configuration error: macOS SwiftLint binary checksum must be SHA-256" \
        "$PROJECT_DIR/scripts/validate-ci-configuration.sh" "$invalid_hash_root"
}

test_module_test_boundaries_are_enforced() {
    local valid_root="$FIXTURES_DIR/module-boundaries/valid"
    "$PROJECT_DIR/scripts/validate-test-boundaries.sh" "$valid_root"

    local invalid_import_root="$TEMP_DIR/invalid-test-import"
    cp -R "$valid_root" "$invalid_import_root"
    cp "$FIXTURES_DIR/module-boundaries/InvalidCoreTests.swift" \
        "$invalid_import_root/Tests/TUIkitCoreTests/InvalidCoreTests.swift"
    expect_failure \
        "Test boundary error: Tests/TUIkitCoreTests/InvalidCoreTests.swift imports forbidden project module TUIkit" \
        "$PROJECT_DIR/scripts/validate-test-boundaries.sh" "$invalid_import_root"

    local invalid_dependency_root="$TEMP_DIR/invalid-test-dependency"
    cp -R "$valid_root" "$invalid_dependency_root"
    sed -i.bak \
        's/dependencies: \["TUIkitCore"\]/dependencies: ["TUIkitCore", "TUIkit"]/' \
        "$invalid_dependency_root/Package.swift"
    find "$invalid_dependency_root" -name '*.bak' -delete
    expect_failure \
        "Test boundary error: Package.swift must declare the isolated TUIkitCoreTests dependency set exactly once" \
        "$PROJECT_DIR/scripts/validate-test-boundaries.sh" "$invalid_dependency_root"

    local native_source_root="$TEMP_DIR/native-source"
    cp -R "$valid_root" "$native_source_root"
    mkdir -p "$native_source_root/Sources/Decoder"
    touch "$native_source_root/Sources/Decoder/decoder.c"
    expect_failure \
        "Test boundary error: native source is forbidden: Sources/Decoder/decoder.c" \
        "$PROJECT_DIR/scripts/validate-test-boundaries.sh" "$native_source_root"
}

run_case() {
    local name="$1"
    local function_name="$2"

    if [[ "$TEST_CASE" == "all" || "$TEST_CASE" == "$name" ]]; then
        "$function_name"
    fi
}

run_case badge-count test_badge_uses_discovered_tests
run_case stale-readme test_badge_check_detects_stale_readme
run_case duplicate-test-badge test_badge_rejects_duplicate_markers
run_case duplicate-test-ids test_badge_rejects_duplicate_test_ids
run_case duplicate-project-marker test_badge_rejects_duplicate_project_markers
run_case duplicate-developer-marker test_badge_rejects_duplicate_developer_markers
run_case ci-configuration test_ci_configuration_is_deterministic
run_case duplicate-badge test_ci_rejects_duplicate_badge_writer
run_case direct-readme-writer test_ci_rejects_direct_readme_writer
run_case contents-write test_ci_rejects_contents_write_outside_badge_job
run_case write-all test_ci_rejects_write_all_outside_badge_job
run_case quoted-contents-write test_ci_rejects_quoted_contents_write_outside_badge_job
run_case alias-permissions test_ci_rejects_alias_permissions
run_case indirect-badge-writer test_ci_rejects_indirect_badge_writer
run_case git-global-option-push test_ci_rejects_git_global_option_push
run_case git-flag-push test_ci_rejects_git_flag_push
run_case git-line-continuation-push test_ci_rejects_git_line_continuation_push
run_case read-only-workflow test_ci_allows_read_only_workflow
run_case implicit-permissions test_ci_rejects_implicit_workflow_permissions
run_case default-permissions test_ci_requires_read_only_default_permissions
run_case concurrency-guard test_ci_requires_concurrency_guard
run_case badge-permissions test_ci_requires_scoped_badge_permissions
run_case invalid-yaml test_ci_reports_stable_workflow_syntax_error
run_case invalid-docc test_ci_rejects_non_reexport_aware_docc
run_case badge-provenance test_ci_rejects_badge_without_tested_sha_provenance
run_case reusable-workflow test_ci_rejects_unpinned_reusable_workflow
run_case binary-hashes test_ci_rejects_missing_binary_hashes
run_case module-boundaries test_module_test_boundaries_are_enforced

if [[ "$TEST_CASE" == "all" ]]; then
    "$PROJECT_DIR/scripts/tests/test-api-snapshot-scripts.sh"
    "$PROJECT_DIR/scripts/tests/test-owner-registry.sh"
    "$PROJECT_DIR/scripts/tests/test-tool-cache.sh"
    "$PROJECT_DIR/scripts/tests/test-quality-gate.sh"
    "$PROJECT_DIR/scripts/tests/test-linux-shell.sh"
fi

echo "Tooling self-tests passed"
