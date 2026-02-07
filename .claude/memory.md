# TUIKit: Project Memory

## Project Overview

**Name:** TUIKit
**Purpose:** Terminal UI framework for Swift, inspired by SwiftUI
**Language:** Swift 6.0, cross-platform (macOS + Linux)
**Package:** Swift Package (`Package.swift`)
**Repo:** github.com/phranck/TUIkit
**Docs:** tuikit.layered.work (Astro + DocC)

### Key Dependencies
- Swift 6.0 (`swift-tools-version: 6.0`)
- swift-docc-plugin (documentation)
- No external runtime dependencies

### Targets
| Target | Type | Purpose |
|--------|------|---------|
| TUIkit | Library | Main framework |
| TUIkitExample | Executable | Demo app |
| TUIkitTests | Tests | 590+ tests, Swift Testing |

---

## Architecture

### Core Pattern: View / Renderable Duality

```
View (protocol)                 Renderable (protocol)
  ├─ body: some View              ├─ renderToBuffer(context:) -> FrameBuffer
  └─ User-facing API              └─ Internal rendering
         │                                 │
         └──────────┬──────────────────────┘
                    ▼
           renderToBuffer(_:context:) [free function]
           - If Renderable: call renderToBuffer directly
           - Else: recursively render body
```

All visible components are `View`. Complex rendering uses `Renderable` extension.

### Actor Isolation

- `@MainActor` on: View, ViewModifier, Renderable, App, Scene protocols
- All builders: `@MainActor`
- Terminal operations: `@MainActor` isolated
- Cross-thread: `Lock<State>` wrapper (OSAllocatedUnfairLock/NSLock)

### Directory Structure

```
Sources/TUIkit/
├── App/           # App, Scene, AppRunner, SignalManager, PulseTimer
├── Core/          # KeyEvent, Lock, Binding, ViewIdentity
├── Environment/   # EnvironmentValues, TUIContext, Preferences
├── Focus/         # FocusManager, Focusable, ActionHandler, FocusSection
├── Modifiers/     # ViewModifier implementations
├── Rendering/     # Terminal, FrameBuffer, ViewRenderer, RenderCache
├── State/         # @State, StateStorage, StateBox, AppState
├── StatusBar/     # StatusBarState, StatusBarItem
├── Styling/       # Color, Palette, Appearance, ThemeManager
├── Views/         # All View implementations
└── ViewBuilder/   # @ViewBuilder, result builders
```

---

## Key Types Reference

### Protocols

| Protocol | File | Purpose |
|----------|------|---------|
| `View` | View.swift | User-facing component, has `body: some View` |
| `Renderable` | Renderable.swift | Internal rendering, `renderToBuffer(context:)` |
| `Focusable` | Focus.swift | Keyboard focus, `handleKeyEvent(_:) -> Bool` |
| `App` | App.swift | Application entry point |
| `Scene` | Scene.swift | Top-level scene container |
| `ViewModifier` | ViewModifier.swift | View transformation |
| `TerminalProtocol` | TerminalProtocol.swift | Terminal abstraction for testing |

### Core Classes

| Class | File | Purpose |
|-------|------|---------|
| `Terminal` | Terminal.swift | Raw terminal I/O, frame buffering |
| `FocusManager` | Focus.swift | Section-based focus, keyboard dispatch |
| `StateStorage` | StateStorage.swift | @State persistence across renders |
| `AppState` | State.swift | Render trigger, thread-safe needsRender |
| `TUIContext` | TUIContext.swift | Per-app context container |
| `RenderCache` | RenderCache.swift | Subtree memoization |
| `ThemeManager` | ThemeManager.swift | Palette/Appearance cycling |

### Views

| View | File | Purpose |
|------|------|---------|
| `Text` | Text.swift | Styled text output |
| `Button` | Button.swift | Focusable action trigger |
| `Toggle` | Toggle.swift | Boolean switch (slider/checkbox) |
| `RadioButtonGroup` | RadioButton.swift | Single-select from options |
| `Box` | Box.swift | Bordered container |
| `VStack/HStack/ZStack` | Stacks.swift | Layout containers |
| `Spacer` | Spacer.swift | Flexible space |
| `Divider` | Divider.swift | Horizontal line |
| `Spinner` | Spinner.swift | Loading indicator |
| `ProgressView` | ProgressView.swift | Progress bar |
| `ForEach` | ForEach.swift | Collection iteration |
| `ContainerView` | ContainerView.swift | Internal bordered container |

### Modifiers

| Modifier | Purpose |
|----------|---------|
| `.foregroundColor(_:)` | Text/border color |
| `.bold()` / `.dim()` | Text weight |
| `.padding(_:)` | Edge insets |
| `.frame(width:height:)` | Fixed dimensions |
| `.border(_:color:)` | Add border |
| `.disabled(_:)` | Disable interaction |
| `.overlay(_:)` | Overlay content |
| `.focusSection(_:)` | Named focus region |
| `.equatable()` | Enable render caching |

### Environment Keys

| Key | Type | Purpose |
|-----|------|---------|
| `foregroundColor` | Color? | Inherited text color |
| `palette` | Palette | Color theme |
| `appearance` | Appearance | Border/container style |
| `focusManager` | FocusManager | Focus state |
| `isEnabled` | Bool | Disabled state |

---

## Patterns & Conventions

### Adding a New View

1. Create `MyView.swift` in `Sources/TUIkit/Views/`
2. Struct conforming to `View`:
   ```swift
   public struct MyView: View {
       let title: String
       
       public init(title: String) { self.title = title }
       
       public var body: some View { Text(title) }
   }
   ```
3. For complex rendering, add `Renderable` extension:
   ```swift
   extension MyView: Renderable {
       func renderToBuffer(context: RenderContext) -> FrameBuffer { ... }
   }
   ```
4. Add tests in `Tests/TUIkitTests/MyViewTests.swift`

### Adding a Focusable View

1. Create handler class conforming to `Focusable`:
   ```swift
   final class MyHandler: Focusable {
       let focusID: String
       var canBeFocused: Bool
       func handleKeyEvent(_ event: KeyEvent) -> Bool { ... }
   }
   ```
2. In `renderToBuffer`:
   - Get handler from StateStorage (or create new)
   - Register with FocusManager
   - Check `focusManager.isFocused(id:)`
   - Mark state active

### State Persistence Pattern

```swift
func renderToBuffer(context: RenderContext) -> FrameBuffer {
    let storage = context.tuiContext.stateStorage
    let key = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
    let box: StateBox<MyHandler> = storage.storage(for: key, default: MyHandler())
    let handler = box.value
    
    // Sync mutable fields
    handler.canBeFocused = !isDisabled
    
    // Register and mark active
    context.environment.focusManager.register(handler, inSection: context.activeFocusSectionID)
    storage.markActive(context.identity)
    
    // Render...
}
```

### Keyboard Navigation

- Handler's `handleKeyEvent(_:)` is called first
- Return `true` to consume event (stops propagation)
- Return `false` to let FocusManager handle (Tab, arrows)
- FocusManager: Tab = next section, Up/Down = within section

### Testing Pattern

```swift
@MainActor
@Suite("MyView Tests")
struct MyViewTests {
    @Test("renders correctly")
    func basicRender() {
        let view = MyView(title: "Hello")
        let buffer = TestRenderer.render(view)
        #expect(buffer.contains("Hello"))
    }
}
```

---

## Rendering Pipeline

```
App.main()
    └── AppRunner.run()
            ├── Terminal setup (raw mode, alternate screen)
            ├── Main loop:
            │     ├── Check signals (resize, shutdown)
            │     ├── Check appState.needsRender
            │     ├── RenderLoop.render(pulsePhase:)
            │     │     ├── FocusManager.beginRenderPass()
            │     │     ├── ViewRenderer.render(scene)
            │     │     │     └── renderToBuffer(view, context)
            │     │     ├── FocusManager.endRenderPass()
            │     │     └── FrameDiffWriter.write(buffer)
            │     └── InputHandler.handle(keyEvent)
            └── Cleanup (restore terminal)
```

### Frame Buffering
- `Terminal.beginFrame()` / `endFrame()` collects writes
- Single `write()` syscall per frame
- `FrameDiffWriter` only writes changed lines

---

## Current State

**Branch:** `main`
**Tests:** 590 / 94 suites
**Build:** clean
**Lint:** 0 serious (1 file-length warning)

### Recent Changes (Feb 2026)
- Swift 6 Concurrency: @MainActor isolation complete
- TerminalProtocol: Testability abstraction
- ActionHandler: Consolidated Button/Toggle handlers
- Astro Migration: Docs site on Astro (was Next.js)
- Mobile Performance: Framer Motion removed, CSS animations

### Next Up
- TextInput / TextField component
- List & Table with shared ItemListHandler

---

**Last Updated:** 2026-02-07
