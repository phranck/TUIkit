## RULES

### Compatibility (non-negotiable)
- **Swift 6.0 compatible**: `swift-tools-version: 6.0`. Never use features that require a newer compiler.
- **Cross-platform**: must build and run without crashes/segfaults on both macOS and Linux. CI tests both (`macos-15` + `swift:6.0` container).
- When in doubt, verify with the CI pipeline before merging.

### Architecture (non-negotiable)

#### General Principles
- No Singletons
- **Before implementing ANYTHING NEW: Search the codebase** for similar patterns, reusable code, existing solutions
- Consolidate and reuse before adding new functions or types
- "Reinventing the wheel" is a code smell: investigate why it exists first

#### Code Reuse Checklist
1. Does a similar feature exist? Use it or extend it
2. Can I reuse a helper function/extension/modifier? Do it
3. Does a pattern already exist? Follow it exactly
4. Am I duplicating logic? Refactor into a shared utility
5. **Never implement features in isolation**: maximize consistency and minimize maintenance burden

### Workflow
- **NEVER merge PRs autonomously**: stop after creating, let user merge

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

### View Architecture (non-negotiable)
**EVERYTHING that is visible to users must be a `View` (conform to `View` protocol).**

This is CRITICAL for:
- **View-Modifiers**: `.foregroundColor()`, `.padding()`, `.disabled()`, etc. only work on Views
- **Environment-Value propagation**: Foreground colors, fonts, etc. inherit automatically through View hierarchy
- **Consistency**: All public APIs look the same, follow SwiftUI patterns
- **Performance**: Single rendering path, no special cases

**Structure:**
- Public API: `struct MyControl: View { var body: some View { ... } }`
- Internal complex logic: Private/internal Views like `_MyControlCore: View` or `Renderable` structs inside `body`
- NEVER expose `Renderable` to users; it's an implementation detail

**Before implementing ANY new control:**
1. Check if similar controls already exist in the codebase
2. Reuse patterns, extensions, helpers from existing Views
3. Make it a `View` first: internal rendering complexity goes in `body` or child Views
4. Verify modifiers work: `.foregroundColor()`, `.disabled()`, environment values propagate correctly

**Example (CORRECT):**
```swift
public struct MyControl: View {
    let label: String
    
    public var body: some View {
        _MyControlCore(label: label)
    }
}

private struct _MyControlCore: View {
    let label: String
    @Environment(\.foregroundColor) var foregroundColor
    
    var body: some View {
        Text(label)
            .foregroundColor(foregroundColor ?? .default)
    }
}
```

**Example (WRONG):**
```swift
public struct MyControl: View {
    public var body: Never { fatalError() }
}

extension MyControl: Renderable {
    func renderToBuffer() { ... }  // Exposes implementation, breaks modifiers
}
```

**Pattern to follow: `Box.swift`**
`Box` is the reference implementation:
- Public API: Real `View` with `body: some View`
- Body: Applies modifiers to content (`.border()`, `.padding()`, etc.)
- No `Renderable` in public API: modifiers do the rendering work
- Users can chain modifiers naturally: `Box { ... }.foregroundColor(...)`

This is the CORRECT pattern for ALL controls.