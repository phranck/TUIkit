#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_LIST=""
README_PATH="$PROJECT_DIR/README.md"
CHECK_ONLY=0
COUNT_ONLY=0
EXPECTED_TEST_TARGETS=()

count_pattern_occurrences() {
    local pattern="$1"
    local file="$2"

    awk -v pattern="$pattern" '
        {
            remaining = $0
            while (match(remaining, pattern)) {
                count += 1
                remaining = substr(remaining, RSTART + RLENGTH)
            }
        }
        END { print count + 0 }
    ' "$file"
}

count_shields_test_badges() {
    count_pattern_occurrences \
        'https://img[.]shields[.]io/badge/Tests-[0-9]+(%2B|[+])?_passing-005c00' \
        "$1"
}

count_test_discovery_markers() {
    count_pattern_occurrences 'Test discovery covers [0-9]+[+]? tests across all isolated targets' "$1"
}

count_developer_markers() {
    count_pattern_occurrences 'All [0-9]+[+]? tests run' "$1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --test-list)
            TEST_LIST="$2"
            shift 2
            ;;
        --readme)
            README_PATH="$2"
            shift 2
            ;;
        --check)
            CHECK_ONLY=1
            shift
            ;;
        --count-only)
            COUNT_ONLY=1
            shift
            ;;
        --expected-test-target)
            EXPECTED_TEST_TARGETS+=("$2")
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

if [[ -z "$TEST_LIST" || ! -f "$TEST_LIST" ]]; then
    echo "--test-list must reference output from 'swift test list'" >&2
    exit 2
fi

DUPLICATE_TEST_ID="$(awk '
    {
        test_id = $0
        sub(/^[[:space:]]+/, "", test_id)
        sub(/[[:space:]]+$/, "", test_id)
        if (test_id != "" && seen[test_id]++) {
            print test_id
            exit
        }
    }
' "$TEST_LIST")"
if [[ -n "$DUPLICATE_TEST_ID" ]]; then
    echo "Test list contains duplicate discovered test ID: $DUPLICATE_TEST_ID" >&2
    exit 1
fi

DISCOVERED_TEST_TARGETS="$(awk '
    {
        test_id = $0
        sub(/^[[:space:]]+/, "", test_id)
        sub(/[[:space:]]+$/, "", test_id)
        if (test_id != "") {
            target = test_id
            sub(/[.\/].*$/, "", target)
            if (target != "") {
                targets[target] = 1
            }
        }
    }
    END {
        for (target in targets) {
            print target
        }
    }
' "$TEST_LIST" | LC_ALL=C sort)"

if [[ "${#EXPECTED_TEST_TARGETS[@]}" -gt 0 ]]; then
    for expected_index in "${!EXPECTED_TEST_TARGETS[@]}"; do
        expected_target="${EXPECTED_TEST_TARGETS[$expected_index]}"
        for previous_index in "${!EXPECTED_TEST_TARGETS[@]}"; do
            if [[ "$previous_index" -ge "$expected_index" ]]; then
                break
            fi
            if [[ "${EXPECTED_TEST_TARGETS[$previous_index]}" == "$expected_target" ]]; then
                echo "Expected test target is listed more than once: $expected_target" >&2
                exit 2
            fi
        done

        if ! printf '%s\n' "$DISCOVERED_TEST_TARGETS" | grep -Fxq "$expected_target"; then
            echo "Test list is missing expected test target: $expected_target" >&2
            exit 1
        fi
    done

    while IFS= read -r discovered_target; do
        [[ -n "$discovered_target" ]] || continue
        is_expected=0
        for expected_target in "${EXPECTED_TEST_TARGETS[@]}"; do
            if [[ "$discovered_target" == "$expected_target" ]]; then
                is_expected=1
                break
            fi
        done
        if [[ "$is_expected" == "0" ]]; then
            echo "Test list contains unexpected test target: $discovered_target" >&2
            exit 1
        fi
    done <<< "$DISCOVERED_TEST_TARGETS"
fi

TEST_COUNT="$(awk '
    {
        test_id = $0
        sub(/^[[:space:]]+/, "", test_id)
        sub(/[[:space:]]+$/, "", test_id)
        if (test_id != "") {
            count += 1
        }
    }
    END { print count + 0 }
' "$TEST_LIST")"
if [[ "$TEST_COUNT" -le 0 ]]; then
    echo "No discovered tests found in $TEST_LIST" >&2
    exit 1
fi

if [[ "$COUNT_ONLY" == "1" ]]; then
    printf '%s\n' "$TEST_COUNT"
    exit 0
fi

if [[ ! -f "$README_PATH" ]]; then
    echo "README not found: $README_PATH" >&2
    exit 2
fi

BADGE_MARKER_COUNT="$(count_shields_test_badges "$README_PATH")"
if [[ "$BADGE_MARKER_COUNT" != "1" ]]; then
    echo "README must contain exactly one shields.io test badge marker" >&2
    exit 1
fi
DISCOVERY_COUNT_MARKERS="$(count_test_discovery_markers "$README_PATH")"
if [[ "$DISCOVERY_COUNT_MARKERS" != "1" ]]; then
    echo "README must contain exactly one test discovery count marker" >&2
    exit 1
fi
DEVELOPER_COUNT_MARKERS="$(count_developer_markers "$README_PATH")"
if [[ "$DEVELOPER_COUNT_MARKERS" != "1" ]]; then
    echo "README must contain exactly one developer test count marker" >&2
    exit 1
fi

TEMP_FILE="$(mktemp "${README_PATH}.XXXXXX")"
cleanup() {
    if [[ -f "$TEMP_FILE" ]]; then
        find "$TEMP_FILE" -delete
    fi
}
trap cleanup EXIT

sed -E \
    -e "s#(https://img[.]shields[.]io/badge/Tests-)[0-9]+(%2B|[+])?(_passing-005c00)#\\1${TEST_COUNT}\\3#g" \
    -e "s#(Test discovery covers )[0-9]+\\+?( tests across all isolated targets)#\\1${TEST_COUNT}\\2#g" \
    -e "s/(All )[0-9]+\\+?( tests run)/\\1${TEST_COUNT}\\2/g" \
    "$README_PATH" > "$TEMP_FILE"

UPDATED_BADGE_MARKER_COUNT="$(count_shields_test_badges "$TEMP_FILE")"
if [[ "$UPDATED_BADGE_MARKER_COUNT" != "1" ]]; then
    echo "README must contain exactly one updated shields.io test badge marker" >&2
    exit 1
fi
grep -Fq "https://img.shields.io/badge/Tests-${TEST_COUNT}_passing-005c00" "$TEMP_FILE" || {
    echo "README updated shields.io test badge marker not found" >&2
    exit 1
}
DISCOVERY_COUNT_MARKERS="$(count_test_discovery_markers "$TEMP_FILE")"
if [[ "$DISCOVERY_COUNT_MARKERS" != "1" ]]; then
    echo "README must contain exactly one test discovery count marker" >&2
    exit 1
fi
grep -Fq "Test discovery covers ${TEST_COUNT} tests across all isolated targets" "$TEMP_FILE" || {
    echo "README updated test discovery count marker not found" >&2
    exit 1
}
DEVELOPER_COUNT_MARKERS="$(count_developer_markers "$TEMP_FILE")"
if [[ "$DEVELOPER_COUNT_MARKERS" != "1" ]]; then
    echo "README must contain exactly one developer test count marker" >&2
    exit 1
fi
grep -Fq "All ${TEST_COUNT} tests run" "$TEMP_FILE" || {
    echo "README updated developer test count marker not found" >&2
    exit 1
}

if cmp -s "$README_PATH" "$TEMP_FILE"; then
    echo "README already reports $TEST_COUNT discovered tests"
    exit 0
fi

if [[ "$CHECK_ONLY" == "1" ]]; then
    echo "README does not report $TEST_COUNT discovered tests" >&2
    exit 1
fi

mv "$TEMP_FILE" "$README_PATH"
echo "Updated README to $TEST_COUNT discovered tests"
