# Render Performance Phase 2: Memoization Activation & Debug Tooling

## Preface

Subtree memoization is activated: environment snapshot comparison in `RenderLoop` automatically invalidates cache on theme/palette changes; core types (Text, Alignment, ContainerConfig, etc.) gain `Equatable` conformance; example app extracts view subcomponents and applies `.equatable()` for real cache benefit. Debug logging (via `TUIKIT_DEBUG_RENDER` env var) tracks cache hits/misses per identity. Between state changes, identical views now skip re-rendering entirely.

## Completed

**2026-02-05** — All 6 phases implemented. PR #74 with environment snapshot comparison, core type Equatable conformances, and debug statistics.

## Checklist

- [x] Add EnvironmentSnapshot struct for cache invalidation
- [x] Implement environment snapshot comparison in RenderLoop
- [x] Add TextStyle: Equatable
- [x] Add Alignment: Equatable
- [x] Add ContainerConfig: Equatable
- [x] Add Text: Equatable
- [x] Add conditional Equatable to VStack, HStack, ZStack
- [x] Add conditional Equatable to Box, BorderedView
- [x] Add conditional Equatable to ContainerView, Panel, Card, Dialog
- [x] Add conditional Equatable to FlexibleFrameView, OverlayModifier, DimmedModifier
- [x] Add RenderCache.Stats struct
- [x] Implement debug logging with TUIKIT_DEBUG_RENDER env var
- [x] Extract view subcomponents for memoization (FeatureBox, ContainerTypesRow, SettingsAndAlignmentRow)
- [x] Apply .equatable() in MainMenuPage and ContainersPage
- [x] Update RenderCycle.md DocC article
- [x] All tests passing (520+)

## Goal

Make the existing subtree memoization (Phase 5, PR #71) actually effective. Currently `EquatableView` + `RenderCache` are fully implemented but **unused in production**: zero views call `.equatable()`, and only 3 trivial views (`Spacer`, `Divider`, `EmptyView`) conform to `Equatable`. Additionally, environment changes bypass cache invalidation — a latent bug that becomes real the moment `.equatable()` is used.

This plan closes the gaps:
1. Fix the environment/cache invalidation bug
2. Add `Equatable` conformances to core types and views
3. Apply `.equatable()` in the example app for real-world benefit
4. Add debug tooling for render performance analysis
5. Decompose complex view bodies in the example app
6. Document everything in DocC

## Findings Summary

### Already `Equatable`
- `Color` (auto-synthesized via `ColorValue: Equatable`)
- `BorderStyle` (8 `Character` properties, auto-synthesized)
- `EdgeInsets` (auto-synthesized)
- `HorizontalAlignment`, `VerticalAlignment` (simple enums, implicit)
- `Spacer`, `Divider`, `EmptyView`

### Need `Equatable` Conformance (trivial — add declaration, auto-synthesis works)
- `TextStyle` (9 properties: `Color?` × 2, `Bool` × 7)
- `Alignment` (2 properties: `HorizontalAlignment`, `VerticalAlignment`)
- `ContainerConfig` (5 properties: `BorderStyle?`, `Color?` × 2, `EdgeInsets`, `Bool`)

### Cache Invalidation Bug
- `StateBox.value.didSet` → `renderCache.clearAll()` ✅
- `ThemeManager.applyCurrentItem()` → `appState.setNeedsRender()` only ❌
- `StatusBarState` (6 call sites) → `appState.setNeedsRender()` only ❌
- `PulseTimer` / `Spinner` → `setNeedsRender()` only — **correct**, these don't change view content
- **Fix**: Environment snapshot comparison in `RenderLoop` — see Phase 1

### Where Cache Helps Most
- **Spinner frames** (~25 FPS): `setNeedsRender()` without `@State` change → cache stays valid between state changes. Static views next to spinners benefit fully.
- **Pulse animation**: Same pattern — `PulseTimer` triggers renders, cache survives.
- **After any state change**: One full render repopulates cache, subsequent frames reuse it until next state change.

### Closure Problem
- `Button`, `Menu`, `KeyPressModifier`, lifecycle modifiers contain closures → parent views can't be `Equatable`
- **Workaround**: Extract data-only subtrees below the closure boundary. The parent with the closure can't use `.equatable()`, but its children can.

## Implementation Plan

### Phase 1: Fix Cache Invalidation Bug (High Priority)

**Principle: The SDK handles invalidation — developers never think about it.**

#### The Problem

Environment changes (theme, palette, appearance) bypass `renderCache.clearAll()`. Only `StateBox.value.didSet` clears the cache. `ThemeManager`, `StatusBarState`, and other framework services call `appState.setNeedsRender()` directly — the cache serves stale content.

#### Rejected Approaches

- **Option A**: `clearAll()` in `AppState.setNeedsRender()` — kills cache during Spinner/Pulse frames (~25 FPS of wasted memoization)
- **Option B**: `clearAll()` in specific callers (`ThemeManager`, etc.) — fragile, easy to forget for future callers
- **Generation counter on `EnvironmentValues`**: `buildEnvironment()` creates a fresh instance every frame and sets the same N keys → mutation count is identical regardless of whether values changed. Values are `Any` → can't compare.

#### Chosen Approach: Environment Snapshot Comparison in RenderLoop

`RenderLoop` tracks the identity of environment values that affect visual output. After `buildEnvironment()`, it compares the current snapshot with the previous frame. If different → `clearAll()`.

The snapshot tracks **only values that affect rendered output**: palette name and appearance name. Reference-type services (`FocusManager`, `ThemeManager`) don't affect cached content — they're infrastructure.

This is:
- **Automatic** — developer never thinks about it
- **Spinner/Pulse safe** — environment doesn't change between their frames → no clear
- **Correct** — any theme/appearance change triggers clear
- **Cheap** — two string comparisons per frame

#### Implementation

- [x] Add `EnvironmentSnapshot` struct (private in `RenderLoop.swift`) with `paletteID` and `appearanceID`
- [x] Add `private var lastEnvironmentSnapshot: EnvironmentSnapshot?` to `RenderLoop`
- [x] In `RenderLoop.render()`, after `buildEnvironment()`: snapshot from built `EnvironmentValues`, compare, `clearAll()` on mismatch
- [x] Keep existing `clearAll()` in `StateBox.value.didSet`
- [x] Doc comment on `AppState.setNeedsRender()`

#### Tests

- [x] Theme change with `.equatable()` view → verify view re-renders with new palette
- [x] `setNeedsRender()` without state change → verify cache survives (Spinner scenario)
- [x] StatusBar content change → verify it doesn't unnecessarily clear the cache

### Phase 2: Equatable Conformances for Core Types (High Priority)

#### 2a. Types (prerequisites for views)

- [x] `TextStyle: Equatable` — auto-synthesis
- [x] `Alignment: Equatable` — auto-synthesis
- [x] `ContainerConfig: Equatable` — auto-synthesis
- [x] `ContainerStyle: Equatable` — auto-synthesis (added during implementation)

#### 2b. Leaf Views

- [x] `Text: Equatable` — stored properties: `content: String`, `style: TextStyle`
- [x] Test: existing EquatableView tests cover Text equality

#### 2c. Container Views (conditional conformance)

- [x] `VStack: Equatable where Content: Equatable`
- [x] `HStack: Equatable where Content: Equatable`
- [x] `ZStack: Equatable where Content: Equatable`
- [x] `Box: Equatable where Content: Equatable`
- [x] `BorderedView: Equatable where Content: Equatable`
- [x] `ContainerView: Equatable where Content: Equatable, Footer: Equatable`
- [x] `Panel: Equatable where Content: Equatable, Footer: Equatable`
- [x] `Card: Equatable where Content: Equatable, Footer: Equatable`
- [x] `Dialog: Equatable where Content: Equatable, Footer: Equatable`
- [x] Existing EquatableView tests cover equality via cache hit/miss

#### 2d. Modifier Views (conditional conformance where possible)

- [x] `FlexibleFrameView: Equatable where Content: Equatable`
- [x] `OverlayModifier: Equatable where Base: Equatable, Overlay: Equatable`
- [x] `DimmedModifier: Equatable where Content: Equatable`
- Skipped: `EnvironmentModifier` — `WritableKeyPath` is not `Equatable`
- Skipped: `PaddingModifier`, `BackgroundModifier` — these are `ViewModifier` (buffer transform), not `View`, so not relevant for `EquatableView` comparison

Note: Modifier views with closures (`KeyPressModifier`, `OnAppearModifier`, `TaskModifier`, etc.) **cannot** be made `Equatable` — this is expected and matches SwiftUI behavior.

### Phase 3: Debug Tooling (Medium Priority)

- [x] Add `RenderCache.Stats` struct with hits/misses/stores/clears, hitRate, delta(since:)
- [x] Increment counters in `lookup` (hit/miss), `clearAll` (clears), `store`
- [x] `private(set) var stats` + `statsAtFrameStart` for per-frame deltas
- [x] `TUIKIT_DEBUG_RENDER=1` env var: per-identity HIT/MISS/STORE logs + FRAME summary
- [x] `logDebug(@autoclosure)` — zero cost when disabled, stderr output
- [x] 11 new tests for stats counting, delta, reset
- Deferred: `View._printChanges()` equivalent — future work

### Phase 4: Example App — View Decomposition (Medium Priority)

- [x] `ContainerTypesRow` — Card/Box/Panel comparison row (from ContainersPage)
- [x] `SettingsAndAlignmentRow` — settings panel + alignment demos (from ContainersPage)
- [x] `FeatureBox` — extracted from MainMenuPage's private `featureBox()` method
- Skipped: ButtonsPage — nearly all sections depend on `@State clickCount` via Button closures, decomposition ineffective for memoization
- Skipped: CollapsibleSection — depends on `@State showDetails`, must stay in parent

### Phase 5: Example App — Apply `.equatable()` (Medium Priority)

- [x] `FeatureBox: View, Equatable` + `.equatable()` on 3 instances in MainMenuPage
- [x] `ContainerTypesRow: View, Equatable` + `.equatable()` in ContainersPage
- [x] `SettingsAndAlignmentRow: View, Equatable` + `.equatable()` in ContainersPage

### Phase 6: Documentation (Low Priority)

- [x] Update `RenderCycle.md` — new "Subtree Memoization" section with how-it-works, invalidation, decision guide, type list, debug logging
- [x] Add `EquatableView` to Renderable lists in existing sections
- [x] Correct "no subtree memoization" claim
- [x] Code example using real `FeatureBox` from example app

## Files Modified

| File | Change |
|---|---|
| `Sources/TUIkit/Rendering/RenderLoop.swift` | Environment snapshot comparison, `clearAll()` on change |
| `Sources/TUIkit/Rendering/RenderCache.swift` | `EnvironmentSnapshot` struct, `Stats` struct, debug logging |
| `Sources/TUIkit/State/State.swift` | Doc comment on `AppState.setNeedsRender()` |
| `Sources/TUIkit/Views/Text.swift` | `TextStyle: Equatable`, `Text: Equatable` |
| `Sources/TUIkit/Views/Stacks.swift` | `Alignment: Equatable`, conditional `Equatable` on stacks |
| `Sources/TUIkit/Views/ContainerView.swift` | `ContainerConfig: Equatable`, conditional `Equatable` |
| `Sources/TUIkit/Views/Panel.swift` | Conditional `Equatable` |
| `Sources/TUIkit/Views/Card.swift` | Conditional `Equatable` |
| `Sources/TUIkit/Views/Dialog.swift` | Conditional `Equatable` |
| `Sources/TUIkit/Views/Box.swift` | Conditional `Equatable` |
| `Sources/TUIkit/Modifiers/*.swift` | Conditional `Equatable` on modifier views |
| `Sources/TUIkit/Rendering/RenderCache.swift` | Stats struct, debug logging |
| `Example/Sources/Pages/*.swift` | Subview extraction, `.equatable()` usage |
| DocC articles | Phase 5+6 documentation |

## Risks

| Risk | Mitigation |
|---|---|
| Auto-synthesized `Equatable` on generic views may not compile if `Content` has constraints | Conditional conformance `where Content: Equatable` — standard Swift pattern |
| Over-caching after environment changes (stale colors/borders) | Phase 1 fixes this before any `.equatable()` usage |
| Debug logging performance overhead | Gated behind environment variable, zero cost when disabled |
| `TupleView` Equatable — `(A, B, C, ...)` tuples up to arity 6 are Equatable in Swift, but TUIKit's `TupleView` may need explicit conformance | Investigate during Phase 2c, add if needed |

## Open Questions

1. **`TupleView` Equatable**: `VStack { Text("A"); Text("B") }` creates a `TupleView<(Text, Text)>`. Is `TupleView` `Equatable` when its elements are? Needs investigation — may need explicit conditional conformance for each arity.
2. **Granular cache invalidation**: Instead of `clearAll()`, could we invalidate only entries that depend on changed environment keys? Complex but would maximize cache effectiveness. Probably not worth it now — `clearAll()` is simple and correct.
3. **Automatic `.equatable()`**: Should the framework automatically wrap views in `EquatableView` when they conform to `Equatable`? SwiftUI does NOT do this (requires explicit `.equatable()`). Recommend keeping opt-in for now.
