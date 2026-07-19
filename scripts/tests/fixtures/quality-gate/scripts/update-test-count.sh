#!/usr/bin/env bash

set -euo pipefail

printf 'update-test-count %s\n' "$*" >> "$QUALITY_GATE_TEST_LOG"

test_list=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --test-list)
            test_list="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

[[ -f "$test_list" ]]
awk 'NF { count += 1 } END { print count + 0 }' "$test_list"
