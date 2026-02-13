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

#### Public API: Every control is a View with a real body

**The Rule:**
- Every **public** control MUST be a `View` with a real `body: some View`
- The `body` MUST return actual Views (not `Never`, not `fatalError()`)
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

#### Renderable: When and where it is allowed

Terminal UI requires procedural buffer assembly (ANSI codes, Unicode borders,
buffer overlays). `Renderable` is the mechanism for this. It is allowed in
these cases:

| Layer | Example | Renderable? |
|-------|---------|-------------|
| **Leaf nodes** | `Text`, `Spacer`, `Divider` | Yes (terminal primitives) |
| **Private `_*Core` views** | `_ButtonCore`, `_VStackCore` | Yes (procedural ANSI rendering) |
| **Layout primitives** | `_VStackCore`, `_HStackCore` | Yes + `Layoutable` (two-pass layout) |
| **Modifier infrastructure** | `ModifiedView`, `EnvironmentModifier` | Yes (context/buffer pipeline) |
| **Public controls** | `Button`, `VStack`, `List` | **No** (must use `body: some View`) |

**The `_*Core` pattern:**
```swift
// Public View: real body, environment flows through
public struct MyControl<Content: View>: View {
    let content: Content

    public var body: some View {
        _MyControlCore(content: content)
    }
}

// Private Core: Renderable for terminal-specific rendering
private struct _MyControlCore<Content: View>: View, Renderable {
    let content: Content
    var body: Never { fatalError("_MyControlCore renders via Renderable") }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Read environment from context, render with ANSI codes
    }
}
```

**Preferred: Pure composition (Box.swift is the reference):**
```swift
public struct MyControl<Content: View>: View {
    let content: Content

    public var body: some View {
        content
            .padding()
            .border()
    }
}
```

When possible, prefer composition over `_*Core`. Use `_*Core` + `Renderable`
only when the rendering requires procedural buffer manipulation that cannot
be expressed as View composition.

**WRONG Pattern (public control with Renderable):**
```swift
public struct MyControl: View {
    public var body: Never { fatalError() }  // WRONG!
}

extension MyControl: Renderable {  // WRONG - public types must not be Renderable!
    func renderToBuffer() { ... }
}
```

**Before implementing ANY control:**
1. Can it be composed from existing Views + modifiers? (preferred)
2. If not, does the public View have a real `body` wrapping a private `_*Core`?
3. Does `_*Core` read environment values from `RenderContext`?
4. Test: `.foregroundColor()` on the control affects its content?
5. Test: `.disabled()` on the control disables interactions?

### Interactive Views: Focus & State (non-negotiable)

All interactive views (Button, TextField, Toggle, Slider, etc.) that participate
in the focus system MUST follow these rules:

#### FocusID generation
- Default focusIDs MUST use `context.identity.path`, never user-facing data
- Pattern: `"\(prefix)-\(context.identity.path)"` (e.g. `"button-\(context.identity.path)"`)
- Never use label text, titles, or other user content for focusIDs (collision risk)

#### Focus registration
- Use the shared `FocusRegistration` helper for all focus setup
- Do NOT duplicate focus registration boilerplate in individual views
- Registration, disabled-state check, and isFocused query are one operation

#### StateStorage property indices
- Every `_*Core` view MUST document its property indices with named constants:
```swift
private enum StateIndex {
    static let focusID = 0
    static let handler = 1
}
```
- Never use bare integer literals for `propertyIndex`

#### Disabled state
- Disabled views MUST NOT register with the focus system
- Check `isDisabled` BEFORE calling `focusManager.register()`
- Disabled styling MUST be visually consistent across all interactive views

### SwiftUI API Design (non-negotiable)

#### Init signatures: Keep them minimal
- Public inits MUST match SwiftUI parameter names and order
- TUI-specific options (focusID, emptyPlaceholder, etc.) MUST be modifiers, not init params
- Minimize init overloads; prefer `@ViewBuilder` label variants over String convenience inits

**Correct:**
```swift
List(selection: $selection) { content }
    .focusID("my-list")
    .listEmptyPlaceholder("No items")
```

**Wrong:**
```swift
List(selection: $selection, focusID: "my-list", emptyPlaceholder: "No items") { content }
```

#### Modifier-first principle
TUI-specific behavior that SwiftUI handles via modifiers MUST also be modifiers:
- Focus identity: `.focusID(_:)`
- Placeholder text: `.listEmptyPlaceholder(_:)`
- Visual customization: `.trackStyle(_:)`, `.buttonStyle(_:)`, etc.

### File Organization

- Source files SHOULD stay under 500 lines
- If a file exceeds 500 lines, consider splitting: public API in one file, `_*Core` in another
- One view per file (do not combine VStack + HStack + ZStack in one file)