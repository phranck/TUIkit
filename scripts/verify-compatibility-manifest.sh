#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

TOOL=""
POLICY=""
OWNER_REGISTRY=""
REFERENCE_SET=""
TUIKIT_SET=""
CONTRACTS=""
MANIFEST=""
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
        --tool|--policy|--owner-registry|--reference-set|--tuikit-set|--contracts|--manifest)
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
        --policy) POLICY="$value" ;;
        --owner-registry) OWNER_REGISTRY="$value" ;;
        --reference-set) REFERENCE_SET="$value" ;;
        --tuikit-set) TUIKIT_SET="$value" ;;
        --contracts) CONTRACTS="$value" ;;
        --manifest) MANIFEST="$value" ;;
    esac
done

require_option() {
    local value="$1"
    local option="$2"
    [[ -n "$value" ]] || usage_failure "Missing required option: $option"
}

require_option "$TOOL" --tool
require_option "$POLICY" --policy
require_option "$OWNER_REGISTRY" --owner-registry
require_option "$REFERENCE_SET" --reference-set
require_option "$TUIKIT_SET" --tuikit-set
require_option "$CONTRACTS" --contracts
require_option "$MANIFEST" --manifest

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

require_file() {
    local option="$1"
    local path="$2"
    [[ -f "$path" ]] || usage_failure "Input file not found for $option: $path"
}

TOOL="$(resolve_executable --tool "$TOOL")"
require_file --policy "$POLICY"
require_file --owner-registry "$OWNER_REGISTRY"
require_file --reference-set "$REFERENCE_SET"
require_file --tuikit-set "$TUIKIT_SET"
require_file --contracts "$CONTRACTS"
require_file --manifest "$MANIFEST"

TEMP_DIR="$(mktemp -d)"
cleanup() {
    find "$TEMP_DIR" -type f -delete
    find "$TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

GENERATED_MANIFEST="$TEMP_DIR/compatibility-manifest.json"
if ! "$TOOL" generate-manifest \
    --policy "$POLICY" \
    --owner-registry "$OWNER_REGISTRY" \
    --reference-set "$REFERENCE_SET" \
    --tuikit-set "$TUIKIT_SET" \
    --output "$GENERATED_MANIFEST" \
    > /dev/null; then
    fail "Unable to generate compatibility manifest from the current API snapshots"
fi

if ! cmp -s "$MANIFEST" "$GENERATED_MANIFEST"; then
    fail "Compatibility manifest is stale; regenerate it from the current API snapshots"
fi

if ! "$TOOL" validate-manifest \
    --manifest "$GENERATED_MANIFEST" \
    --reference-set "$REFERENCE_SET" \
    --tuikit-set "$TUIKIT_SET" \
    --contracts "$CONTRACTS" \
    > /dev/null; then
    fail "Generated compatibility manifest failed validation"
fi

echo "Compatibility manifest matches the current API snapshots."
