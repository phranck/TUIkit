# State Storage Identity

## Preface

State now survives **any** view reconstruction via structural identity: each view gets a stable key (its position in the tree), and state values live in external `StateStorage` indexed by that key. Self-hydrating `@State.init` checks the active context during `body` evaluation and retrieves persistent storage immediately. This foundation enables components like RadioButtonGroup, List, and any control with persistent local state to work reliably across all render passes.

## Completed

**2026-02-02** — All five phases implemented. Self-hydrating `@State` with structural identity, persistent `StateStorage`, garbage collection, branch invalidation, and root context hydration in `RenderLoop`. Dead code (Mirror-based `hydrateState`, `_hydrateField`, `StateHydratable`) removed.

## Checklist

- [x] Create ViewIdentity type for stable view keys
- [x] Create StateStorage class for persistent state
- [x] Add StateRegistration counter enum
- [x] Extend RenderContext with identity and helper methods
- [x] Extend TUIContext with stateStorage
- [x] Update renderToBuffer for identity propagation
- [x] Update TupleView.childInfos for child index tracking
- [x] Update ViewArray.childInfos for enumeration
- [x] Implement State<Value> self-hydration
- [x] Set/clear active context around body evaluation
- [x] Update RenderLoop root context setup
- [x] Update ConditionalView for branch invalidation
- [x] Remove scene cache from RenderLoop
- [x] Implement garbage collection in StateStorage
- [x] Write comprehensive tests (12 tests)
- [x] Update DocC documentation
- [x] Inline documentation on all new types

---

## Context / Problem

`@State` in TUIKit only survives render passes because the top-level scene is cached in `RenderLoop.scene`. Once a view sits deeper in the tree and gets reconstructed during a `body` call, a new `Storage` object is allocated and the previous value is lost.

In SwiftUI, `@State` survives **every** reconstruction because state values live in an external storage graph, indexed by the view's **structural position** in the tree (Structural Identity).

## Specification / Goal

Every `@State` in TUIKit must survive render passes — regardless of whether the view is reconstructed on every frame. The user-facing API (`@State var count = 0`) remains unchanged.

## Design

### Core Concept: Self-Hydrating State

Originally planned as a two-phase model (construct locally, then hydrate via Mirror).
During implementation, we switched to a **self-hydrating** approach:

`renderToBuffer` sets `StateRegistration.activeContext` before evaluating a composite
view's `body`. When `@State.init` runs inside `body`, it checks for an active context
and directly retrieves or creates a persistent `StateBox` from `StateStorage`.

This avoids unsafe pointer manipulation and Mirror reflection entirely.

### Building Blocks

#### 1. `ViewIdentity` (new type)

Stable key per view position in the tree. Built incrementally during render traversal.

```swift
struct ViewIdentity: Hashable {
    let path: String  // e.g. "ContentView/VStack.0/Menu"
}
```

The path is composed of:
- **Type name** of the view (`String(describing: V.self)`)
- **Child index** within the parent container (0, 1, 2, ...)

Example for `ContentView` with `VStack { Header(); Menu() }`:

```
"ContentView"
"ContentView/VStack.0"    → HeaderView
"ContentView/VStack.1"    → Menu
```

#### 2. `StateStorage` (new type)

Central store for all state values. Lives in `TUIContext`.

```swift
final class StateStorage {
    private var values: [StateKey: AnyObject] = [:]

    struct StateKey: Hashable {
        let identity: ViewIdentity
        let propertyIndex: Int  // 0th @State, 1st @State, etc. per view
    }

    func storage<Value>(for key: StateKey, default: Value) -> StateBox<Value> { ... }
    func invalidateDescendants(of ancestor: ViewIdentity) { ... }
}
```

#### 3. `RenderContext` Extension

`RenderContext` gains an `identity: ViewIdentity` field that is extended during traversal.

Convenience methods:
- `withChildIdentity(type:index:)` — for container children
- `withChildIdentity(type:)` — for composite view body descent
- `withBranchIdentity(_:)` — for ConditionalView branches

#### 4. `@State` Self-Hydration

`State<Value>.init` checks `StateRegistration.activeContext`. If present, it claims a
property index from `StateRegistration.counter` and retrieves a persistent `StateBox`
from `StateStorage`. If absent, it creates a local `StateBox` (pre-render or testing).

```swift
public init(wrappedValue: Value) {
    if let context = StateRegistration.activeContext {
        let index = StateRegistration.counter
        StateRegistration.counter += 1
        let key = StateStorage.StateKey(identity: context.identity, propertyIndex: index)
        self.box = context.storage.storage(for: key, default: wrappedValue)
    } else {
        self.box = StateBox(wrappedValue)
    }
}
```

#### 5. `RenderLoop` Root Context

`RenderLoop.render()` sets the active context **before** `app.body` evaluation so that
views constructed inside `WindowGroup { ... }` (e.g. `ContentView()`) self-hydrate
immediately:

```swift
let rootIdentity = ViewIdentity(rootType: A.self)
StateRegistration.activeContext = HydrationContext(
    identity: rootIdentity,
    storage: tuiContext.stateStorage
)
StateRegistration.counter = 0
let scene = app.body
StateRegistration.activeContext = nil
tuiContext.stateStorage.markActive(rootIdentity)
```

#### 6. `renderToBuffer` Hydration Setup

The free function `renderToBuffer` sets the active context before evaluating `body`:

```swift
if V.Body.self != Never.self {
    let childContext = context.withChildIdentity(type: V.Body.self)
    StateRegistration.activeContext = HydrationContext(
        identity: context.identity,
        storage: context.tuiContext.stateStorage
    )
    StateRegistration.counter = 0
    let body = view.body
    StateRegistration.activeContext = nil
    context.tuiContext.stateStorage.markActive(context.identity)
    return renderToBuffer(body, context: childContext)
}
```

#### 7. Child-Index Tracking in Containers

`TupleView.childInfos` uses `infos.count` as the index (workaround for Swift's `repeat`
statement not supporting mutable counters). `ViewArray.childInfos` uses `enumerated()`.

#### 8. `ConditionalView` Branch Stability

On branch switch, `ConditionalView` invalidates the inactive branch's state descendants
via `stateStorage.invalidateDescendants(of:)`.

## Implementation

### Phase 1: Infrastructure ✅

- [x] 1. **`ViewIdentity`** type (`Sources/TUIkit/State/ViewIdentity.swift`)
- [x] 2. **`StateStorage`** type (`Sources/TUIkit/State/StateStorage.swift`)
- [x] 3. **`StateRegistration`** counter enum (in `State.swift`)
- [x] 4. **`RenderContext`** extended with `identity: ViewIdentity` and helper methods
- [x] 5. **`TUIContext`** extended with `stateStorage: StateStorage`

### Phase 2: Identity Propagation ✅

- [x] 6. **`renderToBuffer` (free function)** — `withChildIdentity(type: V.Body.self)` on body descent
- [x] 7. **`TupleView.childInfos`** — `withChildIdentity(type:index:)` via `infos.count` workaround
- [x] 8. **`ViewArray.childInfos`** — `enumerated()` for child index
- [x] 9. **`resolveChildInfos` / `makeChildInfo`** — no change needed, context flows through
- [x] 10. **`ConditionalView`** — `withBranchIdentity("true"/"false")` + `invalidateDescendants`

### Phase 3: State Hydration ✅

- [x] 11. **`State<Value>`** — self-hydrating init via `StateRegistration.activeContext`
- [x] 12. **`renderToBuffer`** — set/clear active context around `body` evaluation, save/restore for nesting
- [x] 13. **`AppStorage`** — not applicable (uses explicit string keys, no identity needed)

### Phase 4: Cleanup and Edge Cases ✅

- [x] 14. **Remove scene cache** — `RenderLoop.scene` removed, `app.body` evaluated fresh each frame
- [x] 15. **ConditionalView branch invalidation** — already done in Phase 2 step 10
- [x] 16. **Lifecycle coordination** — `stateStorage.beginRenderPass()`/`endRenderPass()` in `RenderLoop.render()`

### Phase 5: Tests and Documentation ✅

- [x] 17. **Write tests** — 12 tests: self-hydration, multi-property, identity paths, branch invalidation, GC, renderToBuffer integration, nested views
- [x] 18. **Update DocC** — StateManagement.md (structural identity, persistent storage, GC), RenderCycle.md (state tracking, identity in context, dispatch code)
- [x] 19. **Inline docs** — all new types fully documented (ViewIdentity, StateStorage, StateBox, HydrationContext, StateRegistration)

## Open Questions

1. ~~**Mirror vs. explicit protocol for hydration?**~~ **Resolved:** Self-hydrating init — `@State.init` checks `StateRegistration.activeContext` and retrieves persistent `StateBox` directly. No Mirror, no unsafe pointers, no type-erased protocol needed.

2. ~~**Parameter pack `repeat` with mutable index?**~~ **Resolved:** `infos.count` as index proxy.

3. ~~**State garbage collection?**~~ **Resolved:** `StateStorage.beginRenderPass()`/`endRenderPass()` called by `RenderLoop.render()`. Views not marked active during the frame get their state removed. `ConditionalView` also calls `invalidateDescendants` immediately on branch switch.
