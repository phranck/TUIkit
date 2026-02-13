# TUIkit Agent Instructions

TUIkit is a SwiftUI-like framework for building Terminal User Interfaces in pure Swift (no ncurses, no C dependencies).

## Hard Constraints

- **Swift 6.0 only** (`swift-tools-version: 6.0`). Never use features from a newer compiler.
- **Cross-platform**: Must build on macOS and Linux. CI tests both.
- **CI must pass** before merge.

## Build & Test

```bash
swift build          # Build
swift test           # Run all tests (1037+, Swift Testing framework)
swiftlint            # Lint
```

## Key Rules

- Public APIs must match SwiftUI signatures exactly (parameter names, order, types)
- Every public control must be a `View` with a real `body: some View` (no `body: Never`)
- `Renderable` is only for leaf nodes and private `_*Core` views
- No singletons; all state flows through the Environment system
- Search the codebase for existing patterns before adding new code

## Detailed Documentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for full architecture rules, code style, and PR requirements.
See [.claude/CLAUDE.md](.claude/CLAUDE.md) for comprehensive architecture documentation.
