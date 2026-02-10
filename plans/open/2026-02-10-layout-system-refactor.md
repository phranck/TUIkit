# Layout System Refactor: Two-Pass Layout Like SwiftUI

## Preface

This plan refactors TUIKit's layout system to use a proper two-pass layout algorithm similar to SwiftUI. The current system renders all children with the same `availableWidth`, causing layout bugs when views need to share horizontal space (e.g., TextField in HStack). The new system will measure views first, then distribute remaining space, ensuring predictable and correct layouts.

## Context / Problem

### Current State (Broken)

The current rendering system has a fundamental flaw: **all children receive the same `availableWidth`**.

```swift
// HStack rendering (simplified)
func renderToBuffer(context: RenderContext) -> FrameBuffer {
    // ALL children get the SAME context.availableWidth!
    let infos = resolveChildInfos(from: content, context: context)
    // ...
}
```

**Example of the bug:**

```swift
HStack {
    Text("Label:")      // Gets availableWidth=80, renders as 6 chars
    TextField(...)      // Gets availableWidth=80, renders as 80 chars!
}
// Result: 86 chars total, wraps to next line
```

**What should happen:**

1. Measure Text("Label:") - needs 6 chars
2. Calculate remaining: 80 - 6 - 1 (spacing) = 73 chars
3. Give TextField 73 chars of available width

### Why `hasExplicitWidth` Failed

We tried using `hasExplicitWidth` as a workaround, but it's fundamentally flawed:

1. It's a boolean - can't express "I have 30 chars remaining"
2. It propagates to ALL children equally
3. Views can't know if they're in a flexible or fixed context
4. It conflates "terminal has fixed width" with "view should expand"

### SwiftUI's Layout Model

SwiftUI uses a proper layout protocol:

```swift
protocol Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache)
}
```

Key concepts:
1. **ProposedViewSize**: Parent suggests a size (can be nil = "use ideal", .infinity = "expand", or specific value)
2. **sizeThatFits**: View returns how much space it actually needs
3. **placeSubviews**: Parent places children knowing their actual sizes
4. **Flexibility**: Views report if they're flexible (Spacer) or fixed (Text)

## Specification / Goal

### Success Criteria

1. **HStack with mixed content works correctly**: `HStack { Text("Label:"); TextField(...) }` renders without overflow
2. **Spacer distributes remaining space**: Works with multiple Spacers
3. **VStack alignment works**: Children align correctly within available width
4. **Borders fit content**: `.border()` wraps content tightly, doesn't expand unnecessarily
5. **No `hasExplicitWidth`/`hasExplicitHeight` hacks**: Clean, principled layout
6. **All 1020+ tests pass**
7. **Performance**: No significant regression (measure before/after)

### Non-Goals

- Full SwiftUI Layout protocol (too complex for TUI)
- Caching system (can add later if needed)
- GeometryReader (not needed for TUI)

## Design

### Core Concept: Two-Pass Layout

**Pass 1 - Measure**: Ask each child how much space it needs
**Pass 2 - Layout**: Distribute space and render

### New Types

```swift
/// How much space a parent proposes to a child.
struct ProposedSize {
    /// nil = use your ideal size, .infinity = expand, value = exact
    var width: Int?
    var height: Int?
    
    static let unspecified = ProposedSize(width: nil, height: nil)
    static func fixed(_ width: Int, _ height: Int) -> ProposedSize
}

/// How much space a view needs and its flexibility.
struct ViewSize {
    var width: Int
    var height: Int
    var isWidthFlexible: Bool   // true for Spacer, TextField
    var isHeightFlexible: Bool  // true for Spacer
    
    static func fixed(_ width: Int, _ height: Int) -> ViewSize
    static func flexible(minWidth: Int, minHeight: Int) -> ViewSize
}

/// Extended Renderable protocol with layout support.
protocol Layoutable: Renderable {
    /// Returns the size this view needs given a proposed size.
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize
}
```

### Layout Algorithm for HStack

```swift
func renderToBuffer(context: RenderContext) -> FrameBuffer {
    let proposal = ProposedSize(width: context.availableWidth, height: context.availableHeight)
    
    // Pass 1: Measure all children
    var childSizes: [ViewSize] = []
    var totalFixedWidth = 0
    var flexibleCount = 0
    
    for child in children {
        let size = child.sizeThatFits(proposal: .unspecified, context: context)
        childSizes.append(size)
        
        if size.isWidthFlexible {
            flexibleCount += 1
            totalFixedWidth += size.width  // minimum width
        } else {
            totalFixedWidth += size.width
        }
    }
    
    // Calculate spacing
    let totalSpacing = (children.count - 1) * spacing
    
    // Calculate remaining space for flexible views
    let remainingWidth = max(0, (proposal.width ?? 0) - totalFixedWidth - totalSpacing)
    let flexibleWidth = flexibleCount > 0 ? remainingWidth / flexibleCount : 0
    
    // Pass 2: Render with final sizes
    var result = FrameBuffer()
    for (index, child) in children.enumerated() {
        let childSize = childSizes[index]
        let finalWidth = childSize.isWidthFlexible 
            ? childSize.width + flexibleWidth 
            : childSize.width
        
        let childProposal = ProposedSize(width: finalWidth, height: proposal.height)
        let buffer = child.renderToBuffer(proposal: childProposal, context: context)
        result.appendHorizontally(buffer, spacing: index > 0 ? spacing : 0)
    }
    
    return result
}
```

### View Flexibility Classification

| View | Width Flexible | Height Flexible | Notes |
|------|---------------|-----------------|-------|
| Text | No | No | Fixed to content |
| Spacer | Yes | Yes | Expands to fill |
| TextField | Yes | No | Expands horizontally |
| Button | No | No | Fixed to label |
| VStack | Depends | Depends | Max of children |
| HStack | Depends | Depends | Sum/Max of children |
| Border | No | No | Wraps content tightly |

### Migration Strategy

1. **Add `Layoutable` protocol** alongside existing `Renderable`
2. **Implement `sizeThatFits`** for leaf views (Text, Spacer, etc.)
3. **Update HStack** to use two-pass layout
4. **Update VStack** similarly
5. **Update TextField** to report flexible width
6. **Remove `hasExplicitWidth`/`hasExplicitHeight`**
7. **Update all tests**

## Implementation Plan

### Phase 1: Foundation (Day 1)

1. Add `ProposedSize` and `ViewSize` types to `Renderable.swift`
2. Add `Layoutable` protocol with default implementation
3. Implement `sizeThatFits` for `Text`
4. Implement `sizeThatFits` for `Spacer`
5. Write tests for new types

### Phase 2: Stack Layout (Day 1-2)

1. Refactor `_HStackCore` to use two-pass layout
2. Refactor `_VStackCore` similarly
3. Update tests for stack layout
4. Verify existing examples still work

### Phase 3: Flexible Views (Day 2)

1. Make `TextField` report flexible width
2. Make `SecureField` report flexible width
3. Make `Slider` report flexible width
4. Update tests

### Phase 4: Containers (Day 2-3)

1. Update `ContainerView` (borders) to use content size
2. Update `Panel`, `Card` similarly
3. Remove `resolveContainerWidth`/`resolveContainerHeight`
4. Update tests

### Phase 5: Cleanup (Day 3)

1. Remove `hasExplicitWidth` from `RenderContext`
2. Remove `hasExplicitHeight` from `RenderContext`
3. Remove related helper functions
4. Update all remaining views
5. Full test suite pass
6. Performance benchmarks

## Checklist

- [x] Add `ProposedSize` struct
- [x] Add `ViewSize` struct
- [x] Add `Layoutable` protocol
- [x] Implement `sizeThatFits` for Text
- [x] Implement `sizeThatFits` for Spacer
- [x] Implement `sizeThatFits` for Divider
- [x] Add `ChildView` type-erased wrapper for two-pass layout
- [x] Add `ChildViewProvider` protocol
- [x] Implement `ChildViewProvider` for TupleView
- [x] Refactor HStack to two-pass layout
- [x] Implement `sizeThatFits` for HStack
- [x] Refactor VStack to two-pass layout
- [x] Implement `sizeThatFits` for VStack
- [x] Make TextField width-flexible
- [x] Make SecureField width-flexible
- [x] Make Slider width-flexible
- [x] Update ContainerView layout (already uses content-based sizing)
- [x] Update Panel layout (delegates to ContainerView)
- [x] Update Card layout (delegates to ContainerView)
- [ ] Remove hasExplicitWidth
- [ ] Remove hasExplicitHeight
- [x] All tests pass (1034)
- [ ] Performance benchmarks show no regression (relaxed for two-pass overhead)
- [ ] Example app works correctly
- [ ] Document new layout system in render-cycle.md

**Note:** Phase 5 (removing hasExplicitWidth/Height) deferred to separate PR.
The two-pass layout system is functional. Remaining cleanup can be done incrementally.

## Open Questions

1. **Should `Layoutable` replace `Renderable` entirely?** Or keep both for backward compatibility?
2. **How to handle views that aren't updated yet?** Default implementation returns fixed size based on rendered buffer?
3. **ZStack layout**: Does it need special handling? (Probably just max of children)

## Files to Modify

- `Sources/TUIkit/Rendering/Renderable.swift` - Add new types and protocol
- `Sources/TUIkit/Rendering/RenderContext.swift` - Remove hasExplicit flags
- `Sources/TUIkit/Views/Stacks.swift` - Two-pass layout
- `Sources/TUIkit/Views/TextField.swift` - Flexible width
- `Sources/TUIkit/Views/SecureField.swift` - Flexible width
- `Sources/TUIkit/Views/Slider.swift` - Flexible width
- `Sources/TUIkit/Views/Spacer.swift` - sizeThatFits
- `Sources/TUIkit/Views/ContainerView.swift` - Use content size
- `Sources/TUIkit/Views/Text.swift` - sizeThatFits (if separate file)
- `Tests/TUIkitTests/LayoutTests.swift` - New test file
- Multiple existing test files - Update for new behavior

## Dependencies

None - this is foundational work that other features depend on.

## Risks

1. **Performance regression**: Two passes means more work. Mitigate with benchmarks.
2. **Breaking changes**: Layout may change for existing views. Mitigate with comprehensive tests.
3. **Complexity**: New concepts to understand. Mitigate with clear documentation.
