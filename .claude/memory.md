# TUIkit Memory

## Project Overview

**Name:** TUIkit
**Purpose:** Terminal UI framework for Swift (SwiftUI-inspired API)
**Repo:** github.com/phranck/TUIkit
**Docs:** tuikit.layered.work (Astro + DocC)

### Package Structure

```
TUIkit/
├── Sources/TUIkit/          # Main library
├── Sources/TUIkitExample/   # Demo app
├── Tests/TUIkitTests/       # Swift Testing (666 tests)
├── docs/                    # Astro site + DocC
├── xcode-template/          # Xcode project template
└── plans/                   # Feature plans
```

### Compatibility

- Swift 6.0 (`swift-tools-version: 6.0`)
- Cross-platform: macOS + Linux
- CI: `macos-15` + `swift:6.0` container

## Architecture

### 100% SwiftUI Conformity (NON-NEGOTIABLE)

**The Golden Rule:** Everything is a View with real `body: some View`.

```swift
// CORRECT - SwiftUI-conformant
public struct MyControl: View {
    public var body: some View {
        // Compose other Views
        // Environment flows automatically
        // Modifiers propagate correctly
    }
}

// WRONG - breaks modifier propagation
public struct MyControl: View {
    public var body: Never { fatalError() }
}
extension MyControl: Renderable { ... }
```

### Why This Matters

```swift
// This MUST work like SwiftUI:
List("Items", selection: $sel) {
    ForEach(items) { Text($0.name) }
}
.foregroundStyle(.red)  // Must affect all Text inside!
.disabled(true)         // Must disable entire List!
```

With `body: Never` + Renderable, modifiers don't propagate because the View tree is cut off.

### Renderable - When to Use

**ONLY for leaf nodes:**
- `Text` - renders styled string
- `Spacer` - renders empty space
- `Divider` - renders a line
- Internal helpers (`_ContainerViewCore`, `BufferView`)

**NEVER for:**
- Containers (List, Table, Card, Panel)
- Interactive controls (Button, Toggle, Menu)
- Composite views (RadioButtonGroup, ProgressView)

### View / Renderable Duality

```
User Code                    Framework Internal
─────────                    ──────────────────
struct MyView: View          
  var body: some View        (composes other Views)
      ↓
  internal _Core: View       extension _Core: Renderable
    var body: Never            func renderToBuffer(context:)
```

`renderToBuffer(_:context:)` free function:
- If `Renderable`: call `renderToBuffer` directly
- Else: recursively render `body` (environment propagates!)

### Actor Isolation

| Scope | Isolation |
|-------|-----------|
| View, ViewModifier, Renderable | `@MainActor` |
| App, Scene | `@MainActor` |
| All builders | `@MainActor` |
| Terminal, FocusManager | `@MainActor` |
| Cross-thread state | `Lock<State>` wrapper |

### Directory Map

| Directory | Purpose |
|-----------|---------|
| `App/` | App, Scene, AppRunner, SignalManager, PulseTimer |
| `Core/` | KeyEvent, Key, Lock, Binding, ViewIdentity |
| `Environment/` | EnvironmentValues, EnvironmentKey, TUIContext |
| `Focus/` | FocusManager, Focusable, ActionHandler, ItemListHandler |
| `Modifiers/` | All ViewModifier implementations |
| `Rendering/` | Terminal, TerminalProtocol, FrameBuffer, RenderCache |
| `State/` | @State, StateStorage, StateBox, AppState |
| `StatusBar/` | StatusBarState, StatusBarItem, StatusBarStyle |
| `Styling/` | Color, Palette, Appearance, ThemeManager |
| `Views/` | All View implementations |
| `ViewBuilder/` | @ViewBuilder, SceneBuilder, result builders |

## SwiftUI Patterns (Reference)

### Views vs Modifiers (from Swift by Sundell)

**Use Views (custom types) for:**
- Containers that wrap multiple children
- Structural changes to view hierarchy
- When it's clear content is being wrapped

**Use Modifiers for:**
- Styling (colors, fonts, padding)
- When the view's place in hierarchy doesn't change
- Transformations that apply to any view

```swift
// Container = View
SplitView(leading: { ... }, trailing: { ... })

// Styling = Modifier
Text("Hello").featured()  // adds icon + styling
```

### ViewBuilder Pattern

```swift
public struct MyContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    public var body: some View {
        VStack {
            content()
        }
    }
}
```

### ViewModifier with State

```swift
struct FeaturedModifier: ViewModifier {
    @State private var opacity = 0.0
    
    func body(content: Content) -> some View {
        HStack {
            Image(systemName: "star")
            content
        }
        .opacity(opacity)
        .onAppear { withAnimation { opacity = 1 } }
    }
}
```

### Type-Constrained Extensions

```swift
extension MyContainer where Content == Text {
    init(_ text: String) {
        self.init { Text(text) }
    }
}
```

## Key Types Reference

### Protocols

| Protocol | Purpose | Key Requirement |
|----------|---------|-----------------|
| `View` | User-facing component | `var body: some View` |
| `Renderable` | Internal rendering (leaf nodes only!) | `func renderToBuffer(context:) -> FrameBuffer` |
| `Focusable` | Keyboard focus | `func handleKeyEvent(_:) -> Bool` |
| `ViewModifier` | View transformation | `func modify(buffer:context:) -> FrameBuffer` |
| `Palette` | Color theme | foreground, background, accent, etc. |
| `TerminalProtocol` | Terminal abstraction | `func write(_:)`, `func readKeyEvent()` |

### Core Classes

| Class | Purpose |
|-------|---------|
| `Terminal` | Raw terminal I/O, frame buffering |
| `FocusManager` | Section-based focus, keyboard dispatch |
| `StateStorage` | @State persistence across renders |
| `AppState` | Thread-safe render trigger |
| `RenderCache` | Subtree memoization for `.equatable()` |
| `ActionHandler` | Reusable Focusable for Button/Toggle |
| `ItemListHandler` | Shared handler for List/Table navigation/selection |

### Views

| View | Purpose |
|------|---------|
| `Text` | Styled text (leaf) |
| `Button` | Action trigger, focusable |
| `Toggle` | Boolean switch (slider/checkbox) |
| `RadioButtonGroup` | Single-select options |
| `Box` | Bordered container (reference implementation!) |
| `List` | Scrollable list with selection |
| `Table` | Tabular data with columns |
| `VStack/HStack/ZStack` | Layout |
| `Spacer` | Flexible space (leaf) |
| `Divider` | Horizontal line |
| `Spinner` | Loading indicator |
| `ProgressView` | Progress bar (5 styles) |
| `ForEach` | Collection iteration |

### Modifiers

| Modifier | Effect |
|----------|--------|
| `.foregroundStyle(_:)` | Text/border color |
| `.bold()` / `.dim()` | Text weight |
| `.padding(_:)` | Edge insets |
| `.frame(width:height:)` | Fixed dimensions |
| `.border(_:color:)` | Add border via ContainerView |
| `.disabled(_:)` | Disable interaction |
| `.overlay(_:)` | Overlay content |
| `.focusSection(_:)` | Named focus region |
| `.equatable()` | Enable render caching |

## Patterns & Conventions

### New View (Correct Pattern - Box.swift)

```swift
public struct MyContainer<Content: View>: View {
    let title: String?
    let content: Content
    
    public var body: some View {
        ContainerView(title: title) {
            content
        }
    }
}
```

### Stateful Control (Correct Pattern)

```swift
public struct MyControl: View {
    let selection: Binding<String?>
    
    public var body: some View {
        // Compose Views - environment propagates
        _MyControlContent(selection: selection)
    }
}

// Internal - can use Renderable for leaf rendering
private struct _MyControlContent: View, Renderable {
    let selection: Binding<String?>
    
    var body: Never { fatalError() }
    
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Access StateStorage, FocusManager here
        // Read environment: context.environment.foregroundStyle
        // This is OK because it's internal and at leaf level
    }
}
```

### Focus Handler Pattern

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

// In renderToBuffer of internal _Core view:
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
       │         │    └─ If View has body: render body (env propagates!)
       │         │    └─ If Renderable: call renderToBuffer directly
       │         ├─ focusManager.endRenderPass()
       │         └─ FrameDiffWriter.write(buffer)
       └─ terminal.readKeyEvent()
            └─ inputHandler.handle(event)
```

## SwiftUI API Parity Rules

| Aspect | Requirement |
|--------|-------------|
| Parameter names | Exact (`isPresented`, not `isVisible`) |
| Parameter order | Exact (title, binding, actions, message) |
| Parameter types | Match closely (ViewBuilder closures) |
| Trailing closures | `@ViewBuilder () -> T`, not `String` |

**Before implementing:** Look up exact SwiftUI signature first.

## Controls Needing Refactor

These currently use `body: Never` and need conversion to real `body: some View`:

**High Priority (Complex):**
- List, Table - StateStorage + FocusManager
- RadioButtonGroup - StateStorage + FocusManager
- Menu - StateStorage + FocusManager

**Medium Priority (Interactive):**
- Button, Toggle - Focus handling

**Lower Priority (Containers):**
- Card, Panel, Dialog, Alert - Already use ContainerView

**OK as Renderable (Leaf Nodes):**
- Text, Spacer, Divider
- HStack, VStack, ZStack (layout primitives)
- ForEach (iteration helper)

## Current State

**Branch:** `refactor/foreground-style`
**Tests:** 666 / 104 suites
**Build:** clean
**Lint:** 0 warnings

### Recent (Feb 2026)

- `.foregroundColor()` renamed to `.foregroundStyle()` for SwiftUI parity
- List & Table PR merged (focus bar, F-keys, StatusBar defaults)
- Xcode project template created (TUIkit App.xctemplate)
- List/Table implemented with ItemListHandler

### Next

- TextInput / TextField component
- View Architecture Refactor (plan: `2026-02-07-view-architecture-refactor.md`)

---

**Last Updated:** 2026-02-08
