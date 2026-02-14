# App Lifecycle

Understand how a TUIkit application starts, runs, and shuts down.

## Overview

A TUIkit application follows a linear lifecycle: **launch → setup → main loop → cleanup**. The framework handles terminal configuration, signal handling, and the render-input cycle so you can focus on building views.

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

`AppRunner.init()` creates and wires the core subsystems: Terminal, AppState, StatusBarState, AppHeaderState, FocusManager, TUIContext (containing LifecycleManager, KeyEventDispatcher, PreferenceStorage, StateStorage, and RenderCache), and two ThemeManagers (palette and appearance). `run()` then creates the remaining runtime components: InputHandler, RenderLoop, PulseTimer (100 ms), and CursorTimer (50 ms).

@Image(source: "lifecycle-subsystem-init.png", alt: "Diagram showing subsystem initialization: @main calls App.main(), which creates the app instance via Self(), then AppRunner.init() creates Terminal, AppState, StatusBarState, AppHeaderState, FocusManager, TUIContext with 5 children (LifecycleManager, KeyEventDispatcher, PreferenceStorage, StateStorage, RenderCache), and two ThemeManagers. run() then creates InputHandler, RenderLoop, PulseTimer (100ms), and CursorTimer (50ms).")

The `AppRunner` is the sole owner of all subsystems. Dependencies flow through constructor injection and ``RenderContext``.

## Terminal Setup

Before the main loop starts, `run()` prepares the terminal:

| Step | What | Why |
|------|------|-----|
| 1 | Install signal handlers | Catch Ctrl+C (SIGINT) and terminal resize (SIGWINCH) |
| 2 | Enter alternate screen | Preserve the user's existing terminal content |
| 3 | Hide cursor | Avoid cursor flicker during rendering |
| 4 | Enable raw mode | Disable line buffering, echo, and signal processing |
| 5 | Register state observer | `AppState` changes trigger re-renders via `signals.requestRerender()` |
| 6 | Register focus observer | Focus changes reset the pulse timer and trigger re-renders |
| 7 | Start timers | PulseTimer (100 ms) and CursorTimer (50 ms) for animations |
| 8 | Render first frame | Show the initial UI immediately |

### Raw Mode

In raw mode, the terminal delivers every keystroke immediately without waiting for Enter. TUIkit configures:

- **No echo**: typed characters are not displayed
- **No canonical mode**: input is byte-by-byte, not line-by-line
- **No signal processing**: Ctrl+C is handled by TUIkit, not the OS
- **100ms read timeout**: non-blocking input polling

The original terminal settings are saved and restored during cleanup.

## Main Loop

The main loop is synchronous and runs until shutdown:

@Image(source: "lifecycle-main-loop.png", alt: "Flowchart of the main loop: run() performs terminal setup, registers observers, starts timers, renders first frame, then loops checking shouldShutdown, consumeResizeFlag to invalidate diff cache, rerenderFlag or needsRender to conditionally render, reads key events non-blocking up to 128 per frame, dispatches through 5 layers, and sleeps 28ms. On shouldShutdown, cleanup restores the terminal and exits.")

### Re-render Triggers

Several sources cause a new frame to be rendered, all converging on two boolean checks in the main loop:

| Trigger | Path | Main loop check |
|---------|------|-----------------|
| SIGWINCH | Sets `signalNeedsRerender` + `signalTerminalResized` | `consumeRerenderFlag()` |
| @State mutation | `AppState` observer calls `signals.requestRerender()` | `consumeRerenderFlag()` |
| PulseTimer / CursorTimer | Calls `appState.setNeedsRender()` | `appState.needsRender` |
| Focus change | Calls `appState.setNeedsRender()` | `appState.needsRender` |

All triggers set boolean flags. The actual rendering always happens on the main thread: signal handlers never render directly.

## Signal Handling

`SignalManager` installs two POSIX signal handlers:

| Signal | Trigger | Effect |
|--------|---------|--------|
| `SIGINT` | Ctrl+C | Sets a shutdown flag → main loop exits |
| `SIGWINCH` | Terminal resize | Sets a re-render flag → next iteration re-renders |

Signal handlers only set `nonisolated(unsafe)` boolean flags: no allocations, no locks. The main loop reads these flags each iteration and acts accordingly.

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
| 11 | Flush entire frame in one `write()` syscall (`Terminal.endFrame()`) |
| 12 | End lifecycle tracking (fires `onDisappear` for removed views) |

Steps 8–11 are the output optimization layer: line-level diffing reduces writes by ~94% for static UIs, and frame buffering reduces syscalls from ~40+ to exactly 1.

> For full details on each step, see <doc:RenderCycle>.

## Cleanup

When the main loop exits: via Ctrl+C, the quit key, or programmatic shutdown: `cleanup()` restores the terminal:

| Step | What | Why |
|------|------|-----|
| 1 | Disable raw mode | Restore original terminal settings |
| 2 | Show cursor | Make the cursor visible again |
| 3 | Exit alternate screen | Restore the user's previous terminal content |
| 4 | Clear state observers | Remove `AppState` observer callbacks |
| 5 | Clear focus | Remove all focus registrations |
| 6 | Reset TUIContext | Clear lifecycle, key handlers, and preferences |

The `Terminal` class also has a `deinit` safety net that disables raw mode if it was not explicitly restored.

## Subsystem Dependency Graph

### Ownership

AppRunner creates and owns every subsystem. TUIContext acts as a secondary container for lifecycle, key dispatch, and preference storage.

@Image(source: "dep-graph-ownership.png", alt: "Ownership diagram showing AppRunner owning all subsystems: SignalManager, Terminal, AppState, StatusBarState, AppHeaderState, FocusManager, both ThemeManagers, TUIContext, InputHandler, RenderLoop, PulseTimer, and CursorTimer. TUIContext contains LifecycleManager, KeyEventDispatcher, PreferenceStorage, StateStorage, and RenderCache. SignalManager sends SIGINT and SIGWINCH flags back to AppRunner.")

### Runtime References

During each frame, RenderLoop and InputHandler reference shared subsystems to build the environment and dispatch key events.

@Image(source: "dep-graph-references.png", alt: "Runtime reference diagram showing RenderLoop writing output to Terminal, injecting environment values from StatusBarState, AppHeaderState, FocusManager, and both ThemeManagers, calling begin/end pass on LifecycleManager, StateStorage, and RenderCache, begin pass on PreferenceStorage, and clearing handlers on KeyEventDispatcher. InputHandler dispatches through Layer 0+3 FocusManager, Layer 1 StatusBarState, Layer 2 KeyEventDispatcher, and Layer 4 both ThemeManagers.")
