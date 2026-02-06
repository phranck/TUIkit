# Containerization: Composition NOT Inheritance in Swift

## Preface

Composition replaces inheritance throughout the framework: Alert, Dialog, Panel, and Card all use the `renderContainer()` helper rather than inheriting from ContainerView. List and Table will follow the same pattern with `renderListWithFocus()` and `renderTableWithFocus()` helpers plus shared `FocusableItemListHandler`. This ensures consistency, maximizes code reuse, and keeps view definitions simple (plain structs) while rendering logic lives in testable helper functions. Utrue to SwiftUI/TUIKit's design philosophy.

## Context / Problem

Current container-like components might use inheritance or ad-hoc patterns. We need a unified, composition-based approach that works consistently across Alert, Dialog, Panel, and Card.

## Specification / Goal

Establish a composition-based architecture for all container components using shared rendering helpers, ensuring consistency and reducing code duplication.

## Design

### Current Pattern in TUIKit: ContainerView

ContainerView is NOT inherited. Instead:

### 1. Alert, Dialog, Panel, Card DON'T extend ContainerView
Instead, they use **Composition via renderContainer() helper**:

```swift
extension Card: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        return renderContainer(
            title: title,
            config: config,
            content: content,
            footer: footer,
            context: context
        )
    }
}
```

The `renderContainer()` function internally creates and renders a `ContainerView`.

### 2. Swift Pattern: Composition > Inheritance
- Card, Panel, Dialog, Alert don't inherit from ContainerView
- They SHARE the ContainerView rendering logic via the helper function
- Each maintains its own struct definition (properties, init, etc.)
- ContainerView is an implementation detail

## Can List & Table Use This?

**YES! And they should!**

### Option 1: Use renderContainer() (Current Pattern)
```swift
struct List<S, C>: View {
    var body: some View {
        _ListCore(...)
    }
}

private struct _ListCore<S, C>: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Render list items first
        let itemsBuffer = renderListItems(...)
        
        // Wrap in container
        return renderContainer(
            title: title,
            config: config,
            content: itemsBuffer,  // This won't work directly!
            footer: nil,
            context: context
        )
    }
}
```

**Problem**: `renderContainer()` expects a `View`, not a pre-rendered `FrameBuffer`.

### Option 2: Create a ListContainer Helper (Like renderContainer)
```swift
internal func renderListWithFocus<SelectionValue, Content: View>(
    title: String?,
    selection: Binding<SelectionValue>?,
    focusID: String,
    config: ContainerConfig,
    content: Content,
    context: RenderContext
) -> FrameBuffer {
    // 1. Render content and extract rows
    let contentBuffer = TUIkit.renderToBuffer(content, context: context)
    let rows = contentBuffer.lines
    
    // 2. Manage focus/selection/scrolling
    let handler = getOrCreateListHandler(...)
    let visibleRows = computeVisibleRows(rows, handler)
    
    // 3. Style rows based on focus/selection
    let styledRows = visibleRows.map { renderRowWithState($0, ...) }
    
    // 4. Wrap in container (title + border + padding)
    let containerContent = ListBodyView(lines: styledRows)
    
    return renderContainer(
        title: title,
        config: config,
        content: containerContent,
        footer: nil,
        context: context
    )
}
```

### Option 3: Create Reusable FocusableContainer Base Helper
```swift
internal func renderFocusableContainer<SelectionValue, Content: View>(
    title: String?,
    handler: FocusableItemListHandler,
    config: ContainerConfig,
    content: Content,
    renderItemWithState: (String, Bool, Bool) -> String,
    context: RenderContext
) -> FrameBuffer {
    // 1. Extract rows from content
    // 2. Apply focus/selection logic
    // 3. Render styled rows
    // 4. Wrap in container
}
```

This would be shared between List and Table!

## Implementation Plan

1. **Document composition pattern**. Uestablish guidelines
2. **Review current container components**. Uverify consistency
3. **Create/refactor renderListWithFocus() helper** for List and Table
4. **Extract shared state management** into `FocusableItemListHandler`
5. **Verify all components use composition** via renderContainer()

## Checklist

- [ ] Document composition pattern guidelines
- [ ] Review Alert, Dialog, Panel, Card for consistency
- [ ] Create renderListWithFocus() helper function
- [ ] Extract FocusableItemListHandler for shared logic
- [ ] Verify renderContainer() usage across components
- [ ] Write tests for helpers
- [ ] Update documentation

## Recommendation

**DO NOT inherit from ContainerView.** Instead:

1. **Create `renderListWithFocus()` helper**. Usimilar to `renderContainer()`
2. **Extract common focus logic** into `FocusableItemListHandler`
3. **Extract common container logic** into configuration structs
4. **Both List and Table use the helper**. Umaximum code reuse

This follows SwiftUI/TUIKit patterns:
- Composition over inheritance
- Helper functions for shared logic
- Each component maintains its own struct definition
- Clear, testable separation of concerns

## Architecture Path

```
List → _ListCore (View/Renderable)
                ↓
        renderListWithFocus() [helper]
                ↓
        FocusableItemListHandler [state]
        ListBodyContent (View, renders items)
        ContainerView [via renderContainer()]

Table → _TableCore (View/Renderable)
                ↓
        renderListWithFocus() or renderTableWithFocus() [shared or separate]
                ↓
        FocusableItemListHandler [shared] or TableFocusHandler
        TableBodyContent (View, renders grid)
        ContainerView [via renderContainer()]
```

The KEY: Handlers and helper functions are SHARED, structs are COMPOSED.
