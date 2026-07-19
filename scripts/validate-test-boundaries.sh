#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
PACKAGE_MANIFEST="$PROJECT_DIR/Package.swift"

fail() {
    echo "Test boundary error: $1" >&2
    exit 1
}

if [[ ! -f "$PACKAGE_MANIFEST" ]]; then
    fail "Package.swift not found"
fi

validate_test_target() {
    local target_name="$1"
    local dependencies="$2"
    local allowed_imports="$3"
    local expected_manifest_line=".testTarget(name: \"$target_name\", dependencies: [$dependencies]),"
    local declaration_count
    declaration_count="$(awk -v expected="$expected_manifest_line" '
        {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            sub(/[[:space:]]+$/, "", line)
            if (line == expected) {
                count += 1
            }
        }
        END { print count + 0 }
    ' "$PACKAGE_MANIFEST")"
    if [[ "$declaration_count" != "1" ]]; then
        fail "Package.swift must declare the isolated $target_name dependency set exactly once"
    fi

    local target_dir="$PROJECT_DIR/Tests/$target_name"
    if [[ ! -d "$target_dir" ]]; then
        fail "missing test target directory: Tests/$target_name"
    fi
    if ! find "$target_dir" -type f -name '*.swift' -print -quit | grep -q .; then
        fail "test target contains no Swift tests: Tests/$target_name"
    fi

    local invalid_import
    invalid_import="$({
        find "$target_dir" -type f -name '*.swift' -exec \
            awk -v allowed="$allowed_imports" -v root_length="${#PROJECT_DIR}" '
                {
                    line = $0
                    sub(/^[[:space:]]+/, "", line)
                    while (line ~ /^@[^[:space:]]+[[:space:]]+/) {
                        sub(/^@[^[:space:]]+[[:space:]]+/, "", line)
                    }
                    if (line ~ /^(private|fileprivate|internal|package|public)[[:space:]]+import[[:space:]]+/) {
                        sub(/^(private|fileprivate|internal|package|public)[[:space:]]+/, "", line)
                    }
                    if (line !~ /^import[[:space:]]+/) {
                        next
                    }

                    split(line, fields, /[[:space:]]+/)
                    module_index = 2
                    if (fields[2] ~ /^(class|enum|func|let|protocol|struct|typealias|var)$/) {
                        module_index = 3
                    }
                    module = fields[module_index]
                    sub(/[.].*$/, "", module)
                    if (module !~ /^TUIkit(Core|Styling|View|Image)?$/) {
                        next
                    }
                    if (index(" " allowed " ", " " module " ") == 0) {
                        relative = substr(FILENAME, root_length + 2)
                        print relative ":" module
                    }
                }
            ' {} +
    } | LC_ALL=C sort | head -n 1)"
    if [[ -n "$invalid_import" ]]; then
        fail "${invalid_import/:/ imports forbidden project module }"
    fi
}

validate_test_target "TUIkitCoreTests" '"TUIkitCore"' "TUIkitCore"
validate_test_target "TUIkitStylingTests" '"TUIkitStyling"' "TUIkitStyling"
validate_test_target "TUIkitViewTests" '"TUIkitCore", "TUIkitView"' "TUIkitCore TUIkitView"
validate_test_target "TUIkitImageTests" '"TUIkitImage"' "TUIkitImage"

if grep -Eq '\.(systemLibrary|binaryTarget|linkedLibrary|linkedFramework)[[:space:]]*\(' \
    "$PACKAGE_MANIFEST"; then
    fail "Package.swift declares a native or binary dependency"
fi

for source_root in Sources Vendor; do
    if [[ ! -d "$PROJECT_DIR/$source_root" ]]; then
        continue
    fi

    native_source="$({
        find "$PROJECT_DIR/$source_root" -type f \
            \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.cxx' \
            -o -name '*.h' -o -name '*.hpp' -o -name '*.m' -o -name '*.mm' \) \
            -print
    } | LC_ALL=C sort | head -n 1)"
    if [[ -n "$native_source" ]]; then
        fail "native source is forbidden: ${native_source#"$PROJECT_DIR/"}"
    fi
done

echo "Test target boundaries passed"
