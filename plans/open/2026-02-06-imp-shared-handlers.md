# Implementation Plan: Shared Focus/Selection Handlers & Helpers

## Objective
Extract and formalize reusable components needed by both List and Table:
- Focus navigation handler
- Selection state manager
- Item rendering utilities
- Container rendering helper

## Current State
- List has `ListHandler: Focusable` (focus logic only)
- No shared selection state manager
- No standardized container helper for focusable items
- Rendering patterns ad-hoc per control

## Target State
- `FocusableItemListHandler` — shared focus/navigation logic
- `SelectionStateManager<T>` — shared selection tracking
- `renderFocusableContainer()` — helper similar to `renderContainer()`
- `ItemStateRenderer` — utilities for styling items based on focus/selection

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
   - `select(index: Int)` — select by index
   - `select(value: SelectionValue)` — select by value
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

## Related Plans
- Foundation for List & Table implementation
- Uses patterns from ContainerView refactoring
- Enables maximum code reuse
