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
├── Tests/TUIkitTests/       # Swift Testing (682 tests)
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

### Renderable: When to Use

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

### Actor Isolation

| Scope | Isolation |
|-------|-----------|
| View, ViewModifier, Renderable | `@MainActor` |
| App, Scene | `@MainActor` |
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
| `ListRowExtractor` | List row extraction | `func extractListRows<ID>(context:) -> [ListRow<ID>]` |
| `SectionRowExtractor` | Section metadata | `func extractSectionInfo(context:) -> SectionInfo` |
| `ChildInfoProvider` | Stack child info | `func childInfos(context:) -> [ChildInfo]` |

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

### Views & Core Types

| View | Purpose |
|------|---------|
| `Text` | Styled text (leaf) |
| `Button` | Action trigger, focusable, supports ButtonRole |
| `Toggle` | Boolean switch (slider/checkbox) |
| `RadioButtonGroup` | Single-select options |
| `Box` | Bordered container (reference implementation!) |
| `List` | Scrollable list with selection |
| `Table` | Tabular data with columns |
| `Section` | Group content with header/footer |
| `Alert` | Modal alert with horizontal buttons |
| `VStack/HStack/ZStack` | Layout |
| `Spacer` | Flexible space (leaf) |
| `Divider` | Horizontal line |
| `Spinner` | Loading indicator |
| `ProgressView` | Progress bar (5 styles) |
| `ForEach` | Collection iteration |

| Type (Phase 2c New) | Purpose |
|--------------------|---------|
| `SelectableListRow` | Type-safe row metadata (header/content/footer) |
| `ListRowType` | Enum classifying row types |
| `BadgeValue` | Badge rendering metadata (Int/String) |
| `ItemListHandler` | Selection + keyboard navigation |

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
| `.alert(isPresented:)` | Show modal alert |

## Patterns & Conventions

### New View (Correct Pattern: Box.swift)

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
- FocusManager: Tab = sections, Up/Down/Left/Right = within section

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

**OK as Renderable (Leaf Nodes):**
- Text, Spacer, Divider
- HStack, VStack, ZStack (layout primitives)
- ForEach (iteration helper)

## Current State

**Branch:** `main`
**Tests:** 722 / 110 suites
**Build:** clean (1 pre-existing flaky Focus test)

### Phase 2: SwiftUI API Parity — Status

| Phase | Feature | Status | Commit |
|-------|---------|--------|--------|
| 2a | Badge Modifier | ✅ Complete | 5cb6794 (earlier) |
| 2b | ListStyle System | ✅ Complete | 5cb6794 (earlier) |
| 2c1 | SelectableListRow Foundation | ✅ Complete | 9df0ab0 |
| 2c2 | ItemListHandler Skip Logic | ✅ Complete | 9df0ab0 |
| 2c3 | List Integration & Rendering | 🚧 Deferred | — |

### Recent Completions (2026-02-09)

- **Badge Modifier (Phase 2a)**: Int/Text/StringProtocol overloads, environment, 20+ tests
- **ListStyle System (Phase 2b)**: PlainListStyle, InsetGroupedListStyle, alternating colors
- **SelectableListRow (Phase 2c1)**: Type-safe row classification (header/content/footer)
- **ItemListHandler Skip Logic (Phase 2c2)**: selectableIndices, focus navigation over non-selectable rows

### Phase 2c3 — Deferred to Next Session

**Why Deferred:** ListRow refactoring from `(id, buffer)` to `(type, buffer)` affects 5+ methods
- `extractRows()` - Section detection/flattening
- `calculateVisibleRows()` - Type awareness
- `renderRow()` - Header/footer styling
- Selection/focus updates

**Recommendation:** Dedicate full session to this refactoring. Foundation ready (2c1+2c2).

---

**Last Updated:** 2026-02-09
