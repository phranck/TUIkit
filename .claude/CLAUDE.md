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

#### 100% SwiftUI Conformity - EVERYTHING is a View!

This is the **MOST IMPORTANT RULE**. No exceptions. No shortcuts.

**The Rule:**
- Every public control MUST be a `View` with a real `body: some View`
- The `body` MUST return actual Views (not `Never`, not `fatalError()`)
- `Renderable` is ONLY for leaf nodes (Text, Spacer) - NEVER for controls
- All modifiers MUST propagate through the entire View hierarchy
- Environment values MUST flow down automatically

**Why this matters:**
```swift
// This MUST work exactly like SwiftUI:
List("Items", selection: $selection) {
    ForEach(items) { item in
        Text(item.name)
    }
}
.foregroundColor(.red)  // MUST affect all Text inside!
.disabled(true)         // MUST disable the entire List!
```

**Correct Pattern (Box.swift is the reference):**
```swift
public struct MyControl<Content: View>: View {
    let content: Content
    
    public var body: some View {
        // Compose using other Views and modifiers
        // Environment flows through automatically
        content
            .padding()
            .border()
    }
}
```

**WRONG Pattern (breaks modifier propagation):**
```swift
public struct MyControl: View {
    public var body: Never { fatalError() }  // WRONG!
}

extension MyControl: Renderable {  // WRONG!
    func renderToBuffer() { ... }
}
```

**Also WRONG (hidden Renderable breaks the chain):**
```swift
public struct MyControl: View {
    public var body: some View {
        _MyControlCore(...)  // If this is Renderable, modifiers break!
    }
}

private struct _MyControlCore: View, Renderable {  // WRONG!
    var body: Never { fatalError() }
    func renderToBuffer() { ... }
}
```

**Before implementing ANY control:**
1. Can it be composed from existing Views + modifiers? (preferred)
2. Does `body` return real Views that propagate environment?
3. Test: `.foregroundColor()` on the control affects its content?
4. Test: `.disabled()` on the control disables interactions?

**Controls that need refactoring to follow this rule:**
- List, Table (currently use internal Renderable)
- Any control with `body: Never`