# Implementation Plan: List & Table (Refactored)

## Objective
Implement List and Table using shared handlers/helpers from Phase 2, with proper View architecture.

## Current State
- List exists but uses wrong pattern (body: Never + Renderable)
- Table doesn't exist yet
- No shared foundation

## Target State
- List: Public View with body, private _ListCore with Renderable
- Table: Public View with body, private _TableCore with Renderable
- Both use: FocusableItemListHandler, SelectionStateManager, renderFocusableContainer()
- Both follow Box.swift pattern

## Implementation Steps

### Phase 1: Refactor List (Using Shared Components)
1. Create `_ListCore` private struct
2. Replace direct `ListHandler` with `FocusableItemListHandler`
3. Replace ad-hoc selection logic with `SelectionStateManager`
4. Use `renderFocusableContainer()` helper
5. Update public List to have `body: some View` that creates _ListCore
6. Remove `renderToBuffer()` from public List
7. Verify all List tests still pass

### Phase 2: Implement Table (Using Shared Components)
1. Create `Table<SelectionValue, Content>: View`
2. Create `_TableCore` private struct with Renderable
3. Use `FocusableItemListHandler` (same navigation as List)
4. Use `SelectionStateManager` (row-based selection)
5. Implement table-specific logic:
   - Column parsing and alignment
   - ANSI-aware column padding
   - Grid rendering (not vertical stack)
6. Create helper: `renderTableGrid()` or use `renderFocusableContainer()`
7. Tests: navigation, selection, column alignment

### Phase 3: Verify Architecture Consistency
1. Both List and Table follow same pattern:
   - Public View with `body: some View`
   - Private Core with Renderable
   - Use shared handlers/helpers
2. Both support modifiers naturally
3. Environment values propagate correctly
4. Keyboard navigation consistent
5. Selection handling consistent

### Phase 4: Integration Testing
1. Test List with all modifiers: `.foregroundColor()`, `.padding()`, `.disabled()`
2. Test Table with all modifiers
3. Test environment propagation through ListItem content
4. Test selection state transitions
5. Test keyboard navigation in both
6. Test focus indicator rendering

### Phase 5: Example Apps & Docs
1. Update ListPage to use new List
2. Create TablePage example
3. Document keyboard navigation
4. Document selection patterns
5. Add code examples to DocC

## Success Criteria
- ✅ All 618 existing tests pass
- ✅ List tests pass (updated for new pattern)
- ✅ Table tests created and pass (>50 tests)
- ✅ Modifiers work on both List and Table
- ✅ Environment values propagate
- ✅ Zero code duplication between List and Table
- ✅ Both follow Box.swift pattern
- ✅ swiftlint clean
- ✅ No breaking changes to public API

## Estimated Effort
**Moderate to High**, requires careful implementation. ~6-8 hours for List, ~8-10 hours for Table.

## Files Changed/Created
- `Sources/TUIkit/Views/List.swift` (refactored)
- `Sources/TUIkit/Views/Table.swift` (new)
- `Tests/TUIkitTests/ListTests.swift` (updated)
- `Tests/TUIkitTests/TableTests.swift` (new)
- `Sources/TUIkitExample/Pages/ListPage.swift` (updated)
- `Sources/TUIkitExample/Pages/TablePage.swift` (new)

## Dependencies
- Phase 1: ContainerView refactoring ✓
- Phase 2: Shared handlers/helpers ✓
- These must be completed first

## Related Plans
- Uses FocusableItemListHandler, SelectionStateManager, renderFocusableContainer()
- Follows Box.swift pattern
- Final implementation of View Architecture guidelines
