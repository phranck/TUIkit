# Contributing to TUIkit

TUIkit is a SwiftUI-like framework for building Terminal User Interfaces in pure Swift, with no ncurses or C dependencies. It targets SwiftUI API parity wherever possible.

## Hard Requirements (non-negotiable)

| Requirement | Details |
|-------------|---------|
| **Swift 6.0.3** | Development and CI use exactly Swift 6.0.3; `swift-tools-version` remains 6.0. Never use features from a newer compiler. |
| **Cross-platform** | Must build and run on both macOS and Linux. The Linux image and digest are pinned in `scripts/toolchain.env`. |
| **CI must pass** | All tests and linting must pass before merge. |

## Local Quality Gate

```bash
# Run lint, build, tests, test discovery, DocC, and CI configuration checks on macOS and Linux
./scripts/test-linux.sh

# Run one platform only
./scripts/test-linux.sh macos
./scripts/test-linux.sh linux
```

The gate installs the pinned SwiftLint release into `.build/tooling`, verifies its SHA-256 checksum, and rejects any Swift or SwiftLint version drift. Compiler and DocC warnings are errors, and SwiftLint runs with `--strict --no-cache`.

Focused commands remain useful while developing, but they do not replace the complete gate:

```bash
swift build -Xswiftc -warnings-as-errors
swift test -Xswiftc -warnings-as-errors

# Run a single test suite
swift test --filter <TestSuiteName>

# Run the pinned linter through the gate installer
SWIFTLINT_BIN=$(./scripts/install-swiftlint.sh macos)
"$SWIFTLINT_BIN" lint --strict --no-cache

# Format (configured but not enforced in CI)
swift-format format -i -r Sources Tests

# Generate the deployable DocC archive
./scripts/generate-documentation.sh
```

## Pull Request Requirements

1. Branch from `main`
2. Fill in the PR template completely
3. CI must be green (macOS + Linux)
4. No new SwiftLint warnings
5. Follow the architecture and API rules below

## Architecture

### SwiftUI API Parity

Public APIs **must** match SwiftUI signatures exactly unless terminal constraints require deviation (document why in comments).

| Aspect | Requirement |
|--------|-------------|
| Parameter names | Exact (`isPresented`, not `isVisible`) |
| Parameter order | Exact (title, binding, actions, message) |
| Parameter types | Match closely (ViewBuilder closures, not pre-built values) |
| Trailing closures | `@ViewBuilder () -> T`, not `String` |

**Before implementing any SwiftUI-equivalent API:** Look up the exact SwiftUI signature first.

### View Architecture

- Every **public** control must be a `View` with a real `body: some View`
- The `body` must return actual Views (not `Never`, not `fatalError()`)
- `Renderable` is only for leaf nodes (`Text`, `Spacer`, `Divider`) and private `_*Core` views
- All modifiers must propagate through the entire View hierarchy
- Environment values must flow down automatically

### General Principles

- No singletons
- Search the codebase for similar patterns before implementing anything new
- Consolidate and reuse before adding new functions or types

### Image Decoding

- `TUIkitImage` supports static PNG and JPEG input with non-premultiplied 8-bit RGBA output.
- Vendored decoder sources must remain pure Swift, namespaced, provenance-documented, and compatible with Swift 6.0 on macOS and Linux.
- Input, dimensions, pixels, frames, decompressed samples, and final allocation are bounded before decoding.
- Format decoding stays separate from file and network lifecycle code so it remains deterministic and fuzzable.

## Code Style

- Line length: 140 characters (warning), 200 (error)
- 4-space indentation
- Trailing commas in multi-line collections
- See `.swiftlint.yml` and `.swift-format` for full configuration

## Testing

- Uses Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Independent tests run in parallel; suites that isolate shared state run serially
- Test files mirror source structure in `Tests/TUIkitTests/`

## Detailed Architecture Rules

For comprehensive architecture documentation including the `_*Core` pattern, focus system, state management, and interactive view rules, see [`.claude/CLAUDE.md`](.claude/CLAUDE.md).
