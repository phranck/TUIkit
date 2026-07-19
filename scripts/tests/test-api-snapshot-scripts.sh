#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
GENERATE_SCRIPT="$PROJECT_DIR/scripts/generate-api-snapshot-source.sh"
ASSEMBLE_SCRIPT="$PROJECT_DIR/scripts/assemble-api-snapshot-set.sh"
GENERATE_REFERENCE_SCRIPT="$PROJECT_DIR/scripts/generate-swiftui-reference-snapshots.sh"
GENERATE_TUIKIT_SCRIPT="$PROJECT_DIR/scripts/generate-tuikit-api-snapshots.sh"
API_PACKAGE="$PROJECT_DIR/Tools/APICompatibility/Package.swift"
TEST_TEMP_DIR="$(mktemp -d)"
FAILURE_INDEX=0
TEST_TAB=$'\t'

cleanup() {
    find "$TEST_TEMP_DIR" -type f -delete
    find "$TEST_TEMP_DIR" -depth -type d -delete
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local expected="$2"

    grep -Fq -- "$expected" "$file" || fail "$file does not contain: $expected"
}

assert_file_not_exists() {
    local file="$1"

    [[ ! -e "$file" ]] || fail "unexpected path exists: $file"
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

make_fake_tools() {
    local root="$1"
    local bin_dir="$root/bin with spaces"
    mkdir -p "$bin_dir"
    FAKE_API_TOOL="$bin_dir/fake-api-tool"
    FAKE_EXTRACTOR="$bin_dir/fake-extractor"

    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$FAKE_EXTRACTOR"
    chmod +x "$FAKE_EXTRACTOR"

    cat > "$FAKE_API_TOOL" <<'FAKE_TOOL'
#!/usr/bin/env bash

set -euo pipefail

find_option() {
    local requested="$1"
    shift
    while [[ $# -gt 0 ]]; do
        if [[ "$1" == "$requested" ]]; then
            printf '%s\n' "$2"
            return 0
        fi
        shift 2
    done
    return 1
}

command_name="$1"
shift
{
    printf '%s' "$command_name"
    for argument in "$@"; do
        printf '\t<%s>' "$argument"
    done
    printf '\n'
} >> "${FAKE_API_TOOL_LOG:?}"

case "$command_name" in
    extract)
        output="$(find_option --output "$@")"
        printf '{"module":"Fixture"}\n' > "$output/Fixture.symbols.json"
        ;;
    canonicalize)
        output="$(find_option --output "$@")"
        printf '{"schemaVersion":1}\n' > "$output"
        ;;
    write-snapshot-set)
        sources="$(find_option --sources "$@")"
        output="$(find_option --output "$@")"
        cp "$sources" "$output"
        ;;
    *)
        echo "Unexpected fake command: $command_name" >&2
        exit 64
        ;;
esac
FAKE_TOOL
    chmod +x "$FAKE_API_TOOL"
}

make_fake_xcode_tools() {
    local root="$1"
    local bin_dir="$root/fake-xcode-bin"
    FAKE_DEVELOPER_DIR="$root/Xcode_26.6.app/Contents/Developer"
    FAKE_XCODE_SDK_ROOT="$root/Xcode SDKs"
    FAKE_XCRUN_LOG="$root/xcrun.log"
    mkdir -p "$bin_dir" "$FAKE_DEVELOPER_DIR" "$FAKE_XCODE_SDK_ROOT"

    FAKE_XCODEBUILD="$bin_dir/xcodebuild"
    cat > "$FAKE_XCODEBUILD" <<'FAKE_XCODEBUILD_SCRIPT'
#!/usr/bin/env bash

set -euo pipefail

[[ "$*" == "-version" ]] || exit 64
printf 'Xcode %s\nBuild version %s\n' \
    "${FAKE_XCODE_VERSION:-26.6}" \
    "${FAKE_XCODE_BUILD:-17F113}"
FAKE_XCODEBUILD_SCRIPT
    chmod +x "$FAKE_XCODEBUILD"

    FAKE_XCRUN="$bin_dir/xcrun"
    cat > "$FAKE_XCRUN" <<'FAKE_XCRUN_SCRIPT'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "${FAKE_XCRUN_LOG:?}"

if [[ "$1" == "--find" && "$2" == "swift-symbolgraph-extract" ]]; then
    printf '%s\n' "${FAKE_EXTRACTOR:?}"
    exit 0
fi

if [[ "$1" == "swiftc" && "$2" == "--version" ]]; then
    printf '%s\n' "${FAKE_REFERENCE_COMPILER_VERSION:-Apple Swift version 6.2}"
    exit 0
fi

if [[ "$1" == "--sdk" ]]; then
    sdk_name="$2"
    query="$3"
    case "$query" in
        --show-sdk-path)
            sdk_path="${FAKE_XCODE_SDK_ROOT:?}/$sdk_name"
            mkdir -p "$sdk_path"
            printf '%s\n' "$sdk_path"
            ;;
        --show-sdk-version)
            printf '%s\n' "${FAKE_SDK_VERSION:-26.4}"
            ;;
        --show-sdk-build-version)
            printf '%s-build\n' "$sdk_name"
            ;;
        *)
            exit 64
            ;;
    esac
    exit 0
fi

exit 64
FAKE_XCRUN_SCRIPT
    chmod +x "$FAKE_XCRUN"

    FAKE_XCODE_BIN_DIR="$bin_dir"
}

make_fake_swift_tools() {
    local root="$1"
    local bin_dir="$root/fake-swift-bin"
    FAKE_SWIFT_BIN_PATH="$root/swift build"
    FAKE_SWIFT_LOG="$root/swift.log"
    mkdir -p "$bin_dir"

    FAKE_SWIFT="$bin_dir/swift"
    cat > "$FAKE_SWIFT" <<'FAKE_SWIFT_SCRIPT'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "${FAKE_SWIFT_LOG:?}"
case " $* " in
    *" --show-bin-path "*)
        printf '%s\n' "${FAKE_SWIFT_BIN_PATH:?}"
        ;;
    *)
        module_path="${FAKE_SWIFT_BIN_PATH:?}/Modules"
        mkdir -p "$module_path"
        for module in TUIkit TUIkitCore TUIkitImage TUIkitStyling TUIkitView; do
            : > "$module_path/$module.swiftmodule"
        done
        ;;
esac
FAKE_SWIFT_SCRIPT
    chmod +x "$FAKE_SWIFT"

    FAKE_SWIFTC="$bin_dir/swiftc"
    cat > "$FAKE_SWIFTC" <<'FAKE_SWIFTC_SCRIPT'
#!/usr/bin/env bash

set -euo pipefail

case "$1" in
    --version)
        printf '%s\n' "${FAKE_SWIFT_COMPILER_VERSION:-Swift version 6.0.3 (swift-6.0.3-RELEASE)}"
        ;;
    -print-target-info)
        printf '{\n  "target": {\n    "triple": "%s"\n  }\n}\n' \
            "${FAKE_SWIFT_TARGET:-x86_64-unknown-linux-gnu}"
        ;;
    *)
        exit 64
        ;;
esac
FAKE_SWIFTC_SCRIPT
    chmod +x "$FAKE_SWIFTC"

    FAKE_SYMBOL_EXTRACTOR="$bin_dir/swift-symbolgraph-extract"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$FAKE_SYMBOL_EXTRACTOR"
    chmod +x "$FAKE_SYMBOL_EXTRACTOR"

    FAKE_UNAME="$bin_dir/uname"
    cat > "$FAKE_UNAME" <<'FAKE_UNAME_SCRIPT'
#!/usr/bin/env bash

set -euo pipefail
printf '%s\n' "${FAKE_HOST_SYSTEM:-Linux}"
FAKE_UNAME_SCRIPT
    chmod +x "$FAKE_UNAME"

    FAKE_SWIFT_BIN_DIR="$bin_dir"
}

invoke_generate() {
    local output_root="$1"
    local source_id="$2"
    shift 2

    FAKE_API_TOOL_LOG="$output_root/tool.log" "$GENERATE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --extractor "$FAKE_EXTRACTOR" \
        --module Fixture \
        --source-id "$source_id" \
        --platform macOS \
        --target arm64-apple-macosx15.0 \
        --sdk-name macosx \
        --sdk-version 15.0 \
        --sdk-build 24A335 \
        --compiler-version "Swift 6.0.3" \
        --output-root "$output_root" \
        "$@"
}

write_source_record() {
    local output_root="$1"
    local filename="$2"
    local source_id="$3"
    local platform="$4"
    local snapshot_path="$5"

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$source_id" \
        Fixture \
        "$platform" \
        "target-$source_id" \
        sdk \
        1.0 \
        1A1 \
        "Swift 6.0.3" \
        "$snapshot_path" \
        > "$output_root/sources/$filename.tsv"
}

test_generate_writes_isolated_source_artifacts() {
    local root="$TEST_TEMP_DIR/generate-success"
    local output_root="$root/output with spaces"
    local sdk_path="$root/sdk with spaces"
    local swift_modules="$root/swift modules"
    local clang_modules="$root/clang modules"
    mkdir -p "$output_root" "$sdk_path" "$swift_modules" "$clang_modules"
    make_fake_tools "$root"

    invoke_generate "$output_root" fixture-macos \
        --sdk-path "$sdk_path" \
        --swift-module-path "$swift_modules" \
        --clang-module-path "$clang_modules"

    [[ -d "$output_root/raw/fixture-macos" ]] || fail "raw source directory was not created"
    [[ -f "$output_root/raw/fixture-macos/Fixture.symbols.json" ]] || {
        fail "fake extraction output is missing"
    }
    [[ -f "$output_root/snapshots/fixture-macos.json" ]] || fail "snapshot is missing"
    local source_record="$output_root/sources/fixture-macos.tsv"
    [[ "$(wc -l < "$source_record" | tr -d '[:space:]')" == "1" ]] || {
        fail "source metadata must contain exactly one line"
    }
    local expected_record
    expected_record="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
        fixture-macos Fixture macOS arm64-apple-macosx15.0 macosx 15.0 24A335 \
        "Swift 6.0.3" snapshots/fixture-macos.json)"
    [[ "$(cat "$source_record")" == "$expected_record" ]] || fail "source metadata is not exact"

    assert_file_contains "$output_root/tool.log" \
        "extract${TEST_TAB}<--extractor>${TEST_TAB}<$FAKE_EXTRACTOR>${TEST_TAB}<--module>${TEST_TAB}<Fixture>"
    assert_file_contains "$output_root/tool.log" \
        "<--sdk>${TEST_TAB}<$sdk_path>${TEST_TAB}<--swift-module-path>${TEST_TAB}<$swift_modules>${TEST_TAB}<--clang-module-path>${TEST_TAB}<$clang_modules>"
    assert_file_contains "$output_root/tool.log" \
        "canonicalize${TEST_TAB}<--module>${TEST_TAB}<Fixture>${TEST_TAB}<--symbol-graphs>${TEST_TAB}<$output_root/raw/fixture-macos>"
    assert_file_contains "$output_root/tool.log" \
        "<--extension-provenance>${TEST_TAB}<strict>"
    assert_file_contains "$output_root/tool.log" \
        "<--platform>${TEST_TAB}<macOS>${TEST_TAB}<--target>${TEST_TAB}<arm64-apple-macosx15.0>"
    assert_file_contains "$output_root/tool.log" \
        "<--sdk-name>${TEST_TAB}<macosx>${TEST_TAB}<--sdk-version>${TEST_TAB}<15.0>${TEST_TAB}<--sdk-build>${TEST_TAB}<24A335>${TEST_TAB}<--compiler-version>${TEST_TAB}<Swift 6.0.3>"
}

test_generate_rejects_unsafe_or_existing_targets() {
    local root="$TEST_TEMP_DIR/generate-invalid"
    local output_root="$root/output"
    mkdir -p "$output_root"
    make_fake_tools "$root"

    expect_failure "Invalid --source-id: ../escape" \
        invoke_generate "$output_root" ../escape

    mkdir -p "$output_root/raw/existing"
    printf 'keep\n' > "$output_root/raw/existing/sentinel"
    expect_failure "Output already exists: $output_root/raw/existing" \
        invoke_generate "$output_root" existing
    [[ "$(cat "$output_root/raw/existing/sentinel")" == "keep" ]] || {
        fail "existing raw output was modified"
    }

    mkdir -p "$output_root/snapshots"
    printf 'keep\n' > "$output_root/snapshots/existing-snapshot.json"
    expect_failure "Output already exists: $output_root/snapshots/existing-snapshot.json" \
        invoke_generate "$output_root" existing-snapshot
}

test_generate_validates_options_and_dependencies() {
    local root="$TEST_TEMP_DIR/generate-dependencies"
    local output_root="$root/output"
    mkdir -p "$output_root"
    make_fake_tools "$root"

    expect_failure "Directory not found for --sdk-path: $root/missing-sdk" \
        invoke_generate "$output_root" missing-sdk --sdk-path "$root/missing-sdk"
    expect_failure "Duplicate option: --module" \
        invoke_generate "$output_root" duplicate-module --module Other
    expect_failure "Unknown option: --unexpected" \
        invoke_generate "$output_root" unknown-option --unexpected value

    local missing_tool="$root/missing-tool"
    FAKE_API_TOOL_LOG="$output_root/tool.log" expect_failure \
        "Executable not found for --tool: $missing_tool" \
        "$GENERATE_SCRIPT" \
        --tool "$missing_tool" \
        --extractor "$FAKE_EXTRACTOR" \
        --module Fixture \
        --source-id missing-tool \
        --platform macOS \
        --target arm64-apple-macosx15.0 \
        --sdk-name macosx \
        --sdk-version 15.0 \
        --sdk-build 24A335 \
        --compiler-version "Swift 6.0.3" \
        --output-root "$output_root"
}

test_generate_resolves_executable_names_from_path() {
    local root="$TEST_TEMP_DIR/generate-path-resolution"
    local output_root="$root/output"
    mkdir -p "$output_root"
    make_fake_tools "$root"
    local tool_directory
    tool_directory="$(dirname "$FAKE_API_TOOL")"

    PATH="$tool_directory:$PATH" FAKE_API_TOOL_LOG="$output_root/tool.log" \
        "$GENERATE_SCRIPT" \
        --tool fake-api-tool \
        --extractor fake-extractor \
        --module Fixture \
        --source-id path-resolution \
        --platform macOS \
        --target arm64-apple-macosx15.0 \
        --sdk-name macosx \
        --sdk-version 15.0 \
        --sdk-build 24A335 \
        --compiler-version "Swift 6.0.3" \
        --output-root "$output_root"

    assert_file_contains "$output_root/tool.log" \
        "extract${TEST_TAB}<--extractor>${TEST_TAB}<$FAKE_EXTRACTOR>"
}

test_generate_never_evaluates_metadata() {
    local root="$TEST_TEMP_DIR/generate-no-eval"
    local output_root="$root/output"
    local marker="$root/evaluated"
    mkdir -p "$output_root"
    make_fake_tools "$root"

    FAKE_API_TOOL_LOG="$output_root/tool.log" "$GENERATE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --extractor "$FAKE_EXTRACTOR" \
        --module "Fixture; touch $marker" \
        --source-id no-eval \
        --platform macOS \
        --target arm64-apple-macosx15.0 \
        --sdk-name macosx \
        --sdk-version 15.0 \
        --sdk-build 24A335 \
        --compiler-version "Swift 6.0.3" \
        --output-root "$output_root"

    assert_file_not_exists "$marker"
    assert_file_contains "$output_root/tool.log" "<Fixture; touch $marker>"
}

test_assemble_sorts_sources_and_writes_descriptor() {
    local root="$TEST_TEMP_DIR/assemble-success"
    local output_root="$root/output with spaces"
    mkdir -p "$output_root/sources" "$output_root/snapshots"
    make_fake_tools "$root"
    printf '{}\n' > "$output_root/snapshots/z.json"
    printf '{}\n' > "$output_root/snapshots/a.json"
    local coverage="$root/coverage.tsv"
    printf '%s\t%s\n' Fixture Linux Fixture macOS > "$coverage"
    write_source_record "$output_root" source-z source-z macOS snapshots/z.json
    write_source_record "$output_root" source-a source-a Linux snapshots/a.json

    FAKE_API_TOOL_LOG="$output_root/tool.log" "$ASSEMBLE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --name "Fixture snapshots" \
        --coverage "$coverage" \
        --output-root "$output_root"

    local first_source
    local second_source
    first_source="$(sed -n '1s/\t.*//p' "$output_root/sources.tsv")"
    second_source="$(sed -n '2s/\t.*//p' "$output_root/sources.tsv")"
    [[ "$first_source" == "source-a" && "$second_source" == "source-z" ]] || {
        fail "assembled sources are not deterministically sorted"
    }
    cmp -s "$output_root/sources.tsv" "$output_root/snapshot-set.json" || {
        fail "fake descriptor does not contain the assembled sources"
    }
    assert_file_contains "$output_root/tool.log" \
        "write-snapshot-set${TEST_TAB}<--name>${TEST_TAB}<Fixture snapshots>${TEST_TAB}<--sources>${TEST_TAB}<$output_root/sources.tsv>"
    assert_file_contains "$output_root/tool.log" \
        "<--coverage>${TEST_TAB}<$coverage>${TEST_TAB}<--output>${TEST_TAB}<$output_root/snapshot-set.json>"
}

test_assemble_rejects_duplicate_ids_and_missing_snapshots() {
    local duplicate_root="$TEST_TEMP_DIR/assemble-duplicate"
    mkdir -p "$duplicate_root/sources" "$duplicate_root/snapshots"
    make_fake_tools "$duplicate_root"
    printf '{}\n' > "$duplicate_root/snapshots/one.json"
    printf '%s\t%s\n' Fixture Linux Fixture macOS > "$duplicate_root/coverage.tsv"
    write_source_record "$duplicate_root" first duplicate Linux snapshots/one.json
    write_source_record "$duplicate_root" second duplicate macOS snapshots/one.json

    FAKE_API_TOOL_LOG="$duplicate_root/tool.log" expect_failure \
        "Duplicate source ID: duplicate" \
        "$ASSEMBLE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --name Fixture \
        --coverage "$duplicate_root/coverage.tsv" \
        --output-root "$duplicate_root"
    assert_file_not_exists "$duplicate_root/tool.log"

    local missing_root="$TEST_TEMP_DIR/assemble-missing"
    mkdir -p "$missing_root/sources" "$missing_root/snapshots"
    make_fake_tools "$missing_root"
    printf '%s\t%s\n' Fixture Linux > "$missing_root/coverage.tsv"
    write_source_record "$missing_root" missing missing Linux snapshots/missing.json
    FAKE_API_TOOL_LOG="$missing_root/tool.log" expect_failure \
        "Referenced snapshot not found for source 'missing': $missing_root/snapshots/missing.json" \
        "$ASSEMBLE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --name Fixture \
        --coverage "$missing_root/coverage.tsv" \
        --output-root "$missing_root"
    assert_file_not_exists "$missing_root/tool.log"
}

test_assemble_rejects_missing_or_malformed_inputs() {
    local missing_root="$TEST_TEMP_DIR/assemble-no-sources"
    mkdir -p "$missing_root"
    make_fake_tools "$missing_root"
    printf '%s\t%s\n' Fixture Linux > "$missing_root/coverage.tsv"
    FAKE_API_TOOL_LOG="$missing_root/tool.log" expect_failure \
        "Source metadata directory not found: $missing_root/sources" \
        "$ASSEMBLE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --name Fixture \
        --coverage "$missing_root/coverage.tsv" \
        --output-root "$missing_root"

    local malformed_root="$TEST_TEMP_DIR/assemble-malformed"
    mkdir -p "$malformed_root/sources" "$malformed_root/snapshots"
    make_fake_tools "$malformed_root"
    printf '%s\t%s\n' Fixture Linux > "$malformed_root/coverage.tsv"
    printf 'only\ttwo\n' > "$malformed_root/sources/malformed.tsv"
    FAKE_API_TOOL_LOG="$malformed_root/tool.log" expect_failure \
        "Source metadata must contain one 9-column TSV line: $malformed_root/sources/malformed.tsv" \
        "$ASSEMBLE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --name Fixture \
        --coverage "$malformed_root/coverage.tsv" \
        --output-root "$malformed_root"

    local invalid_coverage_root="$TEST_TEMP_DIR/assemble-invalid-coverage"
    mkdir -p "$invalid_coverage_root/sources" "$invalid_coverage_root/snapshots"
    make_fake_tools "$invalid_coverage_root"
    printf '{}\n' > "$invalid_coverage_root/snapshots/source.json"
    write_source_record \
        "$invalid_coverage_root" source source Linux snapshots/source.json
    printf '%s\t%s\n' Fixture macOS Fixture Linux > "$invalid_coverage_root/coverage.tsv"
    FAKE_API_TOOL_LOG="$invalid_coverage_root/tool.log" expect_failure \
        "Coverage metadata must be a sorted unique 2-column TSV: $invalid_coverage_root/coverage.tsv" \
        "$ASSEMBLE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --name Fixture \
        --coverage "$invalid_coverage_root/coverage.tsv" \
        --output-root "$invalid_coverage_root"
}

test_reference_orchestrator_generates_all_required_sources() {
    local root="$TEST_TEMP_DIR/reference-orchestrator"
    local output_root="$root/output"
    mkdir -p "$output_root"
    make_fake_tools "$root"
    make_fake_xcode_tools "$root"

    PATH="$FAKE_XCODE_BIN_DIR:$PATH" \
        FAKE_API_TOOL_LOG="$output_root/tool.log" \
        FAKE_XCRUN_LOG="$FAKE_XCRUN_LOG" \
        FAKE_XCODE_SDK_ROOT="$FAKE_XCODE_SDK_ROOT" \
        FAKE_EXTRACTOR="$FAKE_EXTRACTOR" \
        "$GENERATE_REFERENCE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --developer-dir "$FAKE_DEVELOPER_DIR" \
        --output-root "$output_root"

    [[ "$(find "$output_root/sources" -type f -name '*.tsv' | wc -l | tr -d '[:space:]')" == "10" ]] || {
        fail "reference orchestrator did not create ten source records"
    }
    [[ "$(find "$output_root/snapshots" -type f -name '*.json' | wc -l | tr -d '[:space:]')" == "10" ]] || {
        fail "reference orchestrator did not create ten snapshots"
    }
    [[ -f "$output_root/snapshot-set.json" ]] || fail "reference snapshot set is missing"

    local watch_record
    watch_record="$(cat "$output_root/sources/swiftuicore-watchos-xcode-26.6.tsv")"
    local expected_watch_record
    expected_watch_record="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
        swiftuicore-watchos-xcode-26.6 SwiftUICore watchOS \
        arm64_32-apple-watchos26.4 watchos 26.4 watchos-build \
        "Apple Swift version 6.2" snapshots/swiftuicore-watchos-xcode-26.6.json)"
    [[ "$watch_record" == "$expected_watch_record" ]] || fail "watchOS reference metadata is not exact"

    assert_file_contains "$FAKE_XCRUN_LOG" "--sdk macosx --show-sdk-build-version"
    assert_file_contains "$FAKE_XCRUN_LOG" "--sdk iphoneos --show-sdk-build-version"
    assert_file_contains "$FAKE_XCRUN_LOG" "--sdk appletvos --show-sdk-build-version"
    assert_file_contains "$FAKE_XCRUN_LOG" "--sdk watchos --show-sdk-build-version"
    assert_file_contains "$FAKE_XCRUN_LOG" "--sdk xros --show-sdk-build-version"
    assert_file_contains "$output_root/tool.log" \
        "write-snapshot-set${TEST_TAB}<--name>${TEST_TAB}<SwiftUI Xcode 26.6 (17F113)>"
}

test_reference_orchestrator_rejects_xcode_drift() {
    local root="$TEST_TEMP_DIR/reference-xcode-drift"
    local output_root="$root/output"
    mkdir -p "$output_root"
    make_fake_tools "$root"
    make_fake_xcode_tools "$root"

    PATH="$FAKE_XCODE_BIN_DIR:$PATH" \
        FAKE_XCODE_BUILD=17F000 \
        FAKE_API_TOOL_LOG="$output_root/tool.log" \
        FAKE_XCRUN_LOG="$FAKE_XCRUN_LOG" \
        FAKE_XCODE_SDK_ROOT="$FAKE_XCODE_SDK_ROOT" \
        FAKE_EXTRACTOR="$FAKE_EXTRACTOR" \
        expect_failure \
        "Expected Xcode 26.6 (17F113), found Xcode 26.6 (17F000)" \
        "$GENERATE_REFERENCE_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --developer-dir "$FAKE_DEVELOPER_DIR" \
        --output-root "$output_root"
    assert_file_not_exists "$output_root/tool.log"
}

test_tuikit_orchestrator_generates_host_sources() {
    local root="$TEST_TEMP_DIR/tuikit-orchestrator"
    make_fake_tools "$root"
    make_fake_swift_tools "$root"
    make_fake_xcode_tools "$root"

    local linux_output="$root/linux output"
    mkdir -p "$linux_output"
    PATH="$FAKE_SWIFT_BIN_DIR:$FAKE_XCODE_BIN_DIR:$PATH" \
        FAKE_HOST_SYSTEM=Linux \
        FAKE_SWIFT_BIN_PATH="$FAKE_SWIFT_BIN_PATH" \
        FAKE_SWIFT_LOG="$FAKE_SWIFT_LOG" \
        FAKE_API_TOOL_LOG="$linux_output/tool.log" \
        "$GENERATE_TUIKIT_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --platform Linux \
        --output-root "$linux_output" \
        --build-path "$root/linux build"

    [[ "$(find "$linux_output/sources" -type f -name '*.tsv' | wc -l | tr -d '[:space:]')" == "5" ]] || {
        fail "Linux orchestrator did not create five source records"
    }
    local linux_record
    linux_record="$(cat "$linux_output/sources/tuikitimage-linux-swift-6.0.3.tsv")"
    local expected_linux_record
    expected_linux_record="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
        tuikitimage-linux-swift-6.0.3 TUIkitImage Linux x86_64-unknown-linux-gnu \
        swift-linux 6.0.3 2c7f7276db4a1cd2a657bb225e2637609af00a1c920237396f81a55cb9fa0cd4 \
        "Swift version 6.0.3 (swift-6.0.3-RELEASE)" \
        snapshots/tuikitimage-linux-swift-6.0.3.json)"
    [[ "$linux_record" == "$expected_linux_record" ]] || fail "Linux TUIkit metadata is not exact"
    if grep -Fq '<--sdk>' "$linux_output/tool.log"; then
        fail "Linux extraction unexpectedly received an Apple SDK"
    fi

    local macos_output="$root/macos output"
    local clang_modules="$root/clang modules"
    mkdir -p "$macos_output" "$clang_modules"
    PATH="$FAKE_SWIFT_BIN_DIR:$FAKE_XCODE_BIN_DIR:$PATH" \
        FAKE_HOST_SYSTEM=Darwin \
        FAKE_SWIFT_COMPILER_VERSION="Apple Swift version 6.0.3 (swiftlang-6.0.3)" \
        FAKE_SWIFT_TARGET=arm64-apple-macosx15.0.0 \
        FAKE_SWIFT_BIN_PATH="$FAKE_SWIFT_BIN_PATH" \
        FAKE_SWIFT_LOG="$FAKE_SWIFT_LOG" \
        FAKE_API_TOOL_LOG="$macos_output/tool.log" \
        FAKE_XCRUN_LOG="$FAKE_XCRUN_LOG" \
        FAKE_XCODE_SDK_ROOT="$FAKE_XCODE_SDK_ROOT" \
        FAKE_EXTRACTOR="$FAKE_EXTRACTOR" \
        "$GENERATE_TUIKIT_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --platform macOS \
        --output-root "$macos_output" \
        --build-path "$root/macos build" \
        --clang-module-path "$clang_modules"

    [[ "$(find "$macos_output/sources" -type f -name '*.tsv' | wc -l | tr -d '[:space:]')" == "5" ]] || {
        fail "macOS orchestrator did not create five source records"
    }
    local macos_record
    macos_record="$(cat "$macos_output/sources/tuikit-macos-swift-6.0.3.tsv")"
    local expected_macos_record
    expected_macos_record="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
        tuikit-macos-swift-6.0.3 TUIkit macOS arm64-apple-macosx15.0.0 \
        macosx 26.4 macosx-build "Apple Swift version 6.0.3 (swiftlang-6.0.3)" \
        snapshots/tuikit-macos-swift-6.0.3.json)"
    [[ "$macos_record" == "$expected_macos_record" ]] || fail "macOS TUIkit metadata is not exact"
    assert_file_contains "$macos_output/tool.log" \
        "<--sdk>${TEST_TAB}<$FAKE_XCODE_SDK_ROOT/macosx>"
    assert_file_contains "$macos_output/tool.log" \
        "<--clang-module-path>${TEST_TAB}<$clang_modules>"
}

test_tuikit_orchestrator_rejects_toolchain_drift() {
    local root="$TEST_TEMP_DIR/tuikit-toolchain-drift"
    local output_root="$root/output"
    mkdir -p "$output_root"
    make_fake_tools "$root"
    make_fake_swift_tools "$root"

    PATH="$FAKE_SWIFT_BIN_DIR:$PATH" \
        FAKE_HOST_SYSTEM=Linux \
        FAKE_SWIFT_COMPILER_VERSION="Swift version 6.0.2 (swift-6.0.2-RELEASE)" \
        FAKE_SWIFT_BIN_PATH="$FAKE_SWIFT_BIN_PATH" \
        FAKE_SWIFT_LOG="$FAKE_SWIFT_LOG" \
        FAKE_API_TOOL_LOG="$output_root/tool.log" \
        expect_failure \
        "Expected Swift 6.0.3, found Swift version 6.0.2 (swift-6.0.2-RELEASE)" \
        "$GENERATE_TUIKIT_SCRIPT" \
        --tool "$FAKE_API_TOOL" \
        --platform Linux \
        --output-root "$output_root" \
        --build-path "$root/build"
    assert_file_not_exists "$output_root/tool.log"
}

test_api_tool_declares_macos_deployment_target() {
    grep -Fq '.macOS(.v14)' "$API_PACKAGE" || {
        fail "API compatibility package must declare the macOS 14 deployment target"
    }
}

test_generate_writes_isolated_source_artifacts
test_generate_rejects_unsafe_or_existing_targets
test_generate_validates_options_and_dependencies
test_generate_resolves_executable_names_from_path
test_generate_never_evaluates_metadata
test_assemble_sorts_sources_and_writes_descriptor
test_assemble_rejects_duplicate_ids_and_missing_snapshots
test_assemble_rejects_missing_or_malformed_inputs
test_reference_orchestrator_generates_all_required_sources
test_reference_orchestrator_rejects_xcode_drift
test_tuikit_orchestrator_generates_host_sources
test_tuikit_orchestrator_rejects_toolchain_drift
test_api_tool_declares_macos_deployment_target

echo "API snapshot script self-tests passed"
