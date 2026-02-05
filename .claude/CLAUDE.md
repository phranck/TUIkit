## RULES

### Compatibility (non-negotiable)
- **Swift 6.0 compatible** — `swift-tools-version: 6.0`. Never use features that require a newer compiler.
- **Cross-platform** — must build and run without crashes/segfaults on both macOS and Linux. CI tests both (`macos-15` + `swift:6.0` container).
- When in doubt, verify with the CI pipeline before merging.

### Architecture
- No Singletons
- Consolidate existing functions before adding new ones

### Workflow
- **NEVER merge PRs autonomously** — stop after creating, let user merge

### SwiftUI API Parity (non-negotiable)
Public APIs MUST match SwiftUI signatures exactly unless terminal constraints require deviation (document why in comments).

| Aspect | Requirement |
|--------|-------------|
| Parameter names | Exact (`isPresented`, not `isVisible`) |
| Parameter order | Exact (title, binding, actions, message) |
| Parameter types | Match closely (ViewBuilder closures, not pre-built values) |
| Trailing closures | `@ViewBuilder () -> T`, not `String` |

**Before implementing:** Look up exact SwiftUI signature first.
**TUI-specific APIs:** OK to add, but keep separate from SwiftUI equivalents.