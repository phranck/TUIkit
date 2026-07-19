#!/usr/bin/env bash

# GitHub expressions and inspected shell snippets must remain literal.
# shellcheck disable=SC2016

set -euo pipefail

PROJECT_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
SCRIPT_PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW_DIR="$PROJECT_DIR/.github/workflows"
TOOLCHAIN_FILE="$PROJECT_DIR/scripts/toolchain.env"
QUALITY_GATE="$PROJECT_DIR/scripts/quality-gate.sh"
DOCC_SCRIPT="$PROJECT_DIR/scripts/generate-documentation.sh"

fail() {
    echo "CI configuration error: $1" >&2
    exit 1
}

extract_top_level_mapping() {
    local workflow="$1"
    local target="$2"

    awk -v target="$target" '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function normalize(line) {
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/[[:space:]]*$/, "", line)
            return line
        }
        {
            normalized = normalize($0)
            significant = normalized != ""
            current_indent = indentation($0)
            if (capturing) {
                if (significant && current_indent <= mapping_indent) {
                    exit
                }
                if (significant) {
                    print normalized
                }
                next
            }
            if (significant && current_indent == 0 && normalized == target ":") {
                capturing = 1
                mapping_indent = current_indent
                print normalized
            }
        }
    ' "$workflow"
}

count_job_blocks() {
    local workflow="$1"
    local target="$2"

    awk -v target="$target" '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function normalize(line) {
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/[[:space:]]*$/, "", line)
            return line
        }
        {
            normalized = normalize($0)
            significant = normalized != ""
            current_indent = indentation($0)
            if (!in_jobs && significant && current_indent == 0 && normalized == "jobs:") {
                in_jobs = 1
                jobs_indent = current_indent
                next
            }
            if (!in_jobs) {
                next
            }
            if (significant && current_indent <= jobs_indent) {
                in_jobs = 0
                next
            }
            if (significant && job_indent == 0) {
                job_indent = current_indent
            }
            if (significant && current_indent == job_indent && normalized == target ":") {
                count += 1
            }
        }
        END { print count + 0 }
    ' "$workflow"
}

extract_job_block() {
    local workflow="$1"
    local target="$2"

    awk -v target="$target" '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function normalize(line) {
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/[[:space:]]*$/, "", line)
            return line
        }
        {
            normalized = normalize($0)
            significant = normalized != ""
            current_indent = indentation($0)
            if (capturing) {
                if (significant && current_indent <= target_indent) {
                    exit
                }
                print
                next
            }
            if (!in_jobs && significant && current_indent == 0 && normalized == "jobs:") {
                in_jobs = 1
                jobs_indent = current_indent
                next
            }
            if (!in_jobs) {
                next
            }
            if (significant && current_indent <= jobs_indent) {
                in_jobs = 0
                next
            }
            if (significant && job_indent == 0) {
                job_indent = current_indent
            }
            if (significant && current_indent == job_indent && normalized == target ":") {
                capturing = 1
                target_indent = current_indent
                print
            }
        }
    ' "$workflow"
}

exclude_job_block() {
    local workflow="$1"
    local target="$2"

    awk -v target="$target" '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function normalize(line) {
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/[[:space:]]*$/, "", line)
            return line
        }
        {
            normalized = normalize($0)
            significant = normalized != ""
            current_indent = indentation($0)
            if (skipping) {
                if (!significant || current_indent > target_indent) {
                    next
                }
                skipping = 0
            }
            if (!in_jobs && significant && current_indent == 0 && normalized == "jobs:") {
                in_jobs = 1
                jobs_indent = current_indent
            } else if (in_jobs && significant && current_indent <= jobs_indent) {
                in_jobs = 0
            } else if (in_jobs && significant && job_indent == 0) {
                job_indent = current_indent
            }
            if (in_jobs && significant && current_indent == job_indent && normalized == target ":") {
                skipping = 1
                target_indent = current_indent
                next
            }
            print
        }
    ' "$workflow"
}

extract_direct_child_mapping() {
    local target="$1"

    awk -v target="$target" '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function normalize(line) {
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/[[:space:]]*$/, "", line)
            return line
        }
        {
            normalized = normalize($0)
            significant = normalized != ""
            current_indent = indentation($0)
            if (!parent_seen && significant) {
                parent_seen = 1
                parent_indent = current_indent
                next
            }
            if (!parent_seen || !significant) {
                next
            }
            if (capturing) {
                if (current_indent <= mapping_indent) {
                    exit
                }
                print normalized
                next
            }
            if (child_indent == 0) {
                child_indent = current_indent
            }
            if (current_indent == child_indent && normalized == target ":") {
                capturing = 1
                mapping_indent = current_indent
                print normalized
            }
        }
    '
}

has_contents_write_permission() {
    awk '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function normalize(line) {
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/[[:space:]]*$/, "", line)
            return line
        }
        {
            normalized = normalize($0)
            semantic = normalized
            gsub(/"/, "", semantic)
            single_quote = sprintf("%c", 39)
            gsub(single_quote, "", semantic)
            gsub(/[[:space:]]/, "", semantic)
            significant = normalized != ""
            current_indent = indentation($0)
            if (!significant) {
                next
            }
            if (in_permissions && current_indent <= permissions_indent) {
                in_permissions = 0
            }
            if (!in_jobs && current_indent == 0 && normalized == "jobs:") {
                in_jobs = 1
                jobs_indent = current_indent
                next
            }
            if (in_jobs && current_indent <= jobs_indent) {
                in_jobs = 0
                job_indent = 0
                child_indent = 0
            } else if (in_jobs) {
                if (job_indent == 0) {
                    job_indent = current_indent
                }
                if (current_indent == job_indent) {
                    child_indent = 0
                } else if (child_indent == 0) {
                    child_indent = current_indent
                }
            }
            is_permission_key = current_indent == 0 || \
                (in_jobs && child_indent != 0 && current_indent == child_indent)
            if (is_permission_key && semantic == "permissions:write-all") {
                found = 1
            }
            if (is_permission_key && semantic ~ /^permissions:[{][^}]*contents:write([,}]|$)/) {
                found = 1
            }
            if (is_permission_key && semantic == "permissions:") {
                in_permissions = 1
                permissions_indent = current_indent
                next
            }
            if (in_permissions && semantic == "contents:write") {
                found = 1
            }
        }
        END { exit found ? 0 : 1 }
    '
}

has_top_level_permissions_declaration() {
    awk '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function normalize(line) {
            sub(/^[[:space:]]*/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/[[:space:]]*$/, "", line)
            return line
        }
        {
            normalized = normalize($0)
            if (indentation($0) == 0 && normalized ~ /^permissions:/) {
                found = 1
            }
        }
        END { exit found ? 0 : 1 }
    '
}

has_yaml_anchor_or_alias() {
    local inspection_status=0

    awk '
        function indentation(line, stripped) {
            stripped = line
            sub(/^[[:space:]]*/, "", stripped)
            return length(line) - length(stripped)
        }
        function structural_text(line, output, position, character, next_character) {
            output = ""
            single_quote = sprintf("%c", 39)
            for (position = 1; position <= length(line); position += 1) {
                character = substr(line, position, 1)
                next_character = substr(line, position + 1, 1)
                if (in_single_quote) {
                    if (character == single_quote && next_character == single_quote) {
                        position += 1
                    } else if (character == single_quote) {
                        in_single_quote = 0
                    }
                    continue
                }
                if (in_double_quote) {
                    if (character == "\\") {
                        position += 1
                    } else if (character == "\"") {
                        in_double_quote = 0
                    }
                    continue
                }
                if (character == "#") {
                    break
                }
                if (character == single_quote) {
                    in_single_quote = 1
                    continue
                }
                if (character == "\"") {
                    in_double_quote = 1
                    continue
                }
                output = output character
            }
            in_single_quote = 0
            in_double_quote = 0
            return output
        }
        {
            current_indent = indentation($0)
            structural = structural_text($0)
            significant = structural ~ /[^[:space:]]/

            if (in_block_scalar) {
                if (significant && current_indent <= block_indent) {
                    in_block_scalar = 0
                } else {
                    next
                }
            }

            if (structural ~ /(^|[[:space:][\]{},:-])[&*][[:alnum:]_-]+([[:space:][\]{},#]|$)/) {
                found = 1
            }
            if (structural ~ /:[[:space:]]*[|>][-+0-9]*[[:space:]]*$/) {
                in_block_scalar = 1
                block_indent = current_indent
            }
        }
        END { exit found ? 0 : 1 }
    ' || inspection_status=$?

    (( inspection_status <= 1 )) || fail "unable to inspect workflow YAML anchors and aliases"
    return "$inspection_status"
}

has_git_push() {
    local inspection_status=0

    awk '
        function normalized_token(token) {
            gsub(/^["'"'"'`([{]+/, "", token)
            gsub(/["'"'"'`),;]}]+$/, "", token)
            return token
        }
        function is_git_command(token) {
            return token == "git" || \
                (length(token) >= 4 && substr(token, length(token) - 3) == "/git")
        }
        function option_requires_value(token) {
            return token == "-C" || token == "-c" || \
                token == "--git-dir" || token == "--work-tree" || \
                token == "--namespace" || token == "--super-prefix" || \
                token == "--config-env" || token == "--exec-path"
        }
        function inspect_command(line, token_count, tokens, token_index, token, candidate_index, candidate) {
            token_count = split(line, tokens, /[[:space:]]+/)
            for (token_index = 1; token_index <= token_count; token_index += 1) {
                token = normalized_token(tokens[token_index])
                if (!is_git_command(token)) {
                    continue
                }

                candidate_index = token_index + 1
                while (candidate_index <= token_count) {
                    candidate = normalized_token(tokens[candidate_index])
                    if (candidate == "push") {
                        found = 1
                        break
                    }
                    if (candidate == "\\") {
                        candidate_index += 1
                        continue
                    }
                    if (option_requires_value(candidate)) {
                        candidate_index += 2
                        continue
                    }
                    if (candidate ~ /^-/) {
                        candidate_index += 1
                        continue
                    }
                    break
                }
            }
        }
        /^[[:space:]]*#/ && !continuing { next }
        {
            physical_line = $0
            sub(/[[:space:]]+$/, "", physical_line)
            if (continuing) {
                logical_line = logical_line " " physical_line
            } else {
                logical_line = physical_line
            }

            if (logical_line ~ /\\$/) {
                sub(/\\$/, "", logical_line)
                continuing = 1
                next
            }

            continuing = 0
            inspect_command(logical_line)
            logical_line = ""
        }
        END {
            if (logical_line != "") {
                inspect_command(logical_line)
            }
            exit found ? 0 : 1
        }
    ' || inspection_status=$?

    (( inspection_status <= 1 )) || fail "unable to inspect workflow git commands"
    return "$inspection_status"
}

has_direct_readme_count_edit() {
    awk '
        /^[[:space:]]*#/ { next }
        {
            line = tolower($0)
            if (line ~ /readme([.]md)?/ && \
                (line ~ /(^|[;&|[:space:]])(sed|perl|awk|ruby|python|python3|mv|cp|tee|printf|echo)([[:space:]]|$)/ || \
                    line ~ /git[[:space:]]+add[[:space:]]+[^#]*readme/ || \
                    line ~ />[[:space:]]*readme([.]md)?/)) {
                readme_mutation = 1
            }
            if (line ~ /tests-|test[_ -]?count|tests run|tuikittests|test badge/) {
                test_count_hint = 1
            }
        }
        END { exit readme_mutation && test_count_hint ? 0 : 1 }
    '
}

normalized_line_count() {
    local text="$1"
    local expected="$2"

    printf '%s\n' "$text" | awk -v expected="$expected" '$0 == expected { count += 1 } END { print count + 0 }'
}

nonempty_line_count() {
    local text="$1"

    printf '%s\n' "$text" | awk 'NF { count += 1 } END { print count + 0 }'
}

for required_file in "$PROJECT_DIR/.swift-version" "$TOOLCHAIN_FILE" "$QUALITY_GATE" "$DOCC_SCRIPT"; do
    [[ -f "$required_file" ]] || fail "missing ${required_file#"$PROJECT_DIR"/}"
done
[[ -d "$WORKFLOW_DIR" ]] || fail "missing .github/workflows"

# shellcheck source=scripts/toolchain.env
# PROJECT_DIR may point at a validation fixture.
# shellcheck disable=SC1091
source "$TOOLCHAIN_FILE"

PINNED_SWIFT_VERSION="$(tr -d '[:space:]' < "$PROJECT_DIR/.swift-version")"
[[ "$PINNED_SWIFT_VERSION" =~ ^6\.0\.[0-9]+$ ]] || fail ".swift-version must pin one Swift 6.0 patch"
[[ "$PINNED_SWIFT_VERSION" == "$SWIFT_VERSION" ]] || fail ".swift-version and toolchain.env disagree"
[[ "$SWIFT_LINUX_IMAGE" == *"swift:${SWIFT_VERSION}-"*"@sha256:"* ]] || fail "Linux Swift image must match Swift $SWIFT_VERSION and include a digest"
[[ "${SWIFT_LINUX_IMAGE##*@sha256:}" =~ ^[0-9a-f]{64}$ ]] || fail "Linux Swift image digest must be a full SHA-256"
[[ "$SWIFTLINT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "SwiftLint must use an exact version"
[[ "$SWIFTLINT_MACOS_URL" == *"/$SWIFTLINT_VERSION/"* ]] || fail "macOS SwiftLint URL must contain its exact version"
[[ "$SWIFTLINT_LINUX_AMD64_URL" == *"/$SWIFTLINT_VERSION/"* ]] || fail "Linux SwiftLint URL must contain its exact version"
[[ "$SWIFTLINT_MACOS_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail "macOS SwiftLint checksum must be SHA-256"
[[ "$SWIFTLINT_LINUX_AMD64_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail "Linux SwiftLint checksum must be SHA-256"
[[ "${SWIFTLINT_MACOS_BINARY_SHA256:-}" =~ ^[0-9a-f]{64}$ ]] || fail "macOS SwiftLint binary checksum must be SHA-256"
[[ "${SWIFTLINT_LINUX_AMD64_BINARY_SHA256:-}" =~ ^[0-9a-f]{64}$ ]] || fail "Linux SwiftLint binary checksum must be SHA-256"
[[ "$ACTIONLINT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "actionlint must use an exact version"
[[ "$ACTIONLINT_MACOS_AMD64_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail "macOS amd64 actionlint checksum must be SHA-256"
[[ "$ACTIONLINT_MACOS_ARM64_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail "macOS arm64 actionlint checksum must be SHA-256"
[[ "$ACTIONLINT_LINUX_AMD64_SHA256" =~ ^[0-9a-f]{64}$ ]] || fail "Linux actionlint checksum must be SHA-256"
[[ "${ACTIONLINT_MACOS_AMD64_BINARY_SHA256:-}" =~ ^[0-9a-f]{64}$ ]] || fail "macOS amd64 actionlint binary checksum must be SHA-256"
[[ "${ACTIONLINT_MACOS_ARM64_BINARY_SHA256:-}" =~ ^[0-9a-f]{64}$ ]] || fail "macOS arm64 actionlint binary checksum must be SHA-256"
[[ "${ACTIONLINT_LINUX_AMD64_BINARY_SHA256:-}" =~ ^[0-9a-f]{64}$ ]] || fail "Linux actionlint binary checksum must be SHA-256"
[[ "${SWIFTUI_REFERENCE_RUNNER:-}" == "macos-26" ]] || fail "SwiftUI reference runner must be macos-26"
[[ "${SWIFTUI_REFERENCE_XCODE_VERSION:-}" == "26.6" ]] || fail "SwiftUI reference Xcode must be 26.6"
[[ "${SWIFTUI_REFERENCE_XCODE_BUILD:-}" == "17F113" ]] || fail "SwiftUI reference Xcode build must be 17F113"
[[ "${SWIFTUI_REFERENCE_XCODE_PATH:-}" == "/Applications/Xcode_26.6.app/Contents/Developer" ]] \
    || fail "SwiftUI reference Xcode path must select Xcode 26.6"

WORKFLOW_FILES=()
while IFS= read -r workflow; do
    WORKFLOW_FILES+=("$workflow")
done < <(find "$WORKFLOW_DIR" -type f \( -name '*.yml' -o -name '*.yaml' \) -print | sort)
[[ "${#WORKFLOW_FILES[@]}" -gt 0 ]] || fail "no workflow files found"

if [[ -z "${ACTIONLINT_BIN:-}" ]]; then
    case "$(uname -s)" in
        Darwin)
            ACTIONLINT_BIN="$("$SCRIPT_PROJECT_DIR"/scripts/install-actionlint.sh macos)"
            ;;
        Linux)
            ACTIONLINT_BIN="$("$SCRIPT_PROJECT_DIR"/scripts/install-actionlint.sh linux-amd64)"
            ;;
        *)
            fail "unsupported actionlint platform: $(uname -s)"
            ;;
    esac
fi
[[ -x "$ACTIONLINT_BIN" ]] || fail "ACTIONLINT_BIN is not executable"
if ! "$ACTIONLINT_BIN" "${WORKFLOW_FILES[@]}"; then
    fail "workflow syntax validation failed"
fi

for workflow in "${WORKFLOW_FILES[@]}"; do
    while IFS= read -r uses_line; do
        action_ref="${uses_line##*@}"
        action_ref="${action_ref%%[[:space:]#]*}"
        [[ "$action_ref" =~ ^[0-9a-f]{40}$ ]] || fail "${workflow#"$PROJECT_DIR"/} contains a moving external uses ref: $action_ref"
    done < <(grep -E '^[[:space:]]*(-[[:space:]]*)?uses:[[:space:]]*[^.]' "$workflow" || true)
done

grep -R -Eq 'brew install swiftlint|swift:6\.0([^.]|$)|ubuntu-latest|macos-latest' "$WORKFLOW_DIR" \
    && fail "workflow contains an unpinned tool or runner"
grep -R -Fq '@Test' "$WORKFLOW_DIR" && fail "workflow must not count source annotations"

BADGE_WORKFLOW_COUNT=0
for workflow in "${WORKFLOW_FILES[@]}"; do
    if grep -Fq 'scripts/update-test-count.sh' "$workflow"; then
        BADGE_WORKFLOW_COUNT=$((BADGE_WORKFLOW_COUNT + 1))
    fi
done
[[ "$BADGE_WORKFLOW_COUNT" == "1" ]] || fail "exactly one workflow must update the test count"

CI_WORKFLOW="$WORKFLOW_DIR/ci.yml"
[[ -f "$CI_WORKFLOW" ]] || fail "missing .github/workflows/ci.yml"

BADGE_JOB_COUNT="$(count_job_blocks "$CI_WORKFLOW" "update-badge")"
[[ "$BADGE_JOB_COUNT" == "1" ]] || fail "CI must define exactly one update-badge job"
BADGE_JOB_BLOCK="$(extract_job_block "$CI_WORKFLOW" "update-badge")"
BADGE_PERMISSIONS="$(printf '%s\n' "$BADGE_JOB_BLOCK" | extract_direct_child_mapping "permissions")"
[[ "$BADGE_PERMISSIONS" == $'permissions:\ncontents: write' ]] \
    || fail "ci.yml update-badge must grant only contents: write"

for workflow in "${WORKFLOW_FILES[@]}"; do
    relative_workflow="${workflow#"$PROJECT_DIR"/}"
    if has_yaml_anchor_or_alias < "$workflow"; then
        fail "$relative_workflow uses unsupported YAML anchors or aliases"
    fi
    if [[ "$workflow" == "$CI_WORKFLOW" ]]; then
        outside_badge_job="$(exclude_job_block "$workflow" "update-badge")"
    else
        outside_badge_job="$(< "$workflow")"
    fi

    if printf '%s\n' "$outside_badge_job" | has_contents_write_permission; then
        fail "$relative_workflow grants contents: write outside ci.yml update-badge"
    fi
    if [[ "$workflow" != "$CI_WORKFLOW" ]] \
        && ! printf '%s\n' "$outside_badge_job" | has_top_level_permissions_declaration; then
        fail "$relative_workflow must explicitly default contents to read-only"
    fi
    if grep -Fq 'scripts/update-test-count.sh' <<< "$outside_badge_job"; then
        fail "$relative_workflow invokes the test-count writer outside ci.yml update-badge"
    fi
    if printf '%s\n' "$outside_badge_job" | has_direct_readme_count_edit \
        && printf '%s\n' "$outside_badge_job" | has_git_push; then
        fail "$relative_workflow contains an unauthorized README writer with git push"
    fi
    if printf '%s\n' "$outside_badge_job" | has_git_push; then
        fail "$relative_workflow contains git push outside ci.yml update-badge"
    fi
done

CI_PERMISSIONS="$(extract_top_level_mapping "$CI_WORKFLOW" "permissions")"
[[ "$CI_PERMISSIONS" == $'permissions:\ncontents: read' ]] \
    || fail "CI must default workflow permissions to contents: read"

CI_CONCURRENCY="$(extract_top_level_mapping "$CI_WORKFLOW" "concurrency")"
if [[ "$(nonempty_line_count "$CI_CONCURRENCY")" != "3" ]] \
    || [[ "$(normalized_line_count "$CI_CONCURRENCY" "concurrency:")" != "1" ]] \
    || [[ "$(normalized_line_count "$CI_CONCURRENCY" 'group: ci-${{ github.ref }}')" != "1" ]] \
    || [[ "$(normalized_line_count "$CI_CONCURRENCY" "cancel-in-progress: \${{ github.event_name == 'pull_request' }}")" != "1" ]]; then
    fail "CI must define the ref-scoped concurrency guard"
fi

grep -Fq './scripts/test-linux.sh macos' "$CI_WORKFLOW" || fail "CI must use the local macOS gate path"
grep -Fq './scripts/test-linux.sh linux' "$CI_WORKFLOW" || fail "CI must use the local Linux gate path"
grep -Fq "$SWIFT_MACOS_XCODE_PATH" "$CI_WORKFLOW" || fail "CI must select the pinned macOS Swift toolchain"
grep -Fq 'ref: ${{ github.sha }}' "$CI_WORKFLOW" || fail "badge workflow must checkout the tested github.sha"
grep -Fq 'TESTED_SHA: ${{ github.sha }}' "$CI_WORKFLOW" || fail "badge workflow must record the tested github.sha"
grep -Fq 'git fetch --no-tags origin main' "$CI_WORKFLOW" || fail "badge workflow must fetch current origin/main"
grep -Fq 'if [[ "$REMOTE_MAIN_SHA" != "$TESTED_SHA" ]]; then' "$CI_WORKFLOW" || fail "badge workflow must reject a stale tested revision"
grep -Fq "steps.badge-provenance.outputs.stale == 'false'" "$CI_WORKFLOW" || fail "badge workflow must skip stale mutations"
grep -Fq 'if git push origin HEAD:main; then' "$CI_WORKFLOW" || fail "badge workflow must push explicitly and non-force to main"
grep -Eq 'git push[^#]*(--force([=[:space:]]|$)|[[:space:]]-f([[:space:]]|$))' "$CI_WORKFLOW" \
    && fail "badge workflow must not force-push"

REFERENCE_JOB_COUNT="$(count_job_blocks "$CI_WORKFLOW" "reference-snapshots")"
[[ "$REFERENCE_JOB_COUNT" == "1" ]] || fail "CI must define exactly one reference-snapshots job"
REFERENCE_JOB_BLOCK="$(extract_job_block "$CI_WORKFLOW" "reference-snapshots")"
grep -Fq "runs-on: $SWIFTUI_REFERENCE_RUNNER" <<< "$REFERENCE_JOB_BLOCK" \
    || fail "reference snapshots must run on $SWIFTUI_REFERENCE_RUNNER"
grep -Fq "$SWIFTUI_REFERENCE_XCODE_PATH" <<< "$REFERENCE_JOB_BLOCK" \
    || fail "reference snapshots must select the pinned Xcode"
grep -Fq 'generate-swiftui-reference-snapshots.sh' <<< "$REFERENCE_JOB_BLOCK" \
    || fail "reference snapshots must use the reviewed orchestrator"
grep -Fq 'name: swiftui-reference-snapshots' <<< "$REFERENCE_JOB_BLOCK" \
    || fail "reference snapshots must upload the stable artifact"
grep -Fq '${{ runner.temp }}' <<< "$REFERENCE_JOB_BLOCK" \
    || fail "reference snapshots must use runner.temp for artifact output"

MACOS_JOB_BLOCK="$(extract_job_block "$CI_WORKFLOW" "macos")"
LINUX_JOB_BLOCK="$(extract_job_block "$CI_WORKFLOW" "linux")"
grep -Fq 'TUIKIT_API_SNAPSHOT_OUTPUT: ${{ runner.temp }}/tuikit-macos-snapshots' \
    <<< "$MACOS_JOB_BLOCK" || fail "macOS CI must export TUIkit API snapshots"
grep -Fq 'name: tuikit-macos-snapshots' <<< "$MACOS_JOB_BLOCK" \
    || fail "macOS CI must upload TUIkit API snapshots"
grep -Fq 'TUIKIT_API_SNAPSHOT_OUTPUT: ${{ runner.temp }}/tuikit-linux-snapshots' \
    <<< "$LINUX_JOB_BLOCK" || fail "Linux CI must export TUIkit API snapshots"
grep -Fq 'name: tuikit-linux-snapshots' <<< "$LINUX_JOB_BLOCK" \
    || fail "Linux CI must upload TUIkit API snapshots"

API_JOB_COUNT="$(count_job_blocks "$CI_WORKFLOW" "api-compatibility")"
[[ "$API_JOB_COUNT" == "1" ]] || fail "CI must define exactly one api-compatibility job"
API_JOB_BLOCK="$(extract_job_block "$CI_WORKFLOW" "api-compatibility")"
grep -Fq 'needs: [reference-snapshots, macos, linux]' <<< "$API_JOB_BLOCK" \
    || fail "API compatibility must consume all snapshot producers"
grep -Fq 'name: swiftui-reference-snapshots' <<< "$API_JOB_BLOCK" \
    || fail "API compatibility must download the reference snapshots"
grep -Fq 'name: tuikit-macos-snapshots' <<< "$API_JOB_BLOCK" \
    || fail "API compatibility must download the macOS snapshots"
grep -Fq 'name: tuikit-linux-snapshots' <<< "$API_JOB_BLOCK" \
    || fail "API compatibility must download the Linux snapshots"
grep -Fq 'assemble-api-snapshot-set.sh' <<< "$API_JOB_BLOCK" \
    || fail "API compatibility must assemble the cross-platform TUIkit set"
grep -Fq 'verify-compatibility-owner-registry.sh' <<< "$API_JOB_BLOCK" \
    || fail "API compatibility must verify owner issue metadata"
grep -Fq 'name: api-compatibility-inputs' <<< "$API_JOB_BLOCK" \
    || fail "API compatibility must upload the assembled inputs"

BADGE_NEEDS="$(printf '%s\n' "$BADGE_JOB_BLOCK" | grep -F 'needs:' | sed -n '1p')"
[[ "$BADGE_NEEDS" == *"api-compatibility"* ]] \
    || fail "badge updates must wait for API compatibility"
DOCC_JOB_BLOCK="$(extract_job_block "$CI_WORKFLOW" "deploy-docs")"
DOCC_NEEDS="$(printf '%s\n' "$DOCC_JOB_BLOCK" | grep -F 'needs:' | sed -n '1p')"
[[ "$DOCC_NEEDS" == *"api-compatibility"* ]] \
    || fail "documentation deployment must wait for API compatibility"

PROVENANCE_LINE="$(grep -nF 'if [[ "$REMOTE_MAIN_SHA" != "$TESTED_SHA" ]]; then' "$CI_WORKFLOW" | sed -n '1s/:.*//p')"
MUTATION_LINE="$(grep -nF 'scripts/update-test-count.sh' "$CI_WORKFLOW" | sed -n '1s/:.*//p')"
[[ "$PROVENANCE_LINE" -lt "$MUTATION_LINE" ]] || fail "badge workflow must verify origin/main before mutation"

grep -Fq 'lint --strict --no-cache' "$QUALITY_GATE" || fail "SwiftLint must be strict with caching disabled"
grep -Fq -- '-warnings-as-errors' "$QUALITY_GATE" || fail "compiler warnings must be fatal"
grep -Fq 'generate-documentation.sh' "$QUALITY_GATE" || fail "quality gate must include DocC"
grep -Fq -- '--warnings-as-errors' "$DOCC_SCRIPT" || fail "DocC warnings must be fatal"
grep -Fq 'swift-symbolgraph-extract' "$DOCC_SCRIPT" || fail "DocC must use the pinned toolchain symbol extractor"
grep -Fq -- '-experimental-allowed-reexported-modules=TUIkitCore,TUIkitStyling,TUIkitImage,TUIkitView' \
    "$DOCC_SCRIPT" || fail "DocC must include the public re-exported modules"
grep -Fq 'convert Sources/TUIkit/TUIkit.docc' "$DOCC_SCRIPT" || fail "DocC must compile the authoritative catalog"
grep -Fq -- '-Xswiftc -warnings-as-errors' "$DOCC_SCRIPT" || fail "DocC's module build must reject compiler warnings"
grep -Fq 'python3' "$DOCC_SCRIPT" && fail "DocC must not require tools absent from the pinned Linux image"

echo "CI configuration is deterministic"
