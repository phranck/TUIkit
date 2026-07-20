# App Lifecycle

Understand how a TUIkit application starts, runs, and shuts down.

## Overview

A TUIkit application follows a linear lifecycle: **launch → setup → initial
render → async event loop → cleanup**. The framework handles terminal
configuration, signal handling, and the render-input cycle so you can focus on
building views.

## Entry Point

Every TUIkit application starts with a type conforming to ``App``, annotated with `@main`:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello, TUIkit!")
        }
    }
}
```

The `@main` attribute tells Swift to call the static `main()` method provided by the ``App`` protocol. This method:

1. Creates an instance of your app via its parameterless `init()`
2. Creates an internal `AppRunner` that owns all subsystems
3. Calls `run()` to enter the main loop

```
@main → App.main() → Self() → AppRunner(app:) → run()
```

## Subsystem Initialization

`AppRunner.init()` creates a terminal session, a signal manager, and one
`TUIContext`. The context is the sole owner of the application's mutable runtime
services. `run()` then creates the session components that consume those services:
`InputHandler`, `RenderLoop`, `RuntimeEventChannel`, input and signal sources,
and `RuntimeAnimationScheduler`. `PulseTimer` and `CursorTimer` derive visual
phases from the runtime clock; they do not own background timers.

```
AppRunner
├── Terminal session
├── SignalManager
└── TUIContext
    ├── AppState, StateStorage, RenderCache
    ├── LifecycleManager, KeyEventDispatcher, PreferenceStorage
    ├── LocalizationService, NotificationService, StorageBackend, RuntimeClock
    ├── FocusManager, palette and appearance managers
    ├── StatusBarState, AppHeaderState
    └── ImageLoader, URLImageCache
```

`AppRunner` owns the session. `TUIContext` owns the view-facing runtime services.
Dependencies flow through constructor injection and ``EnvironmentValues`` inside
``RenderContext``. The render context itself never owns or accesses a terminal.

## Terminal Setup

Before the main loop starts, `run()` prepares the terminal:

| Step | What | Why |
|------|------|-----|
| 1 | Install dispatch signal sources | Deliver SIGINT, SIGTERM, and SIGWINCH as runtime events |
| 2 | Start the input source | Deliver descriptor readiness without polling |
| 3 | Enter alternate screen | Preserve the user's existing terminal content |
| 4 | Hide cursor | Avoid cursor flicker during rendering |
| 5 | Enable raw mode | Disable line buffering, echo, and terminal signal processing |
| 6 | Register state observer | Send `.renderRequested` when `AppState` changes |
| 7 | Register focus observer | Reset the pulse phase and request a render |
| 8 | Initialize animation phase clocks | Establish monotonic phase origins without starting timers |
| 9 | Render first frame | Show the initial UI immediately |

### Raw Mode

In raw mode, the terminal delivers every keystroke immediately without waiting for Enter. TUIkit configures:

- **No echo**: typed characters are not displayed
- **No canonical mode**: input is byte-by-byte, not line-by-line
- **No signal processing**: Ctrl+C is handled by TUIkit, not the OS
- **Non-blocking reads**: input is drained only after the descriptor becomes readable

The original terminal settings are saved and restored during cleanup.

## Main Loop

The main loop is asynchronous. It awaits the next runtime event instead of
polling, and processes one event at a time:

| Event | Runtime action |
|-------|----------------|
| `.renderRequested` | Render if `AppState` still needs a frame |
| `.inputAvailable` | Drain and dispatch a bounded batch of key events |
| `.terminalResized` | Invalidate the terminal diff cache and render |
| `.animationDeadline` | Render the next visible focus-animation phase |
| `.shutdownRequested` | Leave the loop and begin cleanup |

When no event or animation deadline is pending, the task remains suspended and
the idle application does not wake periodically.

### Re-render Triggers

Several sources cause a new frame to be rendered through the runtime event
channel:

| Trigger | Path | Runtime event |
|---------|------|---------------|
| SIGWINCH | `DispatchSourceSignal` | `.terminalResized` |
| @State mutation | Owning runtime invalidates its subtree and notifies `AppState` | `.renderRequested` |
| Focus animation deadline | `RuntimeAnimationScheduler` | `.animationDeadline` |
| View-owned animation | Invalidates `AppState` | `.renderRequested` |
| Focus change | Resets pulse phase and invalidates `AppState` | `.renderRequested` |

The actual rendering always happens on the main actor. Event producers never
render directly.

## Signal Handling

`SignalManager` installs dispatch-backed sources for three POSIX signals:

| Signal | Trigger | Effect |
|--------|---------|--------|
| `SIGINT` | Ctrl+C | Sends `.shutdownRequested` |
| `SIGTERM` | Process termination request | Sends `.shutdownRequested` |
| `SIGWINCH` | Terminal resize | Sends `.terminalResized` |

No POSIX handler mutates Swift global state. Dispatch bridges delivery into the
runtime channel, where the events are serialized with state, input, rendering,
and shutdown.

## Key Event Dispatch

When the terminal delivers a key event, the `InputHandler` dispatches it through five layers. Layer 0 and Layer 3 are mutually exclusive based on `focusManager.hasTextInputFocus`:

### Layer 0: Text Input (conditional)

When a text input element (TextField/SecureField) is focused, `focusManager.dispatchKeyEvent()` runs first. This ensures printable characters, backspace, delete, arrows, home, end, and enter reach the text field before any other layer. Only keys the text field does not consume (Escape, Tab, unhandled Ctrl+shortcuts) fall through.

### Layer 1: Status Bar Items

``StatusBarState`` checks if any status bar item matches the key. Items can match single characters, special keys (Escape, Enter), or arrow keys. If a match is found, the item's action runs and dispatch stops.

### Layer 2: View-Registered Handlers

The `KeyEventDispatcher` iterates handlers registered via `onKeyPress()` modifiers: in reverse order (newest first). If a handler returns `true`, dispatch stops.

### Layer 3: Focus System (conditional)

Skipped when text input has focus (Layer 0 already ran). Otherwise, `focusManager.dispatchKeyEvent()` first delegates to the focused element's `handleKeyEvent()`, then handles Tab/Shift+Tab for focus cycling, then arrow keys as section navigation fallback.

### Layer 4: Default Bindings

Built-in key bindings that apply when no handler consumed the event:

| Key | Action | Condition |
|-----|--------|-----------|
| `q` / `Q` | Quit application | `statusBar.isQuitAllowed` |
| `t` / `T` | Cycle to next palette | `statusBar.showThemeItem` |
| `a` / `A` | Cycle to next appearance | Always |

## Render Pipeline

Each frame follows 12 steps inside `RenderLoop.render()`:

| Step | What |
|------|------|
| 1 | Clear per-frame state (key handlers, preferences, focus, status bar, app header) |
| 2 | Begin lifecycle, state, and cache tracking |
| 3 | Build ``EnvironmentValues`` from subsystem state |
| 4 | Create ``RenderContext`` with layout constraints |
| 5 | Evaluate `app.body` → ``WindowGroup`` |
| 6 | Render view tree → ``FrameBuffer`` |
| 7 | Build terminal-ready output lines |
| 8 | Begin buffered frame (`Terminal.beginFrame()`) |
| 9 | Render app header, diff and write only changed content lines |
| 10 | Render status bar into same buffer |
| 11 | Flush the buffered frame, normally with one `write()` syscall (`Terminal.endFrame()`) |
| 12 | End lifecycle tracking (fires `onDisappear` for removed views) |

Steps 8–11 are the output optimization layer: line-level diffing reduces writes
by ~94% for static UIs, and frame buffering normally reduces the frame flush to
one syscall while still retrying interrupted or partial writes.

> For full details on each step, see <doc:RenderCycle>.

## Cleanup

When the event loop exits via a signal, the quit key, programmatic shutdown, or
a surfaced terminal I/O failure, the runtime first stops its event sources and
then restores the terminal:

| Step | What | Why |
|------|------|-----|
| 1 | Stop animation, input, and signal sources | Prevent new runtime work |
| 2 | Finish the event channel | Resume and terminate pending consumers |
| 3 | Disable raw mode | Restore original terminal settings |
| 4 | Show cursor | Make the cursor visible again |
| 5 | Exit alternate screen | Restore the user's previous terminal content |
| 6 | Clear state observers | Remove `AppState` observer callbacks |
| 7 | Clear focus | Remove all focus registrations |
| 8 | Reset TUIContext | Cancel view tasks and clear runtime state, handlers, caches, notifications, and focus; synchronize app storage |

The `Terminal` class also has a `deinit` safety net that disables raw mode if it was not explicitly restored.

## Subsystem Dependency Graph

### Ownership

`AppRunner` owns the terminal and signals. Its single `TUIContext` owns every
mutable runtime service used by the view tree. A second runner receives a second
context, so neither application can invalidate or reuse the other's state,
caches, focus, localization, notifications, storage, or image requests.

### Runtime References

During each frame, `RenderLoop` obtains a complete environment from `TUIContext`,
renders into a ``FrameBuffer``, then writes that buffer through the injected
terminal session. `InputHandler` receives the same context-owned focus, status
bar, key dispatch, palette, and appearance services. Runtime events and
animation deadlines remain scoped to that runner.
