# Implementation Plan: List & Table (Refactored)

## Preface

List and Table are both implemented using proper View architecture: public View with `body: some View`, private `_ListCore`/`_TableCore` containing all rendering logic. Both share focus and selection handling via `ItemListHandler`, which combines navigation and selection logic in a single reusable component. This establishes a consistent, reusable pattern for List and Table while serving as a reference for future components.

## Completed

**2026-02-08**: List and Table implemented with ItemListHandler. Both use proper View architecture with private _Core structs.

## Context / Problem

List uses the wrong pattern (body: Never + Renderable), and Table doesn't exist yet. Both need shared focus/selection infrastructure.

## Specification / Goal

Implement List and Table using shared handlers/helpers with proper View architecture, ensuring consistency and reducing code duplication.

## Design

### Current State
- List exists but uses wrong pattern (body: Never + Renderable)
- Table doesn't exist yet
- No shared foundation

### Target State
- List: Public View with body, private _ListCore with Renderable
- Table: Public View with body, private _TableCore with Renderable
- Both use: ItemListHandler (combined navigation + selection)
- Both follow Box.swift pattern

## Implementation Steps

### Phase 1: Refactor List (Using Shared Components)
1. Create `_ListCore` private struct
2. Create unified `ItemListHandler` with navigation + selection
3. Update public List to have `body: some View` that creates _ListCore
4. Remove `renderToBuffer()` from public List
5. Verify all List tests still pass

### Phase 2: Implement Table (Using Shared Components)
1. Create `Table<SelectionValue, Content>: View`
2. Create `_TableCore` private struct with Renderable
3. Use `ItemListHandler` (same navigation + selection as List)
4. Implement table-specific logic:
   - Column parsing and alignment
   - ANSI-aware column padding
   - Grid rendering (not vertical stack)
5. Tests: navigation, selection, column alignment

### Phase 3: Verify Architecture Consistency
1. Both List and Table follow same pattern:
   - Public View with `body: some View`
   - Private Core with Renderable
   - Use shared ItemListHandler
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

## Checklist

- [x] Create _ListCore struct
- [x] Create ItemListHandler with navigation + selection
- [x] Update List public API with body: some View
- [x] All List tests passing
- [x] Create _TableCore struct
- [x] Implement Table full API
- [x] All Table tests passing
- [x] Verify architecture consistency
- [x] Integration tests passing
- [x] Example app updated
- [ ] Documentation complete (DocC)
- [x] swiftlint clean

## Success Criteria
- [x] All 666 tests pass (was 618)
- [x] List tests pass (updated for new pattern)
- [x] Table tests created and pass (53 tests for List/Table)
- [x] Modifiers work on both List and Table
- [x] Environment values propagate
- [x] Minimal code duplication (shared ItemListHandler)
- [x] Both follow Box.swift pattern
- [x] swiftlint clean
- [x] No breaking changes to public API

## Estimated Effort
**Moderate to High**, requires careful implementation. ~6-8 hours for List, ~8-10 hours for Table.

## Files Changed/Created
- `Sources/TUIkit/Views/List.swift` (refactored)
- `Sources/TUIkit/Views/Table.swift` (new)
- `Sources/TUIkit/Focus/ItemListHandler.swift` (new, shared)
- `Tests/TUIkitTests/ListTests.swift` (updated)
- `Tests/TUIkitTests/TableTests.swift` (new)
- `Tests/TUIkitTests/ItemListHandlerTests.swift` (new)
- `Sources/TUIkitExample/Pages/ListPage.swift` (updated)
- `Sources/TUIkitExample/Pages/TablePage.swift` (new)

## Dependencies
- Phase 1: ContainerView refactoring ✓
- Phase 2: Shared handlers/helpers ✓
- These must be completed first
