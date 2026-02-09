# View Architecture Refactor: 100% SwiftUI Conformity

## Preface

This plan refactors TUIKit's view architecture to achieve 100% SwiftUI conformity. Currently, many controls use `body: Never` with direct `Renderable` conformance, which breaks modifier propagation and environment value inheritance. After this refactor, every public control will be a proper View with `body: some View` that composes other Views. Modifiers like `.foregroundColor()` will propagate through the entire hierarchy automatically, exactly like SwiftUI.

## Context / Problem

### Current State (Broken)

Many TUIKit controls follow this anti-pattern:

```swift
public struct RadioButtonGroup: View {
    public var body: Never { fatalError() }
}

extension RadioButtonGroup: Renderable {
    func renderToBuffer(context:) -> FrameBuffer { ... }
}
```

**Problems:**
1. `.foregroundColor(.red)` on `RadioButtonGroup` does NOT affect its items
2. `.disabled(true)` requires custom implementation per control
3. Environment values don't propagate through the view tree
4. Each control reinvents modifier handling
5. Inconsistent with SwiftUI mental model

### Desired State (SwiftUI-Conformant)

Every control should follow the Box.swift pattern:

```swift
public struct RadioButtonGroup: View {
    public var body: some View {
        // Compose using other Views
        // Environment flows automatically
        ForEach(items) { item in
            RadioButtonRow(item: item, ...)
        }
    }
}
```

**Benefits:**
1. Modifiers propagate automatically
2. Environment values inherited correctly
3. Consistent with SwiftUI patterns
4. Less code per control
5. Predictable behavior for users

## Specification / Goal

### Success Criteria

1. **No public View with `body: Never`** (except true leaf nodes: Text, Spacer)
2. **Modifier propagation works**: `.foregroundColor()` on a List affects all Text inside
3. **Environment inheritance works**: Custom environment values flow through
4. **All 649+ tests pass**
5. **Example app works identically**

### What IS a Leaf Node (OK to use Renderable)

- `Text` - renders a string with styles
- `Spacer` - renders empty space
- `Divider` - renders a line
- Internal helpers like `BufferView`, `_ContainerViewCore`

### What is NOT a Leaf Node (must use body: some View)

- Container views: List, Table, Menu, RadioButtonGroup
- Interactive controls: Button, Toggle, Spinner
- Layout containers: Card, Panel, Dialog, Alert
- Composite views: ProgressView, ButtonRow

## Design

### SwiftUI's Approach

From SwiftUI documentation and practice:

1. **Views are descriptions, not pixels**: A View describes what to render, not how
2. **Composition over inheritance**: Views compose other Views
3. **Environment propagates down**: Parent modifiers affect children
4. **State is local**: Each View instance manages its own state
5. **Modifiers return new Views**: Each modifier wraps the content

### TUIKit's New Architecture

```
┌─────────────────────────────────────────────────────────┐
│ User Code                                               │
│   List("Items", selection: $sel) { ... }                │
│       .foregroundColor(.red)                            │
│       .disabled(isLoading)                              │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ List (View with body: some View)                        │
│   body = ContainerView(title:) {                        │
│       _ListContent(items:, selection:)                  │
│   }                                                     │
│   // foregroundColor propagates to ContainerView        │
│   // disabled propagates via environment                │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ ContainerView (View with body: some View)               │
│   body = _ContainerViewCore(...)                        │
│   // Passes environment to core                         │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ _ContainerViewCore (Renderable - internal only)         │
│   Reads environment values                              │
│   Renders border, content, etc.                         │
│   Passes context to children with environment           │
└─────────────────────────────────────────────────────────┘
```

### Key Insight: Where Renderable Lives

`Renderable` should only exist at the **leaves** of the view tree or in **internal implementation details**. The public API should never expose it.

```swift
// CORRECT: Public API is pure View
public struct List<...>: View {
    public var body: some View {
        ContainerView(title: title) {
            ForEach(items) { item in
                ListRow(item: item)  // ListRow is also a View
            }
        }
    }
}

// Internal: Can use Renderable for efficiency
private struct ListRow: View, Renderable {
    var body: Never { fatalError() }
    func renderToBuffer(context:) -> FrameBuffer {
        // Read environment from context
        let foreground = context.environment.foregroundColor ?? ...
    }
}
```

### Environment Value Propagation

Current problem: Environment values are in `RenderContext`, but Views with `body: Never` never propagate them.

Solution: Views with real `body` automatically propagate environment because `renderToBuffer` calls child's `renderToBuffer` with the same context.

```swift
// In TUIKit's render pipeline:
func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    } else {
        // View has a body - render it with same context
        return renderToBuffer(view.body, context: context)
    }
}
```

This already works! The problem is controls bypass it with `body: Never`.

### Focus/State Management Challenge

Controls like List, RadioButtonGroup need:
- StateStorage for persisting handler state
- FocusManager for keyboard navigation
- Selection bindings

These currently live in `renderToBuffer`. How to handle in pure View?

**Solution: Stateful Child Views**

```swift
public struct List<...>: View {
    public var body: some View {
        ContainerView(title: title) {
            _ListContent(
                content: content,
                selection: selection,
                ...
            )
        }
    }
}

// Internal view that handles state
private struct _ListContent<...>: View, Renderable {
    var body: Never { fatalError() }
    
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Access StateStorage, FocusManager here
        // Read environment values from context
        let foreground = context.environment.foregroundColor
        // Render rows with proper colors
    }
}
```

The key: `_ListContent` is **internal** and at the leaf level. The public `List` is a proper View that passes environment through.

## Implementation Plan

### Phase 1: Infrastructure (if needed)

1. Verify environment propagation works correctly through View.body
2. Add any missing environment values needed

### Phase 2: Simple Controls

Start with controls that don't need StateStorage/FocusManager:

1. **ProgressView** - just renders a progress bar
2. **Spinner** - just renders animation frames  
3. **ButtonRow** - just layouts buttons

Pattern:
```swift
public struct ProgressView: View {
    public var body: some View {
        _ProgressViewCore(...)
    }
}
```

### Phase 3: Container Views

Controls that wrap content but don't need focus:

1. **Card** - already uses ContainerView, just needs proper body
2. **Panel** - same as Card
3. **Dialog** - same as Card
4. **Alert** - same as Card

### Phase 4: Interactive Controls

Controls that need StateStorage/FocusManager:

1. **Button** - needs focus state
2. **Toggle** - needs focus + binding
3. **Menu** - needs focus + selection state
4. **RadioButtonGroup** - needs focus + selection

### Phase 5: Complex Controls

1. **List** - StateStorage, FocusManager, ItemListHandler
2. **Table** - Same as List

### Phase 6: Verification

1. Write tests for modifier propagation
2. Verify example app works
3. Check all 649+ tests pass

## Checklist

### Phase 1: Infrastructure
- [x] Verify environment propagation through body
- [x] Document the render pipeline

### Phase 2: Simple Controls
- [x] ProgressView: Convert to body: some View
- [x] Spinner: Convert to body: some View
- [x] ButtonRow: Convert to body: some View
- [x] Tests pass for each

### Phase 3: Container Views
- [x] Card: Convert to body: some View
- [x] Panel: Convert to body: some View
- [x] Dialog: Convert to body: some View
- [x] Alert: Convert to body: some View
- [x] Tests pass for each

### Phase 4: Interactive Controls
- [x] Button: Convert to body: some View
- [x] Toggle: Convert to body: some View
- [x] Menu: Convert to body: some View
- [x] RadioButtonGroup: Convert to body: some View
- [x] Tests pass for each

### Phase 5: Complex Controls
- [x] List: Convert to body: some View
- [x] Table: Convert to body: some View
- [x] Tests pass for each

### Phase 6: Verification
- [ ] Add modifier propagation tests
- [ ] Example app works correctly
- [ ] All tests pass
- [ ] SwiftLint clean

## Open Questions

1. **ForEach**: Currently has `body: Never`. Should it stay that way as an internal iteration helper, or become a proper View?

2. **Stacks (HStack, VStack, ZStack)**: These are layout primitives. Should they use body or stay Renderable?

3. **Performance**: Will adding more View layers impact render performance? (Probably not, but should verify)

## Files

### Controls to Refactor

Views/:
- Alert.swift
- Button.swift
- ButtonRow.swift
- Card.swift
- Dialog.swift
- List.swift
- Menu.swift
- Panel.swift
- ProgressView.swift
- RadioButton.swift
- Spinner.swift
- Table.swift
- Toggle.swift

### May Stay as Renderable (Leaf Nodes)

- Text.swift
- Spacer.swift
- Stacks.swift (HStack, VStack, ZStack)
- ForEach.swift

### Reference Implementations

- Box.swift (correct pattern)
- ContainerView.swift (internal Renderable pattern)

## Dependencies

- Existing View protocol
- Existing Renderable protocol
- ContainerView (for containers)
- StateStorage (for stateful controls)
- FocusManager (for interactive controls)

## Risk Assessment

**Low Risk:**
- Simple controls (ProgressView, Spinner) - straightforward conversion

**Medium Risk:**
- Container views - may need ContainerView adjustments

**High Risk:**
- List/Table - complex state management, may need architecture changes

## Success Metrics

After refactor:

```swift
// This MUST work:
List("Items", selection: $selection) {
    ForEach(items) { item in
        Text(item.name)
    }
}
.foregroundColor(.red)  // All Text inside is red
.disabled(isLoading)    // Entire list is disabled
.padding()              // Padding around entire list
```
