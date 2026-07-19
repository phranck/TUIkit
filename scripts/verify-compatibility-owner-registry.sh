#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

TOOL=""
REGISTRY=""
EXPECTED_REPOSITORY=""
GH=""
SEEN_OPTIONS="|"

fail() {
    echo "$1" >&2
    exit 1
}

usage_failure() {
    echo "$1" >&2
    exit 2
}

mark_option() {
    local option="$1"
    case "$SEEN_OPTIONS" in
        *"|$option|"*) usage_failure "Duplicate option: $option" ;;
    esac
    SEEN_OPTIONS="${SEEN_OPTIONS}${option}|"
}

while [[ $# -gt 0 ]]; do
    option="$1"
    case "$option" in
        --tool|--registry|--repository|--gh)
            [[ $# -ge 2 && -n "${2:-}" ]] || usage_failure "Missing value for $option"
            mark_option "$option"
            value="$2"
            shift 2
            ;;
        *)
            usage_failure "Unknown option: $option"
            ;;
    esac

    case "$option" in
        --tool) TOOL="$value" ;;
        --registry) REGISTRY="$value" ;;
        --repository) EXPECTED_REPOSITORY="$value" ;;
        --gh) GH="$value" ;;
    esac
done

require_option() {
    local value="$1"
    local option="$2"
    [[ -n "$value" ]] || usage_failure "Missing required option: $option"
}

require_option "$TOOL" --tool
require_option "$REGISTRY" --registry
require_option "$EXPECTED_REPOSITORY" --repository
require_option "$GH" --gh

resolve_executable() {
    local option="$1"
    local executable="$2"
    local resolved=""
    if [[ "$executable" == */* ]]; then
        [[ -f "$executable" && -x "$executable" ]] || {
            usage_failure "Executable not found for $option: $executable"
        }
        printf '%s\n' "$executable"
        return
    fi
    resolved="$(command -v "$executable" 2>/dev/null || true)"
    [[ -n "$resolved" && -f "$resolved" && -x "$resolved" ]] || {
        usage_failure "Executable not found for $option: $executable"
    }
    printf '%s\n' "$resolved"
}

TOOL="$(resolve_executable --tool "$TOOL")"
GH="$(resolve_executable --gh "$GH")"
[[ -f "$REGISTRY" ]] || usage_failure "Owner registry not found: $REGISTRY"
if [[ ! "$EXPECTED_REPOSITORY" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    usage_failure "Invalid --repository: $EXPECTED_REPOSITORY"
fi

TEMP_DIR="$(mktemp -d)"
cleanup() {
    find "$TEMP_DIR" -type f -delete
    find "$TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

REGISTRY_TSV="$TEMP_DIR/owners.tsv"
if ! "$TOOL" list-owner-registry --owner-registry "$REGISTRY" > "$REGISTRY_TSV"; then
    fail "Unable to read compatibility owner registry: $REGISTRY"
fi

EXPECTED_HEADER=$'repository\tissueNumber\ttitle\turl'
HEADER_READ=false
ISSUE_COUNT=0
GH_TEMPLATE='{{.number}}{{"\t"}}{{.title}}{{"\t"}}{{.url}}{{"\n"}}'

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$HEADER_READ" == false ]]; then
        [[ "$line" == "$EXPECTED_HEADER" ]] || fail "Compatibility owner registry TSV has an invalid header"
        HEADER_READ=true
        continue
    fi

    repository=""
    issue_number=""
    title=""
    url=""
    extra=""
    IFS=$'\t' read -r repository issue_number title url extra <<< "$line"
    expected_line="$repository"$'\t'"$issue_number"$'\t'"$title"$'\t'"$url"
    [[ -n "$repository" && -n "$issue_number" && -n "$title" && -n "$url" \
        && -z "$extra" && "$line" == "$expected_line" ]] || {
        fail "Compatibility owner registry TSV contains a malformed issue record"
    }
    [[ "$repository" == "$EXPECTED_REPOSITORY" ]] || {
        fail "Owner registry repository '$repository' does not match expected repository '$EXPECTED_REPOSITORY'"
    }

    gh_output=""
    if ! gh_output="$(
        "$GH" issue view "$issue_number" \
            --repo "$EXPECTED_REPOSITORY" \
            --json number,title,url \
            --template "$GH_TEMPLATE"
    )"; then
        fail "Unable to read owner issue #$issue_number from $EXPECTED_REPOSITORY"
    fi
    case "$gh_output" in
        *$'\n'*) fail "Owner issue #$issue_number returned malformed metadata" ;;
    esac

    actual_number=""
    actual_title=""
    actual_url=""
    actual_extra=""
    IFS=$'\t' read -r actual_number actual_title actual_url actual_extra <<< "$gh_output"
    actual_line="$actual_number"$'\t'"$actual_title"$'\t'"$actual_url"
    [[ -n "$actual_number" && -n "$actual_title" && -n "$actual_url" \
        && -z "$actual_extra" && "$gh_output" == "$actual_line" ]] || {
        fail "Owner issue #$issue_number returned malformed metadata"
    }
    [[ "$actual_number" == "$issue_number" ]] || {
        fail "Owner issue #$issue_number returned number '$actual_number'"
    }
    [[ "$actual_title" == "$title" ]] || {
        fail "Owner issue #$issue_number title does not match the registry"
    }
    [[ "$actual_url" == "$url" ]] || {
        fail "Owner issue #$issue_number URL does not match the registry"
    }
    ISSUE_COUNT=$((ISSUE_COUNT + 1))
done < "$REGISTRY_TSV"

[[ "$HEADER_READ" == true ]] || fail "Compatibility owner registry TSV is empty"
[[ "$ISSUE_COUNT" -gt 0 ]] || fail "Compatibility owner registry TSV contains no issues"

echo "Verified $ISSUE_COUNT compatibility owner issues in $EXPECTED_REPOSITORY."
