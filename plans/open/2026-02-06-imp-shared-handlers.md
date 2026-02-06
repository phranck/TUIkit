# Implementation Plan: Shared Focus/Selection Handlers & Helpers

## Preface

Shared focus/selection infrastructure is extracted so both List and Table reuse the same pieces: `FocusableItemListHandler` for keyboard navigation (Up/Down/Home/End), `SelectionStateManager<T>` for tracking selected values, `ItemStateRenderer` for styling based on focus/selection state, and `renderFocusableContainer()` helper that orchestrates layout + styling + scrolling. Zero duplication, consistent behavior, maximum testability.

## Context / Problem

List has ListHandler for focus logic, but there's no shared selection state manager or standardized container helper for focusable items. Both List and Table need consistent, reusable components.

## Specification / Goal

Extract and formalize reusable components needed by both List and Table including focus navigation handler, selection state manager, item rendering utilities, and container rendering helper.

## Design

### Current State
- List has `ListHandler: Focusable` (focus logic only)
- No shared selection state manager
- No standardized container helper for focusable items
- Rendering patterns ad-hoc per control

### Target State
- `FocusableItemListHandler`. Ushared focus/navigation logic
- `SelectionStateManager<T>`. Ushared selection tracking
- `renderFocusableContainer()`. Uhelper similar to `renderContainer()`
- `ItemStateRenderer`. Uutilities for styling items based on focus/selection

## Implementation Steps

### Phase 1: Create FocusableItemListHandler
1. Create new file: `Sources/TUIkit/Internal/FocusableItemListHandler.swift`
2. Extract from List's `ListHandler`:
   - `focusedIndex`, `scrollOffset`, `viewportHeight`, `rowCount`
   - `focusUp()`, `focusDown()`, `focusHome()`, `focusEnd()`, `focusPageUp()`, `focusPageDown()`
   - `ensureFocusedInView()`
3. Conform to `Focusable` protocol
4. Add proper documentation

### Phase 2: Create SelectionStateManager
1. Create new file: `Sources/TUIkit/Internal/SelectionStateManager.swift`
2. Generic class: `SelectionStateManager<SelectionValue: Hashable>`
3. Properties:
   - `binding: Binding<AnyHashable>?`
   - `selectedValue: AnyHashable?`
4. Methods:
   - `select(index: Int)`. Uselect by index
   - `select(value: SelectionValue)`. Uselect by value
   - `isSelected(index: Int) -> Bool`
   - `isSelected(value: SelectionValue) -> Bool`
5. Type-erasure utilities for `Binding<SelectionValue>` → `Binding<AnyHashable>`

### Phase 3: Create ItemStateRenderer Utilities
1. Create new file: `Sources/TUIkit/Internal/ItemStateRenderer.swift`
2. Function: `renderItemWithState()`
   - Parameters: `content: String`, `isFocused: Bool`, `isSelected: Bool`, `palette: Palette`
   - Returns: styled string with background color, etc.
3. Optionally: helper for scroll indicators

### Phase 4: Create renderFocusableContainer Helper
1. Create new file: `Sources/TUIkit/Internal/FocusableContainerRenderer.swift`
2. Function: `renderFocusableContainer()`
   - Similar signature to `renderContainer()`
   - Plus: focus handler, selection manager, item renderer
   - Returns: `FrameBuffer`
3. Handles:
   - Extract rows from content
   - Apply focus/selection styling
   - Manage scrolling
   - Wrap in container with title, border, padding

### Phase 5: Testing
1. Create unit tests for each handler/manager
2. Test navigation logic (focusUp, focusDown, wrapping, etc.)
3. Test selection state transitions
4. Test item rendering with various focus/selection states

### Phase 6: Documentation
1. Add doc comments to all new types
2. Document the shared architecture in guides

## Implementation Plan

### Phase 1: Create FocusableItemListHandler
1. Create new file: `Sources/TUIkit/Internal/FocusableItemListHandler.swift`
2. Extract from List's `ListHandler`:
   - `focusedIndex`, `scrollOffset`, `viewportHeight`, `rowCount`
   - `focusUp()`, `focusDown()`, `focusHome()`, `focusEnd()`, `focusPageUp()`, `focusPageDown()`
   - `ensureFocusedInView()`
3. Conform to `Focusable` protocol
4. Add proper documentation

### Phase 2: Create SelectionStateManager
1. Create new file: `Sources/TUIkit/Internal/SelectionStateManager.swift`
2. Generic class: `SelectionStateManager<SelectionValue: Hashable>`
3. Properties: `binding`, `selectedValue`
4. Methods: `select(index:)`, `select(value:)`, `isSelected(index:)`, `isSelected(value:)`
5. Type-erasure utilities for Binding

### Phase 3: Create ItemStateRenderer Utilities
1. Create new file: `Sources/TUIkit/Internal/ItemStateRenderer.swift`
2. Function: `renderItemWithState()` with content, isFocused, isSelected, palette
3. Returns styled string with background color
4. Optionally: helper for scroll indicators

### Phase 4: Create renderFocusableContainer Helper
1. Create new file: `Sources/TUIkit/Internal/FocusableContainerRenderer.swift`
2. Function: `renderFocusableContainer()`
3. Similar signature to `renderContainer()` plus focus handler, selection manager, item renderer
4. Returns: `FrameBuffer`
5. Handles: row extraction, focus/selection styling, scrolling, container wrapping

### Phase 5: Testing
1. Create unit tests for each handler/manager
2. Test navigation logic (focusUp, focusDown, wrapping, etc.)
3. Test selection state transitions
4. Test item rendering with various states

### Phase 6: Documentation
1. Add doc comments to all new types
2. Document the shared architecture in guides

## Checklist

- [ ] Create FocusableItemListHandler
- [ ] Create SelectionStateManager
- [ ] Create ItemStateRenderer utilities
- [ ] Create renderFocusableContainer helper
- [ ] Write comprehensive tests for each component
- [ ] Verify no duplication with existing code
- [ ] Add documentation
- [ ] All tests passing (618 + new tests)
- [ ] swiftlint clean

## Success Criteria
- ✅ All new components have comprehensive tests
- ✅ No duplication of logic between existing and new code
- ✅ Clean, minimal API surface
- ✅ Ready for List and Table to use
- ✅ swiftlint clean
- ✅ All existing tests still pass (618 tests)

## Estimated Effort
**Moderate**, requires careful design. ~4-5 hours.

## Files Created
- `Sources/TUIkit/Internal/FocusableItemListHandler.swift`
- `Sources/TUIkit/Internal/SelectionStateManager.swift`
- `Sources/TUIkit/Internal/ItemStateRenderer.swift`
- `Sources/TUIkit/Internal/FocusableContainerRenderer.swift`
- `Tests/TUIkitTests/FocusableItemListHandlerTests.swift`
- `Tests/TUIkitTests/SelectionStateManagerTests.swift`
