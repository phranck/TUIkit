# Render Pipeline Phase 5: Subtree Memoization

## Preface

Subtree memoization caches rendered FrameBuffers by view identity: when a view conforms to `Equatable` and is wrapped in `.equatable()`, the framework compares the new view with the cached one. If equal (and available size hasn't changed), the cached FrameBuffer is reused — skipping the entire subtree's re-rendering. `RenderCache` stores buffers keyed by `ViewIdentity`, invalidated when `@State` changes or environment changes. Between state changes, identical views like Spinners skip rendering entirely.

## Completed

**2026-02-04** — PR #71 merged. 18 tests (11 RenderCache + 7 EquatableView), 503 total.

## Problem

After phases 1–4 optimized terminal I/O (line diffing, output buffering, caching), the view tree is still **fully reconstructed every frame**. Every `body` is evaluated, every `renderToBuffer()` runs, every FrameBuffer is allocated — even when nothing changed.

For a UI with 30 views and a single animating Spinner, ~29 views produce identical output. The entire subtree is re-rendered for nothing.

### Per-frame cost (post Phase 1–4)

| Category | Still happens | Notes |
|---|---|---|
| View struct allocations | ~30 | Every view rebuilt from scratch |
| FrameBuffer allocations | ~15 | One per leaf + container |
| `body` evaluations | ~15 | Every composite view |
| `renderToBuffer()` calls | ~15 | Every Renderable |
| String allocations | ~50+ | FrameBuffer content |

Line diffing (Phase 1) catches identical output at the terminal level, but the CPU work to *produce* that identical output is wasted.

## Goal

Skip `body` evaluation and `renderToBuffer()` for subtrees whose inputs haven't changed. Opt-in via `Equatable` conformance, matching SwiftUI's approach.

## Design

### Core Concept

When a view conforms to `Equatable` and is wrapped in `EquatableView`, the render pipeline:

1. Looks up the previous view value and cached FrameBuffer by `ViewIdentity`
2. Compares the new view with the old one (`==`)
3. Compares the relevant context (available size)
4. If both match → returns cached buffer, skips entire subtree
5. If not → renders normally, caches result

### Key Types

#### `RenderCache`

```swift
final class RenderCache {
    struct CacheEntry {
        let viewSnapshot: Any        // type-erased previous view value
        let buffer: FrameBuffer
        let contextWidth: Int
        let contextHeight: Int
    }

    private var entries: [ViewIdentity: CacheEntry] = [:]
}
```

Stored on `TUIContext` alongside `StateStorage`. Single instance per app.

#### `EquatableView<Content: View & Equatable>`

```swift
struct EquatableView<Content: View & Equatable>: View {
    let content: Content
    var body: Never { ... }
}
```

Conforms to `Renderable`. Its `renderToBuffer` performs the cache check. If hit, returns cached buffer. If miss, delegates to `renderToBuffer(content, context:)` and caches the result.

**Why a wrapper instead of checking in `renderToBuffer()`?** Because the type-erased cache comparison (`Any as? V`) needs to know the concrete `Equatable`-conforming type. `EquatableView` provides that type context at the call site.

#### `.equatable()` Modifier

```swift
extension View where Self: Equatable {
    func equatable() -> EquatableView<Self> {
        EquatableView(content: self)
    }
}
```

### Cache Invalidation Strategy: Full Clear on State Change

When any `@State` value changes (`StateBox.value.didSet`), the entire render cache is cleared.

**Why full clear?**

The problem: `@State` lives in `StateBox` (reference type). The owning View struct compares as equal even when state changed, because `Equatable` compares value-type fields, not the referenced box contents. We cannot know which cached subtrees depend on which state values without a dependency graph.

**Why this is still effective:**

- Between state changes, the cache works at full power. This covers:
  - Pulse/breathing animation frames (40ms tick, no state change)
  - Spinner animation frames (state changes in Spinner, but siblings are cached)
  - Any frame triggered by timer without user interaction
- After a state change, one full render pass populates the cache again
- For a 25fps render loop, even caching 50% of frames is significant

**Implementation:** `RenderCache` gets a `clearAll()` method. `StateBox.didSet` calls it through `RenderNotifier`.

### Cache GC

Cache entries for `ViewIdentity` paths not seen during the current render pass are removed in `endRenderPass()`, matching `StateStorage`'s existing GC pattern.

### Framework-Level Equatable Views

Trivial views that benefit from Equatable without risk:

| View | Properties | Notes |
|---|---|---|
| `Divider` | `style: DividerStyle` | Enum, trivially equatable |
| `Spacer` | `minLength: Int?` | Optional Int |
| `EmptyView` | (none) | Always equal |

These are made `Equatable` but NOT automatically wrapped in `EquatableView`. Users still need `.equatable()` or `EquatableView(content:)` to opt in. This matches SwiftUI's design.

## Implementation Plan

### 1. RenderCache

- [x] Create `RenderCache` class in `Sources/TUIkit/Rendering/RenderCache.swift`
- [x] Add `CacheEntry` struct with `viewSnapshot: Any`, `buffer: FrameBuffer`, `contextWidth: Int`, `contextHeight: Int`
- [x] API: `lookup()`, `store()`, `clearAll()`, `removeInactive()`, `markActive()`, `beginRenderPass()`
- [x] Add `renderCache` property to `TUIContext`

### 2. EquatableView + Modifier

- [x] Create `EquatableView<Content>` in `Sources/TUIkit/Core/EquatableView.swift`
- [x] Conform to `Renderable` with cache-check logic
- [x] Add `.equatable()` extension on `View where Self: Equatable`
- [x] Hydration: `EquatableView` must propagate hydration context to content

### 3. Cache Integration in RenderLoop

- [x] Call `renderCache.beginRenderPass()` at start of render
- [x] Call `renderCache.removeInactive()` at end of render (GC)

### 4. State-Change Invalidation

- [x] Add `renderCache` reference to `RenderNotifier` (alongside `AppState`)
- [x] `StateBox.value.didSet` calls `RenderNotifier.current.clearRenderCache()`
- [x] RenderLoop sets `RenderNotifier.renderCache` at startup

### 5. Framework Equatable Conformances

- [x] `Divider: Equatable`
- [x] `Spacer: Equatable`
- [x] `EmptyView: Equatable`

### 6. Tests

- [x] RenderCache: store/lookup/miss/hit with equal view
- [x] RenderCache: miss on different view
- [x] RenderCache: miss on different context size
- [x] RenderCache: clearAll empties everything
- [x] RenderCache: GC removes inactive entries
- [x] EquatableView: renders content on first pass
- [x] EquatableView: returns cached buffer on equal content + same size
- [x] EquatableView: re-renders on different content
- [x] EquatableView: re-renders on different context size
- [x] EquatableView: cache clearAll (state-change invalidation)
- [x] Integration: EquatableView inside VStack layout
- [x] Divider/Spacer/EmptyView Equatable conformance

### 7. Documentation

- [ ] Update `RenderCycle.md` DocC article with Phase 5 info (deferred)
- [x] Doc comments on all new public types

## Render Flow (After Phase 5)

```
renderToBuffer(view, context)
  ├─ view is EquatableView<V>?
  │    ├─ cache lookup by identity
  │    ├─ cached + view == oldView + size matches?
  │    │    └─ return cached buffer ← SKIP ENTIRE SUBTREE
  │    └─ miss:
  │         ├─ renderToBuffer(content, context) ← normal render
  │         └─ store in cache
  │
  ├─ view is Renderable?
  │    └─ view.renderToBuffer(context:)          ← unchanged
  │
  ├─ Body != Never?
  │    └─ hydrate → view.body → recurse          ← unchanged
  │
  └─ empty FrameBuffer                           ← unchanged
```

## Open Questions

1. **Should `EquatableView` also check environment values?** Currently only checking view equality + context size. If a parent changes `.foregroundColor()`, the cached buffer would be stale. For now: no environment check — the full-clear-on-state-change covers most cases, and environment changes typically accompany state changes. Can add later if needed.

2. **Should we expose cache statistics?** A `RenderCache.Stats` struct (hits, misses, entries) could help developers optimize. Low priority, easy to add.
