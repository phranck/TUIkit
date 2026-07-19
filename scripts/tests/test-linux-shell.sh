#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES_DIR="$PROJECT_DIR/scripts/tests/fixtures/docker"
TEMP_DIR="$(mktemp -d)"

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
    grep -Fq -- "$expected" "$file" || fail "$file does not contain: $expected"
}

DOCKER_STUB_LOG="$TEMP_DIR/docker.log" \
PATH="$FIXTURES_DIR/bin:$PATH" \
    "$PROJECT_DIR/scripts/test-linux.sh" shell > "$TEMP_DIR/stdout" 2> "$TEMP_DIR/stderr"

assert_contains "$TEMP_DIR/docker.log" '-v'
assert_contains "$TEMP_DIR/docker.log" "$PROJECT_DIR:/workspace:ro"
assert_contains "$TEMP_DIR/docker.log" 'tar --exclude=.build --exclude=docc-output -C /workspace -cf - . | tar -C /tmp/src -xf -'
assert_contains "$TEMP_DIR/docker.log" 'cd /tmp/src'
assert_contains "$TEMP_DIR/docker.log" 'exec /bin/bash'

snapshot_output="$TEMP_DIR/api output"
mkdir -p "$snapshot_output"
DOCKER_STUB_LOG="$TEMP_DIR/docker-api.log" \
PATH="$FIXTURES_DIR/bin:$PATH" \
SWIFTLINT_BIN="$FIXTURES_DIR/bin/docker" \
ACTIONLINT_BIN="$FIXTURES_DIR/bin/docker" \
TUIKIT_API_SNAPSHOT_OUTPUT="$snapshot_output" \
    "$PROJECT_DIR/scripts/test-linux.sh" linux > "$TEMP_DIR/api-stdout" 2> "$TEMP_DIR/api-stderr"

assert_contains "$TEMP_DIR/docker-api.log" "$snapshot_output:/api-snapshots"
assert_contains "$TEMP_DIR/docker-api.log" 'TUIKIT_CONTAINER_API_SNAPSHOT_OUTPUT=/api-snapshots'
assert_contains "$TEMP_DIR/docker-api.log" 'generate-tuikit-api-snapshots.sh'
assert_contains "$TEMP_DIR/docker-api.log" '--output-root "$TUIKIT_CONTAINER_API_SNAPSHOT_OUTPUT"'

echo "Linux shell self-test passed"
