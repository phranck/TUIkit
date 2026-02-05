# Render Cycle

Understand how TUIkit turns your view tree into terminal output — one frame at a time.

## Overview

Every frame in TUIkit follows the same synchronous pipeline: **clear per-frame state → build environment → render the view tree → diff against previous frame → flush to terminal → track lifecycle**. The view tree is fully re-evaluated each frame, but only **changed terminal lines** are written — and all writes are collected in a frame buffer and flushed as a **single `write()` syscall**.

## What Triggers a Frame

Three things cause `RenderLoop` to produce a new frame:

| Trigger | Source | Mechanism |
|---------|--------|-----------|
| Terminal resize | `SIGWINCH` signal | `SignalManager` sets a boolean flag |
| State mutation | `@State` property change | ``AppState`` notifies its observer via ``RenderNotifier``, which sets the rerender flag |
| Programmatic | `appState.setNeedsRender()` | Same observer path as above (services receive `AppState` via constructor injection) |

All triggers converge on boolean flags that the main loop checks each iteration. The actual rendering always happens on the main thread — signal handlers never render directly.

## The Render Pipeline

Each call to `RenderLoop.render()` executes these steps in order:

@Image(source: "render-cycle-pipeline.png", alt: "Diagram showing the 12-step render pipeline: clear per-frame state, begin lifecycle tracking, build environment, create render context, evaluate scene, render view tree, build output lines, begin buffered frame, diff and write changed lines, render status bar into same buffer, flush frame, end lifecycle tracking.")

### Step 1: Clear Per-Frame State

Three subsystems are reset at the start of every frame:

- **`KeyEventDispatcher`** — All key handlers are removed. Views re-register them during rendering via `onKeyPress()` modifiers.
- **`PreferenceStorage`** — All preference callbacks are cleared and the stack is reset to a single empty `PreferenceValues`.
- **``FocusManager``** — All focus registrations are cleared. Focusable views re-register during rendering.

This ensures that views which disappeared between frames don't leave stale handlers or registrations behind.

### Step 2: Begin Lifecycle and State Tracking

The `LifecycleManager` prepares for a new frame by clearing its `currentRenderTokens` set. The `StateStorage` clears its active identity set. As views render, they add their tokens/identities to these sets. After rendering, the managers compare current and previous frames to detect which views appeared, disappeared, or had their state removed.

### Step 3: Build Environment

A fresh ``EnvironmentValues`` instance is assembled from the current subsystem state:

```swift
// Simplified from RenderLoop.buildEnvironment()
var env = EnvironmentValues()
env.statusBar       = statusBar
env.focusManager    = focusManager
env.paletteManager  = paletteManager
env.palette         = paletteManager.current    // e.g. GreenPalette
env.appearanceManager = appearanceManager
env.appearance      = appearanceManager.current // e.g. BorderStyle.rounded
```

This environment is immutable for the duration of the frame.

### Step 4: Create Render Context

A ``RenderContext`` bundles everything a view needs to render:

| Property | What |
|----------|------|
| `availableWidth` | Terminal width (mutable — containers reduce this for children) |
| `availableHeight` | Terminal height minus status bar (mutable) |
| `environment` | The ``EnvironmentValues`` from step 3 |
| `tuiContext` | The `TUIContext` (lifecycle, key dispatch, preferences, state storage) |
| `identity` | The current view's structural identity (``ViewIdentity``) |

`RenderContext` is a pure data container — it does not hold a reference to `Terminal`. All terminal I/O happens after the view tree has been rendered into a ``FrameBuffer``.

The context is passed down the view tree. Each view can create a modified copy for its children — for example, a border reduces `availableWidth` by 2 before rendering its content. Container views extend the `identity` path for each child.

### Step 5: Evaluate Scene

`app.body` is evaluated fresh each frame, producing a ``WindowGroup`` that wraps the root view. The `WindowGroup` implements `SceneRenderable` and bridges from the scene layer to the view layer.

> Note: Views are fully reconstructed on every frame. `@State` values survive because `State.init` self-hydrates from `StateStorage` — looking up the persistent value by the view's structural identity.

### Step 6: Render View Tree

This is where the dual rendering system kicks in. ``WindowGroup`` calls the free function `renderToBuffer()` on its content, which recursively traverses the entire view tree and produces a ``FrameBuffer``.

> See <doc:RenderCycle#The-Dual-Rendering-System> below for details on how views are dispatched.

### Step 7: Build Output Lines

The ``FrameBuffer`` is converted into terminal-ready output lines by `FrameDiffWriter.buildOutputLines()`:

1. Lines with content get their ANSI reset codes replaced with `reset + backgroundColor` (persistent background)
2. Each line is padded to full terminal width
3. Empty rows are filled with the background color
4. The total output is exactly `terminalHeight` lines

### Step 8: Begin Buffered Frame

`Terminal.beginFrame()` activates output buffering. From this point, all `Terminal.write()` calls append to an internal `[UInt8]` buffer instead of issuing syscalls.

### Step 9: Diff and Write Changed Lines

`FrameDiffWriter.writeContentDiff()` compares the new output lines with the previous frame and writes **only changed lines** to the terminal buffer. For mostly-static UIs, this reduces writes by ~94%.

### Step 10: Render Status Bar

The status bar renders in a separate pass (see below) but writes into the **same frame buffer**, so content and status bar are flushed together.

### Step 11: Flush Frame

`Terminal.endFrame()` writes the entire collected buffer to `STDOUT_FILENO` in a **single `write()` syscall**, then resets the buffer. This reduces per-frame syscalls from ~40+ to exactly 1.

### Step 12: End Lifecycle and State Tracking

The `LifecycleManager` compares the current frame's tokens with the previous frame's:

- **Disappeared views** — tokens present last frame but absent now. Their `onDisappear` callbacks fire, and their tokens are removed from the appeared set (allowing future `onAppear` if they return).
- **Visible views** — the current token set becomes the baseline for the next frame.

The `StateStorage` performs garbage collection: any state whose view identity was not marked active during this render pass is removed. This prevents memory leaks from views that have been permanently removed.

All state changes inside the lifecycle manager are `NSLock`-protected. Callbacks execute **outside** the lock to prevent deadlocks.

### Status Bar Rendering (Step 10)

The status bar renders in a separate pass but within the same buffered frame:

1. A ``StatusBar`` view is created with resolved palette colors
2. A dedicated ``RenderContext`` is created with `availableHeight` set to the status bar's height
3. `renderToBuffer()` runs on the status bar view — same dispatch as the main content
4. `FrameDiffWriter.writeStatusBarDiff()` diffs the status bar independently from the main content
5. Changed lines are written into the same frame buffer as the content

The status bar is **never affected** by view dimming or overlays. It always renders at the bottom of the terminal.

## The Dual Rendering System

TUIkit has two ways for a view to produce output:

### Path 1: Direct Rendering (Renderable)

Views that conform to `Renderable` implement `renderToBuffer(context:)` and produce a ``FrameBuffer`` directly. Their `body` property is **never called**.

This path is used by:
- **Leaf views** — ``Text``, ``Spacer``, `Divider`, ``EmptyView``
- **Layout containers** — `VStack`, `HStack`, `ZStack`
- **Interactive views** — ``Button``, ``ButtonRow``, ``Menu``
- **Container views** — ``Panel``, ``Card``, ``Alert``, ``Dialog``
- **Modifier wrappers** — `ModifiedView`, `BorderedView`, `DimmedModifier`, `OverlayModifier`, `EnvironmentModifier`, ``EquatableView``, and all lifecycle modifiers

### Path 2: Composition (body)

Views that are **not** `Renderable` declare their content through `body`. The rendering system recursively renders the body until it hits a `Renderable` leaf.

This path is used by:
- **Composite views** — ``Box`` returns `content.border(...)`, which wraps in a `BorderedView` (which is `Renderable`)
- **User-defined views** — Your custom views compose other views in `body`

### The Dispatch Function

The free function `renderToBuffer()` is the single entry point for all view rendering:

```swift
func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    // Priority 1: Direct rendering
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    }

    // Priority 2: Composite — set up hydration context and recurse into body.
    // @State.init self-hydrates from StateStorage during body evaluation.
    if V.Body.self != Never.self {
        let childContext = context.withChildIdentity(type: V.Body.self)
        // ... activate StateRegistration.activeContext ...
        let body = view.body
        // ... restore previous context, mark identity active ...
        return renderToBuffer(body, context: childContext)
    }

    // Priority 3: No rendering path — empty buffer
    return FrameBuffer()
}
```

@Image(source: "render-cycle-dispatch.png", alt: "Decision tree showing the dual rendering dispatch: renderToBuffer checks Renderable conformance first, then body recursion, then returns an empty buffer as fallback.")

> Important: If a view conforms to `Renderable`, its `body` is never evaluated. This is intentional — `Renderable` views produce output directly and don't need compositional decomposition.

## FrameBuffer

``FrameBuffer`` is the off-screen rendering primitive. It holds an array of strings (which may contain ANSI escape codes) representing terminal lines.

### Creation

Views create buffers in their `renderToBuffer(context:)`:

- ``Text`` — single line with ANSI style codes
- ``Spacer`` — empty lines
- ``EmptyView`` — empty buffer (no lines)

### Combination

Layout containers combine child buffers using `FrameBuffer` methods:

| Method | Used by | What it does |
|--------|---------|--------------|
| `appendVertically(_:spacing:)` | `VStack` | Stacks buffers top to bottom |
| `appendHorizontally(_:spacing:)` | `HStack` | Places buffers side by side, padding shorter sides |
| `overlay(_:)` | `ZStack` | Line-by-line overlay, non-empty lines replace base |
| `composited(with:at:)` | Overlay modifier | Character-level compositing at (x, y) position |

### Diff-Based Output

After the view tree produces a ``FrameBuffer``, the `FrameDiffWriter` prepares terminal-ready output:

1. Lines with content get their ANSI reset codes replaced with `reset + backgroundColor` (persistent background)
2. Each line is padded to full terminal width
3. Empty lines are filled with the background color

The diff writer then compares each output line with the previous frame. Only lines that actually changed are written to the terminal via `Terminal.moveCursor()` + `Terminal.write()`. All writes are collected in a frame buffer and flushed as a single syscall.

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

There is no global environment — everything flows through the context parameter.

## Preference Collection

Preferences flow **bottom-up** — the reverse of environment values. Child views set values that parent views observe.

`PreferenceStorage` uses a stack-based collection mechanism:

1. `OnPreferenceChangeModifier` calls `push()` — creates a new collection scope
2. Its child tree renders, and `PreferenceModifier` calls `setValue()` on the current scope
3. `OnPreferenceChangeModifier` calls `pop()` — merges collected values into the parent scope and fires the callback

The `reduce(value:nextValue:)` function on ``PreferenceKey`` controls how multiple values from different children are combined. The default behavior: last value wins.

## ViewModifier Pipeline

TUIkit has two modifier architectures:

### Buffer Modifiers (ViewModifier protocol)

These transform a ``FrameBuffer`` after the content has rendered:

```swift
public protocol ViewModifier {
    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer
}
```

`ModifiedView` wraps a view and a modifier — it renders the content first, then calls `modify(buffer:context:)`. Examples:

- **`PaddingModifier`** — Adds empty lines (top/bottom) and spaces (leading/trailing) around the buffer
- **`BackgroundModifier`** — Wraps each line with background ANSI codes, padded to full width

### View-Level Modifiers (Renderable)

More complex modifiers are full `View + Renderable` implementations that control when and how their content renders:

- **`BorderedView`** — Reduces `availableWidth` by 2, renders content, adds border characters via `BorderRenderer`
- **`FlexibleFrameView`** — Modifies `availableWidth`/`availableHeight` before rendering, applies min/max constraints and alignment after
- **`OverlayModifier`** — Renders base and overlay separately, composites via `FrameBuffer.composited(with:at:)`
- **`DimmedModifier`** — Renders content, then applies ANSI dim code to every line
- **`EnvironmentModifier`** — Creates modified context, renders content with it
- **``EquatableView``** — Checks ``RenderCache`` before rendering; returns cached buffer on hit, renders and stores on miss (see <doc:RenderCycle#Subtree-Memoization>)

## Lifecycle Tracking

The `LifecycleManager` tracks view visibility across frames using unique tokens (UUIDs):

### onAppear

The `OnAppearModifier` calls `lifecycle.recordAppear(token, action)` during rendering:

- The token is added to `currentRenderTokens` (always)
- If the token has **never appeared before**: it's added to `appearedTokens` and the action fires
- If it **has** appeared before: the action does **not** fire (prevents repeated triggers)

> Note: `onAppear` fires **synchronously** during the render traversal — not after the frame completes. This is because TUIkit uses single-pass rendering with no layout phase.

### onDisappear

The `OnDisappearModifier` does two things during rendering:

1. Registers its callback with `lifecycle.registerDisappear(token, action)`
2. Marks itself as visible with `lifecycle.recordAppear(token, {})` (empty action)

The actual `onDisappear` callback fires in step 7 (end lifecycle tracking), **after** the entire view tree has rendered.

### Task Lifecycle

The `TaskModifier` (created by `.task()`) combines appearance tracking with async tasks:

1. On first appearance: starts a `Task` with the given priority and operation
2. Registers a disappear callback that cancels the task
3. If the view reappears, a new task starts

## Output Optimization

TUIkit uses three techniques to minimize terminal I/O:

### Line-Level Diffing

`FrameDiffWriter` stores the previous frame's output lines and compares them with the new frame. Only lines that actually changed are written to the terminal. For mostly-static UIs (where only a few elements change per frame), this reduces terminal writes by ~94%.

### Frame Buffering

All terminal writes during a frame are collected in an internal `[UInt8]` buffer via `Terminal.beginFrame()` / `Terminal.endFrame()`. The entire frame is flushed to `STDOUT_FILENO` in a **single `write()` syscall**, reducing per-frame syscalls from ~40+ to exactly 1.

### Width Caching

``FrameBuffer`` caches its `width` as a stored property, recomputed only when `lines` is mutated. This eliminates hundreds of redundant ANSI-stripping regex runs per frame. The `strippedLength` property also avoids intermediate string allocations.

### What Is NOT Diffed

The view tree is re-evaluated each frame — there is no virtual DOM. However, views wrapped in ``EquatableView`` (via `.equatable()`) can skip subtree rendering when their properties are unchanged. See <doc:RenderCycle#Subtree-Memoization> below.

The alternate screen buffer (entered during setup) ensures that the user's previous terminal content is preserved and restored on exit.

## Subtree Memoization

While the view tree is reconstructed each frame, ``EquatableView`` allows **individual subtrees** to skip rendering when their inputs haven't changed. This combines the simplicity of full tree evaluation with targeted caching for expensive or static subtrees.

### How It Works

When a view is wrapped in `.equatable()`, the rendering system:

1. Looks up the cached ``FrameBuffer`` for this view's ``ViewIdentity``
2. Compares the **current view value** with the cached snapshot via `Equatable.==`
3. Checks that the available **width and height** haven't changed
4. On **cache hit**: returns the cached buffer — the entire subtree is skipped
5. On **cache miss**: renders normally and stores the result

```swift
// A static info box — title and subtitle are the only inputs.
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

// In a parent view — cached between frames when title/subtitle are unchanged:
FeatureBox("Pure Swift", "No ncurses").equatable()
```

### Cache Invalidation

The ``RenderCache`` is **fully cleared** in two situations:

| Trigger | Mechanism |
|---------|-----------|
| Any `@State` change | `StateBox.value.didSet` calls `renderCache.clearAll()` |
| Environment change | `RenderLoop` compares an `EnvironmentSnapshot` (palette ID + appearance ID) each frame and clears on mismatch |

Between these events — for example during Spinner animation frames at 25 FPS — the cache is fully active. Static subtrees are rendered once and reused for every subsequent frame.

### When to Use `.equatable()`

| Good candidates | Why |
|----------------|-----|
| Static display views (labels, headers, feature boxes) | Properties rarely change, body is rebuilt identically each frame |
| Complex container hierarchies | Many nested views that produce the same output |
| Views next to animated siblings | Spinner/Pulse re-renders the whole tree; static siblings benefit from caching |

| Bad candidates | Why |
|---------------|-----|
| Views that read `@State` directly | State lives in a reference-type box — the view struct compares as equal even when state changed |
| Views that change every frame | Cache overhead with no benefit |
| Tiny views (single `Text`) | Rendering cost is already minimal |

### Which Types Support `.equatable()`

The following types have `Equatable` conformance, enabling `.equatable()` on views composed of them:

**Leaf views:** ``Text``

**Container views** (conditional: `where Content: Equatable`): `VStack`, `HStack`, `ZStack`, ``Box``, ``Panel``, ``Card``, ``Dialog``, `ContainerView`, ``BorderedView``

**Modifier views** (conditional): `FlexibleFrameView`, `OverlayModifier`, `DimmedModifier`

**Supporting types:** `TextStyle`, `Alignment`, `ContainerConfig`, `ContainerStyle`

> Note: `Button` cannot be `Equatable` because it stores a closure (`action: () -> Void`). Views containing buttons are not candidates for `.equatable()`.

### Debug Logging

Set `TUIKIT_DEBUG_RENDER=1` to enable per-frame cache statistics on stderr:

```
[RenderCache] STORE Root/MainMenuPage/FeatureBox
[RenderCache] HIT Root/MainMenuPage/FeatureBox
[RenderCache] MISS (no entry) Root/SpinnersPage/Spinner
[RenderCache] FRAME — hits: 3, misses: 2, stores: 2, clears: 0, entries: 3, hit rate: 60%
```

Redirect with `2>render.log` to capture without interfering with the TUI.
