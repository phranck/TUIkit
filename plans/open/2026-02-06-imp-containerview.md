# Implementation Plan: ContainerView Refactoring

## Objective
Refactor `ContainerView` from `body: Never` + `Renderable` pattern to correct `View` pattern with internal `_ContainerViewCore`.

## Current State
- `ContainerView<Content, Footer>: View` with `body: Never`
- 400+ lines of rendering logic in `renderToBuffer()`
- Modifiers don't work on ContainerView

## Target State
- `ContainerView<Content, Footer>: View` with `body: some View`
- `_ContainerViewCore<Content, Footer>: View, Renderable` contains all logic
- Modifiers work naturally (`.foregroundColor()`, etc.)
- Environment values propagate to content

## Implementation Steps

### Phase 1: Extract _ContainerViewCore
1. Create new private struct `_ContainerViewCore<Content: View, Footer: View>`
2. Copy all properties from ContainerView to _ContainerViewCore
3. Move `renderToBuffer()` logic to _ContainerViewCore
4. Conform _ContainerViewCore to `Renderable`

### Phase 2: Simplify ContainerView
1. Keep all public initializers on ContainerView
2. Add `body: some View` that creates and returns `_ContainerViewCore`
3. Remove `renderToBuffer()` from ContainerView
4. Verify `ContainerConfig` and `ContainerStyle` helpers still work

### Phase 3: Testing & Verification
1. Run all tests — verify no breakage
2. Check users: Card, Panel, Alert, Dialog still render correctly
3. Verify modifiers work: test `.foregroundColor()` on ContainerView
4. Test environment propagation to nested content

### Phase 4: Documentation
1. Update any comments/docs referencing the old pattern
2. Add note about `_ContainerViewCore` being internal implementation detail

## Success Criteria
- ✅ All 618 tests pass
- ✅ No breaking changes to public API
- ✅ Modifiers work on ContainerView
- ✅ Environment values propagate
- ✅ Code follows Box.swift pattern
- ✅ swiftlint clean

## Estimated Effort
**Low-risk**, mechanical refactoring. ~2-3 hours.

## Files Changed
- `Sources/TUIkit/Views/ContainerView.swift` (main)
- Possibly minimal changes to test files if needed

## Related Plans
- Follows from architectural review (CLAUDE.md updates)
- Foundation for List & Table refactoring
- Prerequisite for proper View modifier support
