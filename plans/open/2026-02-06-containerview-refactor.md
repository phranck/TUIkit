# ContainerView Refactoring Plan

## Preface

ContainerView is being refactored from the broken `body: Never` + Renderable pattern to a proper View with `body: some View` that returns an internal `_ContainerViewCore`. This fix enables modifiers to work naturally and becomes the template for fixing List, Box, and other components. Once done, `.foregroundColor()`, `.padding()`, and other standard modifiers will compose correctly instead of being silently ignored.

## Context / Problem

ContainerView currently uses the wrong pattern with `body: Never` + Renderable, preventing view modifiers from working correctly.

## Specification / Goal

Refactor ContainerView to proper View architecture with `body: some View` returning an internal `_ContainerViewCore`, enabling modifiers and proper view composition.

## Design

### Current (WRONG) Pattern
```swift
public struct ContainerView: View {
    var body: Never { fatalError() }
}

extension ContainerView: Renderable {
    func renderToBuffer() { ... }  // 400+ lines of rendering logic
}
```

**Problems:**
- No modifiers work (`.foregroundColor()`, `.padding()`, etc.)
- Can't chain modifiers naturally
- Implementation detail exposed to public API
- Inconsistent with SwiftUI/Box pattern

### New (CORRECT) Pattern

```swift
public struct ContainerView<Content: View, Footer: View>: View {
    let title: String?
    let content: Content
    let footer: Footer?
    let config: ContainerConfig
    
    public var body: some View {
        _ContainerViewCore(
            title: title,
            content: content,
            footer: footer,
            config: config
        )
    }
}

private struct _ContainerViewCore<Content: View, Footer: View>: View, Renderable {
    // All the complex rendering logic goes here
    
    var body: some View {
        // Or: extension _ContainerViewCore: Renderable { func renderToBuffer() }
    }
    
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Current 400+ lines of logic
    }
}
```

## Impact Analysis

### What Uses ContainerView?
```bash
grep -r "ContainerView" Sources/TUIkit/Views/ --include="*.swift" | grep -v "ContainerView.swift"
```

Likely users:
- Card (via renderContainer helper)
- Panel (via renderContainer helper)
- Alert (via renderContainer helper)
- Dialog (via renderContainer helper)

These are already using `renderContainer()` helper, so they won't be directly affected.

### Breaking Changes?
- ContainerView is internal-ish (used via `renderContainer()` helper)
- Direct users are unlikely, but need to check
- The helper function `renderContainer()` doesn't need to change

## Implementation Plan

1. **Create _ContainerViewCore** — private struct with Renderable
2. **Move all rendering logic** from ContainerView to _ContainerViewCore
3. **Make ContainerView a simple View** with body that creates _ContainerViewCore
4. **Verify modifiers work** — test `.foregroundColor()`, `.padding()`, etc.
5. **Check all users** — Card, Panel, Alert, Dialog still work
6. **Update tests** if needed

## Checklist

- [ ] Create _ContainerViewCore private struct
- [ ] Move rendering logic to _ContainerViewCore
- [ ] Update ContainerView with body: some View
- [ ] Verify modifiers work (.foregroundColor, .padding, etc.)
- [ ] Check Card, Panel, Alert, Dialog render correctly
- [ ] Update tests
- [ ] Build & lint verification

## Benefits After Refactoring

✅ Modifiers work naturally
✅ Environment values propagate correctly
✅ Consistent with SwiftUI patterns
✅ Cleaner public API
✅ Implementation detail hidden
✅ Pattern reusable for List, Table, etc.

## Timeline Note

This is NOT urgent but IMPORTANT for long-term consistency. Should be done BEFORE List & Table implementation, so they follow the correct pattern from the start.
