# Render Cycle

Understand how TUIkit turns your view tree into terminal output: one frame at a time.

## Overview

Every frame in TUIkit follows the same synchronous pipeline: **clear per-frame state → build environment → traverse the view tree (one or more passes) → commit → flush to terminal**. The view tree is fully re-evaluated each frame, but only **changed terminal lines** are written. Those writes are collected in a frame buffer and normally flushed with one `write()` syscall.

A single frame may traverse the tree more than once (first-frame header sizing, header correction). Effects therefore never reach live runtime state during traversal: each pass records into scratch collectors, and a single **frame commit** applies only the final pass's results. See <doc:RenderCycle#Render-Phases-and-the-Frame-Commit>.

## What Triggers a Frame

Several sources cause `RenderLoop` to produce a new frame. They enter one
`RuntimeEventChannel`, and `AppRunner` consumes them serially on the main actor:

| Trigger | Source | Mechanism |
|---------|--------|-----------|
| Terminal resize | `SIGWINCH` dispatch source | Sends `.terminalResized` and invalidates the diff cache |
| State mutation | `@State` property change | `AppState` sends `.renderRequested` through its observer |
| Focus animation | `RuntimeAnimationScheduler` | Sends `.animationDeadline` only while an animation is visible |
| View animation | Spinner or notification task | Invalidates `AppState`, which sends `.renderRequested` |
| Focus change | `FocusManager.onFocusChange` | Resets the pulse phase and invalidates `AppState` |

The event loop suspends when no event or animation deadline is pending. Signal
callbacks and background tasks only enqueue events or invalidations; rendering
itself stays serialized on the main actor.

## The Render Pipeline

Each call to `RenderLoop.render()` executes these steps in order:

@Image(source: "render-cycle-pipeline.png", alt: "Diagram showing the 12-step render pipeline: Step 1 clear per-frame state (key handlers, preferences, focus, status bar, app header), Step 2 begin lifecycle/state/cache tracking, Step 3 build environment with all subsystem values and services, Step 4 create render context, Step 5 evaluate scene, Step 6 render view tree, Step 7 build output lines, Step 8 begin buffered frame, Step 9 render app header and diff content, Step 10 render status bar, Step 11 flush frame, Step 12 end tracking (lifecycle onDisappear, state GC, cache cleanup).")

### Step 1: Clear Per-Frame State

Five subsystems are reset at the start of every frame:

- **`KeyEventDispatcher`**: All key handlers are removed. Views re-declare them during traversal; the frame commit adopts the final pass's handler list.
- **`PreferenceStorage`**: The value stack is reset to a single empty `PreferenceValues`.
- **`FocusManager`**: Focus registrations are collected per pass in a staging area; the last committed sections stay queryable while the tree renders.
- **`StatusBarState`**: Declarative registrations are cleared. Views re-declare them via `.statusBarItems()` modifiers.
- **`AppHeaderState`**: Header content is cleared. The `.appHeader()` modifier repopulates it during rendering.

Additionally, the `StatusBarState` receives a reference to the current `FocusManager` for section resolution.

This ensures that views which disappeared between frames don't leave stale handlers or registrations behind.

### Step 2: Begin Lifecycle and State Tracking

The `LifecycleManager` prepares for a new frame by clearing the set of structural runtime slots seen in the current pass. The `StateStorage` and observation registry clear their active identity sets. The `RenderCache` begins a new render pass for cache hit/miss tracking. As views render, they mark their stable slots or identities active. After rendering, the managers compare current and previous frames to detect which views appeared, disappeared, stopped being observed, or had their state removed.

### Step 3: Build Environment

A fresh ``EnvironmentValues`` instance is assembled from the owning runtime:

```swift
// Simplified from TUIContext.environmentValues()
var env = EnvironmentValues()
env.renderInvalidationSink = tuiContext.appState
env.stateStorage        = tuiContext.stateStorage
env.renderCache         = tuiContext.renderCache
env.storageBackend      = tuiContext.storageBackend
env.lifecycle           = tuiContext.lifecycle
env.keyEventDispatcher  = tuiContext.keyEventDispatcher
env.preferenceStorage   = tuiContext.preferences
env.localizationService = tuiContext.localizationService
env.notificationService = tuiContext.notificationService
env.focusManager        = tuiContext.focusManager
env.paletteManager      = tuiContext.paletteManager
env.appearanceManager   = tuiContext.appearanceManager
env.imageLoader         = tuiContext.imageLoader
env.imageCache          = tuiContext.imageCache
```

This environment is immutable for the duration of the frame. Every application
owns its service instances, and views access them through the environment rather
than through `TUIContext` or process-wide service globals.

### Step 4: Create Render Context

A ``RenderContext`` bundles everything a view needs to render:

| Property | What |
|----------|------|
| `availableWidth` | Terminal width (mutable: containers reduce this for children) |
| `availableHeight` | Terminal height minus status bar (mutable) |
| `environment` | The ``EnvironmentValues`` from step 3 |
| `identity` | The current view's structural identity (`ViewIdentity`) |

`RenderContext` is a pure data container: it does not hold a reference to `Terminal`. All terminal I/O happens after the view tree has been rendered into a ``FrameBuffer``.

The context is passed down the view tree. Each view can create a modified copy for its children: for example, a border reduces `availableWidth` by 2 before rendering its content. Container views extend the `identity` path for each child.

### Step 5: Evaluate Scene

`app.body` is evaluated fresh each frame, producing a ``WindowGroup`` that wraps the root view. The `WindowGroup` implements `SceneRenderable` and bridges from the scene layer to the view layer.

> Note: Views are fully reconstructed on every frame. `@State` values survive because the renderer binds each view's dynamic properties to `StateStorage` at the view's final structural identity before evaluating `body`.

### Step 6: Render View Tree

This is where the dual rendering system kicks in. ``WindowGroup`` calls the free function `renderToBuffer()` on its content, which recursively traverses the entire view tree and produces a ``FrameBuffer``.

A frame can perform this traversal up to three times — a first-frame sizing pass, the main pass, and a header-correction pass — and only one of them produces the frame's output. Every traversal writes its effects (handlers, preferences, status-bar items, header buffer, lifecycle records) into fresh per-pass collectors; discarded passes are simply dropped. See <doc:RenderCycle#Render-Phases-and-the-Frame-Commit>.

> Important: Mutating state from inside a view's `body` (or a `Renderable` implementation) during this traversal is unsupported. The framework cannot prevent it, but it diagnoses it: a main-thread invalidation raised inside the traversal window is reported through `RuntimeDiagnostics` once per frame, and the invalidation is still honored so rendering stays consistent. Move such mutations into event handlers, `.task`, or lifecycle actions.

> See <doc:RenderCycle#The-Dual-Rendering-System> below for details on how views are dispatched.

### Step 7: Build Output Lines

The ``FrameBuffer`` is converted into terminal-ready output lines by `FrameDiffWriter.buildOutputLines()`:

1. The cell surface is clipped to the terminal's cell width and height without splitting wide graphemes
2. Clipped cells are encoded into normalized, terminal-safe SGR strings
3. Each output row is cleared with the active background and padded to the terminal width
4. Empty rows are filled so the output contains exactly `terminalHeight` lines

### Step 8: Begin Buffered Frame

`Terminal.beginFrame()` activates output buffering. From this point, all `Terminal.write()` calls append to an internal `[UInt8]` buffer instead of issuing syscalls.

### Step 9: Render App Header and Diff Content

If the app header has content (set by the `.appHeader()` modifier), it is rendered at the top of the terminal. Then `FrameDiffWriter.writeContentDiff()` compares the main content output lines with the previous frame and writes **only changed lines** to the terminal buffer. For mostly-static UIs, this reduces writes by ~94%.

### Step 10: Render Status Bar

The status bar renders in a separate pass but writes into the **same frame buffer**, so app header, content, and status bar are flushed together.

### Step 11: Flush Frame

`Terminal.endFrame()` normally writes the entire collected buffer to
`STDOUT_FILENO` in a **single `write()` syscall**, then resets the buffer.
Interrupted calls and partial transfers are retried; permanent failures are
propagated after terminal cleanup.

### Step 12: Commit Lifetime Effects and Finalize Tracking

After terminal output, the frame commit replays the final pass's lifetime
effect records (`onAppear` actions, `onDisappear` registrations, `.task`
mounts, deferred `onChange`/`onPreferenceChange` actions) in traversal order,
then four managers finalize the frame:

- The **`LifecycleManager`** compares the committed frame's structural slots with the previous frame's. Disappeared views fire their `onDisappear` callbacks, cancel mounted tasks, and leave the appeared set so a future mount can trigger `onAppear` again.
- The **`StateStorage`** performs garbage collection on the committed tree's liveness set: any state whose view identity the final pass did not keep alive is removed.
- The **observation registry** removes identities absent from the committed tree. Cache hits preserve existing registrations below skipped subtrees; callbacks from older generations and unmounted identities become inert.
- The **`RenderCache`** removes inactive entries (subtrees no longer in the view tree) and optionally logs per-frame cache statistics.

All state changes inside the lifecycle manager are `NSLock`-protected. Callbacks execute **outside** the lock to prevent deadlocks.

### Status Bar Rendering (Step 10)

The status bar renders in a separate pass but within the same buffered frame:

1. A ``StatusBar`` view is created with resolved palette colors
2. A dedicated ``RenderContext`` is created with `availableHeight` set to the status bar's height
3. `renderToBuffer()` runs on the status bar view: same dispatch as the main content
4. `FrameDiffWriter.writeStatusBarDiff()` diffs the status bar independently from the main content
5. Changed lines are written into the same frame buffer as the content

The status bar is **never affected** by view dimming or overlays. It always renders at the bottom of the terminal.

## Render Phases and the Frame Commit

A frame is not a single walk over the view tree. Layout sizing evaluates
subtrees speculatively, the first frame measures the app header before any
output exists, and a header-height correction re-evaluates the whole tree.
TUIkit therefore separates **evaluating** a tree from **committing** its
effects — the same conceptual split SwiftUI uses.

### Phases

Every traversal carries a `RenderPhase` on its `RenderContext`:

| Phase | Meaning | Guarantees |
|-------|---------|------------|
| `.measure` | Layout sizing (per-child `sizeThatFits`, first-frame header sizing) | Bodies may be evaluated arbitrarily often; no effect reaches live runtime state, no observation callbacks are registered |
| `.render` | Candidate-tree evaluation for the frame's output | Effects are recorded per pass, never applied directly — the candidate may still be discarded |

Committing is **not** a phase a view can observe: no body evaluates while the
frame commits. The commit is an explicit step in the render loop after the
final candidate is known.

### Two effect patterns, one question

Every effect site classifies itself with one question: **does the effect
outlive the frame?**

- **No → pass collector.** Key handlers, preference values, status-bar
  declarations, the header buffer, and focus registrations are per-frame
  values: the tree re-declares them on every traversal. Each pass writes them
  into fresh scratch collectors, and the commit adopts the FINAL pass's
  collectors into the live managers wholesale. This mirrors SwiftUI's model
  where per-update values are recomputed and the last committed tree simply
  replaces the previous one.
- **Yes → pending record.** `onAppear`/`onDisappear` actions, `.task` mounts,
  `onChange`/`onPreferenceChange` actions, and GC liveness derive from the
  identity diff between committed trees. Traversal only records them; the
  commit replays the final pass's records — after terminal output, in
  traversal order, exactly once.

### What a discarded pass guarantees

The first-frame sizing pass and a superseded main pass are dropped together
with their collectors and records. They start no tasks, fire no actions,
register no handlers or focusables, keep no state alive, and register no
observation callbacks. Only the commit changes terminal output and visible
runtime records.

Implementation details live in the doc comments of `RenderPhase`,
`RenderPassCollectors`, `PendingFrameEffects`, and the frame choreography
comment on `RenderLoop`.

## The Dual Rendering System

TUIkit has two ways for a view to produce output:

### Path 1: Direct Rendering (Renderable)

Views that conform to `Renderable` implement `renderToBuffer(context:)` and produce a ``FrameBuffer`` directly. Their `body` property is **never called**.

This path is used by:
- **Leaf views**: ``Text``, ``Spacer``, `Divider`, ``EmptyView``
- **Layout containers**: `VStack`, `HStack`, `ZStack`
- **Interactive views**: ``Button``, ``ButtonRow``, ``Menu``
- **Container views**: ``Panel``, ``Card``, ``Alert``, ``Dialog``
- **Modifier wrappers**: `ModifiedView`, `DimmedModifier`, `OverlayModifier`, `EnvironmentModifier`, ``EquatableView``, and all lifecycle modifiers

### Path 2: Composition (body)

Views that are **not** `Renderable` declare their content through `body`. The rendering system recursively renders the body until it hits a `Renderable` leaf.

This path is used by:
- **Composite views**: ``Card`` returns `content.padding().border(...)`, which wraps in a `ContainerView` (whose `_ContainerViewCore` is `Renderable`)
- **User-defined views**: Your custom views compose other views in `body`

### The Dispatch Function

The free function `renderToBuffer()` is the single entry point for all view rendering:

```swift
func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    // Priority 1: Direct rendering
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    }

    // Priority 2: Composite: bind dynamic properties and recurse into body.
    if V.Body.self != Never.self {
        let childContext = context.withChildIdentity(type: V.Body.self)
        let body = StateRegistration.withHydration(of: view, context: context) {
            // Observation is tracked for context.identity here.
            view.body
        }
        // ... mark context.identity active ...
        return renderToBuffer(body, context: childContext)
    }

    // Priority 3: No rendering path: empty buffer
    return FrameBuffer()
}
```

@Image(source: "render-cycle-dispatch.png", alt: "Decision tree showing the dual rendering dispatch: renderToBuffer checks Renderable conformance first, then body recursion, then returns an empty buffer as fallback.")

> Important: If a view conforms to `Renderable`, its `body` is never evaluated. This is intentional: `Renderable` views produce output directly and don't need compositional decomposition.

## FrameBuffer

``FrameBuffer`` is the off-screen rendering primitive. Internally it owns a terminal-cell surface whose cells store a grapheme, wide-cell continuation, normalized style, and transparency explicitly. Its public `lines` property remains a compatibility adapter for ANSI-styled input and terminal-safe encoded output.

### Creation

Views create buffers in their `renderToBuffer(context:)`:

- ``Text``: one or more styled cell rows
- ``Spacer``: rows of blank cells
- ``EmptyView``: empty buffer (no lines)

### Combination

Layout containers combine child buffers using `FrameBuffer` methods:

| Method | Used by | What it does |
|--------|---------|--------------|
| `appendVertically(_:spacing:)` | `VStack` | Stacks surfaces top to bottom in one pass |
| `appendHorizontally(_:spacing:)` | `HStack` | Places surfaces side by side, padding shorter sides |
| `overlay(_:)` | `ZStack` | Composites cells while preserving content below transparent cells |
| `composited(with:at:)` | Overlay modifier | Composites at a cell position and replaces wide graphemes atomically |

### Diff-Based Output

After the view tree produces a ``FrameBuffer``, the `FrameDiffWriter` prepares terminal-ready output:

1. The cell surface is clipped to the terminal dimensions
2. Its rows are encoded into normalized SGR strings
3. Each row is cleared and padded with the active background color

The diff writer then compares each output line with the previous frame. Only lines that actually changed are written to the terminal via `Terminal.moveCursor()` + `Terminal.write()`. All writes are collected in a frame buffer and normally flushed with one syscall.

## Environment Flow

Environment values flow **top-down** through the render tree via ``RenderContext``:

```
RenderLoop.buildEnvironment()
  → RenderContext carries EnvironmentValues
    → EnvironmentModifier creates a copy with modified value
      → Children see the modified value
    → Siblings and parents see the original (copy semantics)
```

The `EnvironmentModifier` (created by `.environment(_:_:)`) works by:

1. Creating a new `EnvironmentValues` with the modified key
2. Creating a new `RenderContext` with that environment via `context.withEnvironment()`
3. Rendering its content with the new context

There is no global environment: everything flows through the context parameter.

## Preference Collection

Preferences flow **bottom-up**: the reverse of environment values. Child views set values that parent views observe.

`PreferenceStorage` uses a stack-based collection mechanism:

1. `OnPreferenceChangeModifier` calls `push()`: creates a new collection scope
2. Its child tree renders, and `PreferenceModifier` calls `setValue()` on the current scope
3. `OnPreferenceChangeModifier` calls `pop()`: merges collected values into the parent scope

The `reduce(value:nextValue:)` function on ``PreferenceKey`` controls how multiple values from different children are combined. The default behavior: last value wins.

The `onPreferenceChange` action follows SwiftUI semantics: it fires at the
frame commit when the subtree's reduced value **changed** against the last
committed frame (and once when the subtree first appears) — never during
traversal, and never for unchanged values.

## ViewModifier Pipeline

TUIkit has two modifier architectures:

### Buffer Modifiers (ViewModifier protocol)

These transform a ``FrameBuffer`` after the content has rendered:

```swift
public protocol ViewModifier {
    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer
    func adjustContext(_ context: RenderContext) -> RenderContext  // default: returns context unchanged
}
```

`ModifiedView` wraps a view and a modifier. It first calls `adjustContext(_:)` to let the modifier reduce available space (e.g. padding), then renders the content, then calls `modify(buffer:context:)`. Examples:

- **`PaddingModifier`**: Adds empty lines (top/bottom) and spaces (leading/trailing) around the buffer
- **`BackgroundModifier`**: Paints the background style directly onto cells and fills each row to the surface width

### View-Level Modifiers (Renderable)

More complex modifiers are full `View + Renderable` implementations that control when and how their content renders:

- **`ContainerView` / `_ContainerViewCore`**: Reduces `availableWidth` by 2, renders content, adds border characters via `BorderRenderer`
- **`FlexibleFrameView`**: Modifies `availableWidth`/`availableHeight` before rendering, applies min/max constraints and alignment after
- **`OverlayModifier`**: Renders base and overlay separately, composites via `FrameBuffer.composited(with:at:)`
- **`DimmedModifier`**: Renders content, then applies ANSI dim code to every line
- **`EnvironmentModifier`**: Creates modified context, renders content with it
- **``EquatableView``**: Checks `RenderCache` before rendering; returns cached buffer on hit, renders and stores on miss (see <doc:RenderCycle#Subtree-Memoization>)

## Lifecycle Tracking

The `LifecycleManager` tracks view visibility across frames using stable slots derived from each modifier's structural identity. Reconstructing the same view hierarchy therefore addresses the same lifecycle state instead of creating a new token every frame.

### onAppear

The `OnAppearModifier` records its appearance during traversal; the record is
applied at the **frame commit**, after the frame reached the terminal:

- The structural slot is marked visible in the committed frame
- If the slot has **never appeared before**: it is added to the appeared set and the action fires
- If it **has** appeared before: the action does **not** fire (prevents repeated triggers)

> Note: `onAppear` fires at the frame commit — after terminal output, never
> during traversal. A view that only existed in a discarded pass (sizing or
> superseded by a correction) never fires its action, matching SwiftUI's
> model where effects follow the committed tree.

### onDisappear

The `OnDisappearModifier` records two things during traversal, applied at commit:

1. Its callback registration for `lifecycle.registerDisappear(identity:action:)`
2. Its structural slot's visibility in the committed frame

The actual `onDisappear` callback fires in step 12 (end lifecycle tracking), **after** the entire view tree has rendered.

### Task Lifecycle

The `TaskModifier` (created by `.task()`) combines appearance tracking with async tasks:

1. The first committed frame containing a structural task slot starts one `Task` with the given priority and operation
2. Unchanged reconstruction preserves the mounted task instead of restarting it
3. Removing the slot cancels the task; mounting it again starts a new task
4. A task recorded by a discarded pass is never even started

## Output Optimization

TUIkit uses three techniques to minimize terminal I/O:

### Line-Level Diffing

`FrameDiffWriter` stores the previous frame's output lines and compares them with the new frame. Only lines that actually changed are written to the terminal. For mostly-static UIs (where only a few elements change per frame), this reduces terminal writes by ~94%.

### Frame Buffering

All terminal writes during a frame are collected in an internal `[UInt8]`
buffer via `Terminal.beginFrame()` / `Terminal.endFrame()`. The entire frame is
normally flushed to `STDOUT_FILENO` with one `write()` syscall. Interrupted and
partial transfers are retried without truncating the frame.

### Cell-Based Layout

``FrameBuffer`` stores its measured width with the cell surface. Layout, clipping, and compositing therefore operate directly on cell arrays without repeatedly stripping or reparsing ANSI strings. The public compatibility lines are derived from that surface, and the terminal boundary consumes the same normalized encoding.

### What Is NOT Diffed

The view tree is re-evaluated each frame: there is no virtual DOM. However, views wrapped in ``EquatableView`` (via `.equatable()`) can skip subtree rendering when their properties are unchanged. See <doc:RenderCycle#Subtree-Memoization> below.

The alternate screen buffer (entered during setup) ensures that the user's previous terminal content is preserved and restored on exit.

## Subtree Memoization

While the view tree is reconstructed each frame, ``EquatableView`` allows **individual subtrees** to skip rendering when their inputs haven't changed. This combines the simplicity of full tree evaluation with targeted caching for expensive or static subtrees.

### How It Works

When a view is wrapped in `.equatable()`, the rendering system:

1. Skips the cache entirely in `.measure` traversals: effect sites are inert during sizing, so a buffer stored there could let the same frame's output pass hit a subtree whose effects never mounted
2. Looks up the cached ``FrameBuffer`` for this view's `ViewIdentity` — identities classified as **effect-bearing** always miss (see below)
3. Compares the **current view value** with the cached snapshot via `Equatable.==`
4. Checks that the available **width and height** and the **environment fingerprint** (foreground style, focus indicator color) haven't changed
5. On **cache hit**: returns the cached buffer and preserves the subtree's State, Observation, and nested cache-entry liveness without evaluating its body
6. On **cache miss**: renders normally, classifies the content via the pass's effect-registration probe, and stores the result only when the rendering registered no effects

### Effect-Bearing Subtrees

Content that registers per-pass effects while rendering — key handlers,
focus registrations (`Button`, `Toggle`, …), focus sections, status-bar
declarations, preference writes, or lifetime-effect records (`onAppear`,
`.task`, …) — must reach the frame's collectors on **every** frame; a
cached buffer would silently drop those registrations at the frame commit.

`EquatableView` therefore snapshots the pass's effect-registration probe
around every cache-miss rendering. Any delta flags the identity in the
`RenderCache`: flagged identities never produce hits, so the subtree
renders each frame and behaves exactly as if it were unwrapped (including
pulse-animated focus indicators). The classification refreshes on every
miss, so content that becomes effect-free re-enables caching automatically.

This makes `.equatable()` **safe to apply anywhere**: only provably
effect-free output is ever served from the cache. On effect-bearing
subtrees the wrapper simply has no effect.

### Liveness Guarantees

A cache hit keeps every runtime record below the cached root alive without
traversing the subtree: `@State` boxes, Observation registrations, and
nested cache entries survive via subtree marking at the frame commit.
Effect-bearing records (lifecycle slots, tasks, handlers, status-bar items,
focus registrations) need no such marking — subtrees owning them never hit
the cache and re-register on every frame.

```swift
// A static info box: title and subtitle are the only inputs.
struct FeatureBox: View, Equatable {
    let title: String
    let subtitle: String

    var body: some View {
        VStack {
            Text(title).bold().foregroundColor(.palette.accent)
            Text(subtitle).foregroundColor(.palette.foregroundSecondary)
        }
        .padding(EdgeInsets(horizontal: 2, vertical: 1))
        .border(color: .palette.border)
    }
}

// In a parent view: cached between frames when title/subtitle are unchanged:
FeatureBox("Pure Swift", "No ncurses").equatable()
```

### Cache Invalidation

The runtime applies pending cache invalidations before rendering:

| Trigger | Mechanism |
|---------|-----------|
| `@State` or `@AppStorage` change | Invalidates the owning view subtree |
| Observed model change | Invalidates the structural subtree that read the dependency |
| Language change | Requests a full runtime cache clear |
| Global environment change | `RenderLoop` compares an `EnvironmentSnapshot` (palette ID + appearance ID) each frame and clears on mismatch |
| Style environment change | Entries store an environment fingerprint (foreground style, focus indicator color) captured at their tree position; a lookup with a differing fingerprint misses and re-renders |

Each runtime owns its own `RenderCache`, so invalidation in one application cannot
evict another application's cached output. Between invalidations, for example
during Spinner animation frames, static subtrees are reused across frames.

### When to Use `.equatable()`

| Good candidates | Why |
|----------------|-----|
| Static display views (labels, headers, feature boxes) | Properties rarely change, body is rebuilt identically each frame |
| Complex container hierarchies | Many nested views that produce the same output |
| Views next to animated siblings | Spinner/Pulse re-renders the whole tree; static siblings benefit from caching |

| Pointless candidates | Why |
|---------------------|-----|
| Views that read `@State` directly | State lives in a reference-type box: the view struct compares as equal even when state changed |
| Views that change every frame | Cache overhead with no benefit |
| Tiny views (single `Text`) | Rendering cost is already minimal |
| Effect-bearing subtrees (interactive controls, lifecycle modifiers, status-bar declarations) | Automatically detected and bypassed — safe, but the wrapper adds nothing |

### Which Types Support `.equatable()`

The following types have `Equatable` conformance, enabling `.equatable()` on views composed of them:

**Leaf views:** ``Text``

**Container views** (conditional: `where Content: Equatable`): `VStack`, `HStack`, `ZStack`, ``Panel``, ``Card``, ``Dialog``, `ContainerView`

**Modifier views** (conditional): `FlexibleFrameView`, `OverlayModifier`, `DimmedModifier`

**Supporting types:** `TextStyle`, `Alignment`, `ContainerConfig`, `ContainerStyle`

> Note: `Button` cannot be `Equatable` because it stores a closure (`action: () -> Void`). A custom `Equatable` view may still contain buttons — its focus registrations then classify the subtree as effect-bearing, and the cache is bypassed instead of dropping the button's interactivity.

### Debug Logging

Set `TUIKIT_DEBUG_RENDER=1` to enable per-frame cache statistics on stderr:

```
[RenderCache] STORE Root/MainMenuPage/FeatureBox
[RenderCache] HIT Root/MainMenuPage/FeatureBox
[RenderCache] MISS (no entry) Root/SpinnersPage/Spinner
[RenderCache] FRAME: hits: 3, misses: 2, stores: 2, clears: 0, entries: 3, hit rate: 60%
```

Redirect with `2>render.log` to capture without interfering with the TUI.
