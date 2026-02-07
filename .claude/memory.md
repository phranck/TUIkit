# TUIKit Memory

## Project

**Name:** TUIKit
**Purpose:** Terminal UI framework for Swift (SwiftUI-inspired)
**Repo:** github.com/phranck/TUIkit
**Docs:** tuikit.layered.work

## Compatibility

- Swift 6.0 (`swift-tools-version: 6.0`)
- Cross-platform: macOS + Linux
- CI: `macos-15` + `swift:6.0` container

## Package Structure

```
TUIKit/
├── Sources/TUIkit/          # Main library
├── Sources/TUIkitExample/   # Demo app
├── Tests/TUIkitTests/       # Swift Testing
├── docs/                    # Astro site + DocC
└── plans/                   # Feature plans
```

## Architecture Rules (Non-Negotiable)

### SwiftUI API Parity
- Parameter names: exact match (`isPresented` not `isVisible`)
- Parameter order: exact match
- Parameter types: `@ViewBuilder` closures, not pre-built values
- Look up SwiftUI signature before implementing

### View Architecture
- Everything visible = `View` protocol
- Never expose `Renderable` to users
- Modifiers must work: `.foregroundColor()`, `.disabled()`
- Environment values must propagate

### Code Reuse
- Search codebase before implementing anything new
- Extend existing patterns, don't reinvent
- No singletons

## Core Abstractions

### View / Renderable Duality

```
User Code                    Framework Internal
─────────                    ──────────────────
struct MyView: View          extension MyView: Renderable
  var body: some View          func renderToBuffer(context:)
```

`renderToBuffer(_:context:)` free function:
- If `Renderable`: call `renderToBuffer` directly
- Else: recursively render `body`

### Actor Isolation

| Scope | Isolation |
|-------|-----------|
| View, ViewModifier, Renderable | `@MainActor` |
| App, Scene | `@MainActor` |
| All builders | `@MainActor` |
| Terminal, FocusManager | `@MainActor` |
| Cross-thread state | `Lock<State>` wrapper |

## Directory Map

| Directory | Purpose |
|-----------|---------|
| `App/` | App, Scene, AppRunner, SignalManager, PulseTimer |
| `Core/` | KeyEvent, Key, Lock, Binding, ViewIdentity |
| `Environment/` | EnvironmentValues, EnvironmentKey, TUIContext |
| `Focus/` | FocusManager, Focusable, ActionHandler, FocusSection |
| `Modifiers/` | All ViewModifier implementations |
| `Rendering/` | Terminal, TerminalProtocol, FrameBuffer, RenderCache |
| `State/` | @State, StateStorage, StateBox, AppState |
| `StatusBar/` | StatusBarState, StatusBarItem, StatusBarStyle |
| `Styling/` | Color, Palette, Appearance, ThemeManager |
| `Views/` | All View implementations |
| `ViewBuilder/` | @ViewBuilder, SceneBuilder, result builders |

## Key Protocols

| Protocol | Purpose | Key Requirement |
|----------|---------|-----------------|
| `View` | User-facing component | `var body: some View` |
| `Renderable` | Internal rendering | `func renderToBuffer(context:) -> FrameBuffer` |
| `Focusable` | Keyboard focus | `func handleKeyEvent(_:) -> Bool` |
| `ViewModifier` | View transformation | `func body(content:) -> some View` |
| `TerminalProtocol` | Terminal abstraction | `func write(_:)`, `func readKeyEvent()` |

## Key Classes

| Class | Purpose |
|-------|---------|
| `Terminal` | Raw terminal I/O, frame buffering |
| `FocusManager` | Section-based focus, keyboard dispatch |
| `StateStorage` | @State persistence across renders |
| `AppState` | Thread-safe render trigger |
| `RenderCache` | Subtree memoization for `.equatable()` |
| `ActionHandler` | Reusable Focusable for Button/Toggle |
| `ItemListHandler` | Shared handler for List/Table (planned) |

## Views

| View | Purpose |
|------|---------|
| `Text` | Styled text |
| `Button` | Action trigger, focusable |
| `Toggle` | Boolean switch (slider/checkbox) |
| `RadioButtonGroup` | Single-select options |
| `Box` | Bordered container |
| `VStack/HStack/ZStack` | Layout |
| `Spacer` | Flexible space |
| `Divider` | Horizontal line |
| `Spinner` | Loading indicator |
| `ProgressView` | Progress bar |
| `ForEach` | Collection iteration |

## Modifiers

| Modifier | Effect |
|----------|--------|
| `.foregroundColor(_:)` | Text/border color |
| `.bold()` / `.dim()` | Text weight |
| `.padding(_:)` | Edge insets |
| `.frame(width:height:)` | Fixed dimensions |
| `.border(_:color:)` | Add border via ContainerView |
| `.disabled(_:)` | Disable interaction |
| `.overlay(_:)` | Overlay content |
| `.focusSection(_:)` | Named focus region |
| `.equatable()` | Enable render caching |

## Patterns

### New View (Simple)
```swift
public struct MyView: View {
    let title: String
    public var body: some View { Text(title) }
}
```

### New View (Complex Rendering)
```swift
public struct MyView: View {
    let title: String
    public var body: Never { fatalError() }
}

extension MyView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Direct rendering
    }
}
```

### New Focusable View
```swift
final class MyHandler: Focusable {
    let focusID: String
    var canBeFocused: Bool = true
    
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        switch event.key {
        case .enter: action(); return true
        default: return false
        }
    }
}

// In renderToBuffer:
let storage = context.tuiContext.stateStorage
let key = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
let box: StateBox<MyHandler> = storage.storage(for: key, default: MyHandler(...))
context.environment.focusManager.register(box.value, inSection: context.activeFocusSectionID)
storage.markActive(context.identity)
```

### Keyboard Navigation
- Handler's `handleKeyEvent` called first
- Return `true` to consume (stop propagation)
- Return `false` for FocusManager fallback
- FocusManager: Tab = sections, Up/Down = within section

## Rendering Pipeline

```
AppRunner.run()
  ├─ Terminal setup (raw mode, alternate screen)
  └─ Main loop (40ms tick, ~25 FPS)
       ├─ Check signals (SIGWINCH, SIGINT)
       ├─ appState.needsRender?
       │    └─ RenderLoop.render(pulsePhase)
       │         ├─ focusManager.beginRenderPass()
       │         ├─ renderToBuffer(scene, context)
       │         ├─ focusManager.endRenderPass()
       │         └─ FrameDiffWriter.write(buffer)
       └─ terminal.readKeyEvent()
            └─ inputHandler.handle(event)
```

## Current State

**Branch:** `main`
**Tests:** 590 / 94 suites
**Build:** clean
**Lint:** 0 serious

### Recent (Feb 2026)
- Swift 6 Concurrency complete (Phases 1-7)
- TerminalProtocol + MockTerminal
- ActionHandler (consolidated Button/Toggle)
- Astro docs migration

### Next
- List component (uses ItemListHandler)
- Table component (shares ItemListHandler)
- TextInput / TextField

---

**Last Updated:** 2026-02-07
