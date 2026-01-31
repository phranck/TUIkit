# Render Cycle

Understand how TUIkit turns your view tree into terminal output — one frame at a time.

## Overview

Every frame in TUIkit follows the same synchronous pipeline: **clear per-frame state → build environment → render the view tree → track lifecycle → render the status bar**. There is no double buffering, no async scheduling, and no diffing — each frame is a full top-to-bottom traversal that writes directly to the terminal.

## What Triggers a Frame

Three things cause `RenderLoop` to produce a new frame:

| Trigger | Source | Mechanism |
|---------|--------|-----------|
| Terminal resize | `SIGWINCH` signal | `SignalManager` sets a boolean flag |
| State mutation | `@State` property change | ``AppState`` notifies its observer, which sets the rerender flag |
| Programmatic | `AppState.active.setNeedsRender()` | Same observer path as above |

All triggers converge on boolean flags that the main loop checks each iteration. The actual rendering always happens on the main thread — signal handlers never render directly.

## The Render Pipeline

Each call to `RenderLoop.render()` executes these steps in order:

@Image(source: "render-cycle-pipeline.png", alt: "Diagram showing the 8-step render pipeline: clear per-frame state, begin lifecycle tracking, build environment, create render context, evaluate scene, render view tree, end lifecycle tracking, render status bar.")

### Step 1: Clear Per-Frame State

Three subsystems are reset at the start of every frame:

- **``KeyEventDispatcher``** — All key handlers are removed. Views re-register them during rendering via `onKeyPress()` modifiers.
- **``PreferenceStorage``** — All preference callbacks are cleared and the stack is reset to a single empty `PreferenceValues`.
- **``FocusManager``** — All focus registrations are cleared. Focusable views re-register during rendering.

This ensures that views which disappeared between frames don't leave stale handlers or registrations behind.

### Step 2: Begin Lifecycle Tracking

The ``LifecycleManager`` prepares for a new frame by clearing its `currentRenderTokens` set. As views render, they add their tokens to this set. After rendering, the manager compares it to the previous frame's tokens to detect which views appeared or disappeared.

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

This environment is immutable for the frame — no global state, no singletons.

### Step 4: Create Render Context

A ``RenderContext`` bundles everything a view needs to render:

| Property | What |
|----------|------|
| `terminal` | The ``Terminal`` instance for size queries |
| `availableWidth` | Terminal width (mutable — containers reduce this for children) |
| `availableHeight` | Terminal height minus status bar (mutable) |
| `environment` | The ``EnvironmentValues`` from step 3 |
| `tuiContext` | The ``TUIContext`` (lifecycle, key dispatch, preferences) |

The context is passed down the view tree. Each view can create a modified copy for its children — for example, a border reduces `availableWidth` by 2 before rendering its content.

### Step 5: Evaluate Scene

`app.body` is called, producing a ``WindowGroup`` that wraps the root view. The `WindowGroup` implements `SceneRenderable` and bridges from the scene layer to the view layer.

### Step 6: Render View Tree

This is where the dual rendering system kicks in. ``WindowGroup`` calls the free function `renderToBuffer()` on its content, which recursively traverses the entire view tree and produces a ``FrameBuffer``.

The buffer lines are then written to the terminal row by row — each line padded to full terminal width with a persistent background color.

> See <doc:RenderCycle#The-Dual-Rendering-System> below for details on how views are dispatched.

### Step 7: End Lifecycle Tracking

The ``LifecycleManager`` compares the current frame's tokens with the previous frame's:

- **Disappeared views** — tokens present last frame but absent now. Their `onDisappear` callbacks fire, and their tokens are removed from the appeared set (allowing future `onAppear` if they return).
- **Visible views** — the current token set becomes the baseline for the next frame.

All state changes inside the lifecycle manager are `NSLock`-protected. Callbacks execute **outside** the lock to prevent deadlocks.

### Step 8: Render Status Bar

The status bar renders in a completely separate pass:

1. A ``StatusBar`` view is created with resolved palette colors
2. A dedicated ``RenderContext`` is created with `availableHeight` set to the status bar's height
3. `renderToBuffer()` runs on the status bar view — same dispatch as the main content
4. The buffer is written starting at row `terminal.height - statusBarHeight + 1`

The status bar is **never affected** by view dimming or overlays. It always renders last, at the bottom of the terminal.

## The Dual Rendering System

TUIkit has two ways for a view to produce output:

### Path 1: Direct Rendering (Renderable)

Views that conform to ``Renderable`` implement `renderToBuffer(context:)` and produce a ``FrameBuffer`` directly. Their `body` property is **never called**.

This path is used by:
- **Leaf views** — ``Text``, ``Spacer``, `Divider`, ``EmptyView``
- **Layout containers** — `VStack`, `HStack`, `ZStack`
- **Interactive views** — ``Button``, ``ButtonRow``, ``Menu``
- **Container views** — ``Panel``, ``Card``, ``Alert``, ``Dialog``
- **Modifier wrappers** — `ModifiedView`, `BorderedView`, `DimmedModifier`, `OverlayModifier`, `EnvironmentModifier`, and all lifecycle modifiers

### Path 2: Composition (body)

Views that are **not** `Renderable` declare their content through `body`. The rendering system recursively renders the body until it hits a `Renderable` leaf.

This path is used by:
- **Composite views** — ``Box`` returns `content.border(...)`, which wraps in a `BorderedView` (which is `Renderable`)
- **User-defined views** — Your custom views compose other views in `body`

### The Dispatch Function

The free function `renderToBuffer()` is the single entry point for all view rendering:

```swift
public func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    // Priority 1: Direct rendering
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    }

    // Priority 2: Composite — recurse into body
    if V.Body.self != Never.self {
        return renderToBuffer(view.body, context: context)
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

### Writing to Terminal

``WindowGroup`` iterates over the buffer and writes each line to the terminal:

1. Lines with content get their ANSI reset codes replaced with `reset + backgroundColor` (persistent background)
2. Each line is padded to full terminal width
3. Empty lines are filled with the background color
4. `Terminal.moveCursor()` + `Terminal.write()` per line

## Environment Flow

Environment values flow **top-down** through the render tree via ``RenderContext``:

```
RenderLoop.buildEnvironment()
  → RenderContext carries EnvironmentValues
    → EnvironmentModifier creates a copy with modified value
      → Children see the modified value
    → Siblings and parents see the original (copy semantics)
```

The ``EnvironmentModifier`` (created by `.environment(_:_:)`) works by:

1. Creating a new `EnvironmentValues` with the modified key
2. Creating a new `RenderContext` with that environment via `context.withEnvironment()`
3. Rendering its content with the new context

There is no global environment — everything flows through the context parameter.

## Preference Collection

Preferences flow **bottom-up** — the reverse of environment values. Child views set values that parent views observe.

``PreferenceStorage`` uses a stack-based collection mechanism:

1. ``OnPreferenceChangeModifier`` calls `push()` — creates a new collection scope
2. Its child tree renders, and ``PreferenceModifier`` calls `setValue()` on the current scope
3. ``OnPreferenceChangeModifier`` calls `pop()` — merges collected values into the parent scope and fires the callback

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

- **`BorderedView`** — Reduces `availableWidth` by 2, renders content, adds border characters via ``BorderRenderer``
- **`FlexibleFrameView`** — Modifies `availableWidth`/`availableHeight` before rendering, applies min/max constraints and alignment after
- **`OverlayModifier`** — Renders base and overlay separately, composites via `FrameBuffer.composited(with:at:)`
- **`DimmedModifier`** — Renders content, then applies ANSI dim code to every line
- **`EnvironmentModifier`** — Creates modified context, renders content with it

## Lifecycle Tracking

The ``LifecycleManager`` tracks view visibility across frames using unique tokens (UUIDs):

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

## Why No Double Buffer

TUIkit writes each frame directly to the terminal — there is no previous-frame comparison or minimal-update optimization. This is intentional:

1. **Terminal rendering is fast** — ANSI writes are cheap for typical TUI sizes (< 200×60 characters)
2. **No layout diffing needed** — the view tree is fully re-evaluated each frame, so there's nothing to diff against
3. **Simplicity** — single-pass rendering eliminates entire categories of bugs (stale state, partial updates, layout thrashing)

The alternate screen buffer (entered during setup) ensures that the user's previous terminal content is preserved and restored on exit.
