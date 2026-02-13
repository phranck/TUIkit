# Contributing to TUIkit

TUIkit is a SwiftUI-like framework for building Terminal User Interfaces in pure Swift, with no ncurses or C dependencies. It targets SwiftUI API parity wherever possible.

## Hard Requirements (non-negotiable)

| Requirement | Details |
|-------------|---------|
| **Swift 6.0** | `swift-tools-version: 6.0`. Never use features from a newer compiler. |
| **Cross-platform** | Must build and run on both macOS and Linux. CI tests both (`macos-15` + `swift:6.0` container). |
| **CI must pass** | All tests and linting must pass before merge. |

## Build, Test & Lint

```bash
# Build
swift build

# Run all tests (1037+ tests, Swift Testing framework)
swift test

# Run a single test suite
swift test --filter <TestSuiteName>

# Lint
swiftlint

# Format (configured but not enforced in CI)
swift-format format -i -r Sources Tests
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

## Code Style

- Line length: 140 characters (warning), 200 (error)
- 4-space indentation
- Trailing commas in multi-line collections
- See `.swiftlint.yml` and `.swift-format` for full configuration

## Testing

- Uses Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Tests run in parallel
- Test files mirror source structure in `Tests/TUIkitTests/`

## Detailed Architecture Rules

For comprehensive architecture documentation including the `_*Core` pattern, focus system, state management, and interactive view rules, see [`.claude/CLAUDE.md`](.claude/CLAUDE.md).
