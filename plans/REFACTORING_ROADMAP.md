# TUIKit View Architecture Refactoring Roadmap

## Overview
Three-phase refactoring to implement proper SwiftUI-like View architecture across TUIKit.

**Status:** Planning complete. Ready for implementation.
**Total Effort:** ~20-25 hours
**Outcome:** All controls follow correct pattern, maximum code reuse, proper modifier support

---

## Phase 1: ContainerView Refactoring
**Branch:** `refactor/containerview`  
**Estimated:** 2-3 hours  
**Risk:** Low (mechanical refactoring)

### What
- Extract `_ContainerViewCore` with Renderable implementation
- Simplify public `ContainerView` to View with body
- Enable modifier support

### Why
- Current pattern breaks modifier chaining
- Environment values don't propagate
- Foundation for List & Table

### Success Criteria
✅ 618 tests pass  
✅ Modifiers work on ContainerView  
✅ No breaking changes  
✅ Follows Box.swift pattern

---

## Phase 2: Shared Handlers & Helpers
**Branch:** `refactor/shared-handlers`  
**Estimated:** 4-5 hours  
**Risk:** Moderate (careful API design needed)

### What
- `FocusableItemListHandler` for shared focus/navigation logic
- `SelectionStateManager<T>` for shared selection tracking
- `ItemStateRenderer` for styling utilities
- `renderFocusableContainer()` as helper function

### Why
- List and Table share 80% of focus/selection/rendering logic
- Currently would be duplicated
- Foundation for clean List & Table implementation

### Success Criteria
✅ Zero duplication of focus logic  
✅ Comprehensive tests for each component  
✅ Clean, minimal API  
✅ Ready for List & Table to use  
✅ 618 tests still pass

---

## Phase 3: List & Table Implementation
**Branch:** `feat/list-table-new`  
**Estimated:** 14-18 hours  
**Risk:** Moderate (integration work)

### What
**List (Refactor):**
- Use `_ListCore` with Renderable
- Replace `ListHandler` with `FocusableItemListHandler`
- Use `SelectionStateManager`
- Use `renderFocusableContainer()`
- Public View with body

**Table (New):**
- `Table<SelectionValue, Content>: View`
- `_TableCore` with Renderable
- Same handlers as List (navigation)
- Column-specific: alignment, padding, grid rendering

### Why
- Proper View architecture enables modifiers
- Shared foundation prevents duplication
- Both follow same pattern (consistency)
- Environment values propagate

### Success Criteria
✅ 618 existing tests pass  
✅ List tests updated and pass  
✅ Table tests created (50+) and pass  
✅ Modifiers work on both  
✅ Zero duplication  
✅ Both follow Box.swift pattern  
✅ Keyboard navigation consistent  
✅ Selection handling consistent

---

## Execution Sequence

```
Phase 1: refactor/containerview
         ↓
         [PR #XX: ContainerView refactoring]
         ↓ (merge)
         ↓
Phase 2: refactor/shared-handlers
         ↓
         [PR #YY: Shared handlers & helpers]
         ↓ (merge)
         ↓
Phase 3: feat/list-table-new
         ↓
         [PR #ZZ: List refactoring & Table implementation]
         ↓ (merge)
         ↓
✅ DONE: TUIKit with proper View architecture
```

---

## Key Principles Applied

1. **Everything visible is a View**: enables modifiers, environment propagation
2. **Composition not Inheritance**: use helpers and handlers, not class hierarchies
3. **Maximize Code Reuse**: shared handlers/helpers before implementation
4. **Follow Existing Patterns**: Box.swift, renderContainer() model
5. **Test at Every Phase**: no breaking changes, all tests pass

---

## Branch Management

All three branches start from the same commit (planning phase complete).
They can be worked on in parallel ONLY if no dependencies.

**Recommended sequence:**
1. Phase 1 (independent): can start immediately
2. Phase 2 (depends on Phase 1 being merged): start after Phase 1 PR approved
3. Phase 3 (depends on Phase 1+2 being merged): start after Phase 2 PR approved

---

## Next Steps

1. Review Phase 1 plan: `plans/open/2026-02-06-imp-containerview.md`
2. Checkout `refactor/containerview` branch
3. Start implementation when ready

Questions? Check the detailed plans:
- `plans/open/2026-02-06-imp-containerview.md`
- `plans/open/2026-02-06-imp-shared-handlers.md`
- `plans/open/2026-02-06-imp-list-table.md`

And the architecture analysis:
- `plans/open/2026-02-06-list-table-shared-architecture.md`
- `plans/open/2026-02-06-containerization-composition.md`
