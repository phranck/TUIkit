#!/usr/bin/env bash

set -euo pipefail

export LC_ALL=C

TOOL=""
SET_NAME=""
OUTPUT_ROOT=""
COVERAGE=""
SEEN_OPTIONS="|"

fail() {
    echo "$1" >&2
    exit 2
}

mark_option() {
    local option="$1"
    case "$SEEN_OPTIONS" in
        *"|$option|"*) fail "Duplicate option: $option" ;;
    esac
    SEEN_OPTIONS="${SEEN_OPTIONS}${option}|"
}

while [[ $# -gt 0 ]]; do
    option="$1"
    case "$option" in
        --tool|--name|--coverage|--output-root)
            [[ $# -ge 2 && -n "${2:-}" ]] || fail "Missing value for $option"
            mark_option "$option"
            value="$2"
            shift 2
            ;;
        *)
            fail "Unknown option: $option"
            ;;
    esac

    case "$option" in
        --tool) TOOL="$value" ;;
        --name) SET_NAME="$value" ;;
        --coverage) COVERAGE="$value" ;;
        --output-root) OUTPUT_ROOT="$value" ;;
    esac
done

[[ -n "$TOOL" ]] || fail "Missing required option: --tool"
[[ -n "$SET_NAME" ]] || fail "Missing required option: --name"
[[ -n "$COVERAGE" ]] || fail "Missing required option: --coverage"
[[ -n "$OUTPUT_ROOT" ]] || fail "Missing required option: --output-root"
case "$SET_NAME" in
    *$'\t'*|*$'\r'*|*$'\n'*) fail "Invalid control character in --name" ;;
    [[:space:]]*|*[[:space:]]) fail "Padded value for --name" ;;
esac

if [[ "$TOOL" == */* ]]; then
    [[ -f "$TOOL" && -x "$TOOL" ]] || fail "Executable not found for --tool: $TOOL"
else
    RESOLVED_TOOL="$(command -v "$TOOL" 2>/dev/null || true)"
    [[ -n "$RESOLVED_TOOL" && -f "$RESOLVED_TOOL" && -x "$RESOLVED_TOOL" ]] || {
        fail "Executable not found for --tool: $TOOL"
    }
fi
[[ -d "$OUTPUT_ROOT" ]] || fail "Directory not found for --output-root: $OUTPUT_ROOT"
[[ -f "$COVERAGE" ]] || fail "Coverage metadata file not found: $COVERAGE"

COVERAGE_VALID_FIELDS="$(awk -F '\t' '
    NF != 2 { invalid = 1 }
    {
        for (field_index = 1; field_index <= NF; field_index += 1) {
            if ($field_index == "" || $field_index ~ /^[[:space:]]/ || $field_index ~ /[[:space:]]$/) {
                invalid = 1
            }
        }
    }
    END { print (NR > 0 && !invalid) ? 1 : 0 }
' "$COVERAGE")"
if [[ "$COVERAGE_VALID_FIELDS" != "1" ]] || ! sort -c -u "$COVERAGE" >/dev/null 2>&1; then
    fail "Coverage metadata must be a sorted unique 2-column TSV: $COVERAGE"
fi

SOURCE_DIRECTORY="$OUTPUT_ROOT/sources"
[[ -d "$SOURCE_DIRECTORY" ]] || {
    fail "Source metadata directory not found: $SOURCE_DIRECTORY"
}
SOURCE_FILES=("$SOURCE_DIRECTORY"/*.tsv)
[[ -e "${SOURCE_FILES[0]}" ]] || fail "No source TSV files found in: $SOURCE_DIRECTORY"

COMBINED_SOURCES="$OUTPUT_ROOT/sources.tsv"
SET_OUTPUT="$OUTPUT_ROOT/snapshot-set.json"
for output in "$COMBINED_SOURCES" "$SET_OUTPUT"; do
    [[ ! -e "$output" && ! -L "$output" ]] || fail "Output already exists: $output"
done

SEEN_SOURCE_IDS="|"
for source_file in "${SOURCE_FILES[@]}"; do
    LINE_COUNT="$(awk 'END { print NR + 0 }' "$source_file")"
    COLUMN_COUNT="$(awk -F '\t' 'NR == 1 { print NF + 0 }' "$source_file")"
    VALID_FIELDS="$(awk -F '\t' '
        NR != 1 || NF != 9 { invalid = 1 }
        {
            for (field_index = 1; field_index <= NF; field_index += 1) {
                if ($field_index == "" || $field_index ~ /^[[:space:]]/ || $field_index ~ /[[:space:]]$/) {
                    invalid = 1
                }
            }
        }
        END { print invalid ? 0 : 1 }
    ' "$source_file")"
    if [[ "$LINE_COUNT" != "1" || "$COLUMN_COUNT" != "9" || "$VALID_FIELDS" != "1" ]]; then
        fail "Source metadata must contain one 9-column TSV line: $source_file"
    fi

    SOURCE_ID="$(awk -F '\t' 'NR == 1 { print $1 }' "$source_file")"
    if [[ ! "$SOURCE_ID" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        fail "Invalid source ID in $source_file: $SOURCE_ID"
    fi
    case "$SEEN_SOURCE_IDS" in
        *"|$SOURCE_ID|"*) fail "Duplicate source ID: $SOURCE_ID" ;;
    esac
    SEEN_SOURCE_IDS="${SEEN_SOURCE_IDS}${SOURCE_ID}|"

    SNAPSHOT_PATH="$(awk -F '\t' 'NR == 1 { print $9 }' "$source_file")"
    case "$SNAPSHOT_PATH" in
        /*|*\\*|../*|*/../*|*/..|./*|*/./*|*/.)
            fail "Unsafe snapshot path for source '$SOURCE_ID': $SNAPSHOT_PATH"
            ;;
    esac
    REFERENCED_SNAPSHOT="$OUTPUT_ROOT/$SNAPSHOT_PATH"
    [[ -f "$REFERENCED_SNAPSHOT" ]] || {
        fail "Referenced snapshot not found for source '$SOURCE_ID': $REFERENCED_SNAPSHOT"
    }
done

sort "${SOURCE_FILES[@]}" > "$COMBINED_SOURCES"
"$TOOL" write-snapshot-set \
    --name "$SET_NAME" \
    --sources "$COMBINED_SOURCES" \
    --coverage "$COVERAGE" \
    --output "$SET_OUTPUT"

[[ -f "$SET_OUTPUT" ]] || fail "Snapshot set was not created: $SET_OUTPUT"
