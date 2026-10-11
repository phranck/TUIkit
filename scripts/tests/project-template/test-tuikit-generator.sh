#!/usr/bin/env bash
#
# Integration tests for project-template/tuikit.
#
# Runs on macOS and Linux; requires bash, mktemp, and swift for the
# build check. Failures return non-zero so CI can gate.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GENERATOR="$REPO_ROOT/project-template/tuikit"

PASS_COUNT=0
FAIL_COUNT=0

pass() { printf "  ✓ %s\n" "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf "  ✗ %s\n" "$1" >&2; FAIL_COUNT=$((FAIL_COUNT + 1)); }

# --- Unit tests for internal functions -------------------------------------

# Source the generator so we can call individual functions without
# triggering the CLI. The `main` guard below early-exits when sourced.
export TUIKIT_TEST_HARNESS=1
# The script uses `set -e`; source it in a subshell that captures both
# stdout and the exit code.

run_helper() {
    # Extract and evaluate only the helper-function block: from the first
    # helper to the end of the "--- Argument parsing ---" banner comment.
    bash -c "$(awk '
        /^# --- Argument parsing/ { exit }
        /^# --- Platform detection/,/^$/ { print; next }
        /^detect_os\(\)/,/^\}$/ { print; next }
        /^detect_arch\(\)/,/^\}$/ { print; next }
        /^sanitize_swift_identifier\(\)/,/^\}$/ { print; next }
        /^validate_project_path_component\(\)/,/^\}$/ { print; next }
        /^resolve_install_path\(\)/,/^\}$/ { print; next }
    ' "$GENERATOR"); $*"
}

# sanitize_swift_identifier
result="$(run_helper 'sanitize_swift_identifier "MyApp"' || true)"
[ "$result" = "MyApp" ] && pass "identifier: MyApp" || fail "identifier: MyApp got '$result'"

result="$(run_helper 'sanitize_swift_identifier "my-app.2"' || true)"
[ "$result" = "my_app_2" ] && pass "identifier: my-app.2 → my_app_2" || fail "identifier: my-app.2 got '$result'"

result="$(run_helper 'sanitize_swift_identifier "3ThingsApp"' || true)"
[ "$result" = "_3ThingsApp" ] && pass "identifier: leading digit prefixed" || fail "identifier: leading digit got '$result'"

if run_helper 'sanitize_swift_identifier ""' >/dev/null 2>&1; then
    fail "identifier: empty must fail"
else
    pass "identifier: empty rejected"
fi

# validate_project_path_component
if run_helper 'validate_project_path_component ".."' >/dev/null 2>&1; then
    fail "path: '..' must reject"
else
    pass "path: '..' rejected"
fi

if run_helper 'validate_project_path_component "with/slash"' >/dev/null 2>&1; then
    fail "path: 'with/slash' must reject"
else
    pass "path: 'with/slash' rejected"
fi

if run_helper 'validate_project_path_component "safe-name"' >/dev/null 2>&1; then
    pass "path: 'safe-name' accepted"
else
    fail "path: 'safe-name' must accept"
fi

# detect_os / detect_arch
os="$(run_helper 'detect_os')"
case "$os" in
    macos|linux) pass "os: detected $os" ;;
    *) fail "os: unexpected '$os'" ;;
esac

arch="$(run_helper 'detect_arch')"
case "$arch" in
    x86_64|aarch64) pass "arch: detected $arch" ;;
    *) fail "arch: unexpected '$arch'" ;;
esac

# --- Integration: generate + build ----------------------------------------

TMPDIR_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_ROOT"' EXIT

cd "$TMPDIR_ROOT"

if TUIKIT_NON_INTERACTIVE=1 "$GENERATOR" init --yes "GeneratedApp" >/dev/null 2>&1; then
    if [ -f "GeneratedApp/Package.swift" ] && [ -f "GeneratedApp/Sources/App.swift" ]; then
        pass "generation: basic app produced expected files"
    else
        fail "generation: missing expected files"
    fi
else
    fail "generation: exited non-zero"
fi

# Reject unsafe names.
if TUIKIT_NON_INTERACTIVE=1 "$GENERATOR" init --yes ".." >/dev/null 2>&1; then
    fail "generation: '..' must be rejected"
else
    pass "generation: '..' rejected"
fi

# Sanitize hyphens in produced Swift identifier.
if TUIKIT_NON_INTERACTIVE=1 "$GENERATOR" init --yes "my-hyphen-app" >/dev/null 2>&1; then
    if grep -q 'name: "my_hyphen_app"' "my-hyphen-app/Package.swift"; then
        pass "generation: hyphens sanitized to underscores in Package.swift"
    else
        fail "generation: hyphens not sanitized (see Package.swift)"
    fi
else
    fail "generation: hyphen name exited non-zero"
fi

# --- Summary --------------------------------------------------------------

echo ""
echo "Passed: $PASS_COUNT"
echo "Failed: $FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
fi
