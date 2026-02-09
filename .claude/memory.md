# TUIkit Memory

## Project Overview

**Name:** TUIkit  
**Purpose:** Terminal UI framework for Swift (SwiftUI-inspired API)  
**Language:** Swift 6.0  
**Platforms:** macOS, Linux  
**Repo:** github.com/phranck/TUIkit

### Package Structure

```
TUIkit/
├── Sources/TUIkit/          # Main library
├── Sources/TUIkitExample/   # Demo app (15 pages)
├── Tests/TUIkitTests/       # Swift Testing
├── docs/                    # Astro site + DocC
└── plans/                   # Feature plans
```

### Dependencies

- None (pure Swift, no ncurses)

## Architecture

### View / Renderable Duality

```
Public API                     Internal
──────────                     ────────
struct MyView: View
  var body: some View          (composes other Views)
      ↓
  private _Core: View          extension _Core: Renderable
    var body: Never              func renderToBuffer(context:)
```

**Renderable ONLY for leaf nodes:** Text, Spacer, Divider, internal `_*Core` types.

### Directory Map

| Directory | Purpose |
|-----------|---------|
| `App/` | App, Scene, AppRunner, SignalManager, PulseTimer, InputHandler |
| `Core/` | View, ViewBuilder, KeyEvent, Lock, Binding, ViewIdentity |
| `Environment/` | EnvironmentValues, EnvironmentKey, TUIContext |
| `Focus/` | FocusManager, Focusable, ActionHandler, ItemListHandler, TextFieldHandler, SliderHandler, StepperHandler |
| `Modifiers/` | All ViewModifier implementations |
| `Rendering/` | Terminal, FrameBuffer, RenderCache, ANSIRenderer, TrackRenderer, BorderRenderer |
| `State/` | @State, StateStorage, StateBox, AppState |
| `StatusBar/` | StatusBarState, StatusBarItem |
| `Styling/` | Color, Palette, Appearance, ThemeManager, TrackStyle |
| `Views/` | All View implementations |

### Rendering Pipeline

```
AppRunner.run()
  └─ Main loop (40ms tick)
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

## Key Types Reference

### Protocols

| Protocol | Purpose | Key Requirement |
|----------|---------|-----------------|
| `View` | User-facing component | `var body: some View` |
| `Renderable` | Internal rendering (leaf nodes only) | `func renderToBuffer(context:) -> FrameBuffer` |
| `Focusable` | Keyboard focus | `func handleKeyEvent(_:) -> Bool` |
| `ViewModifier` | View transformation | `func modify(buffer:context:) -> FrameBuffer` |
| `Palette` | Color theme | foreground, background, accent, etc. |
| `TerminalProtocol` | Terminal abstraction | `func write(_:)`, `func readKeyEvent()` |

### Focus Handlers

| Handler | Used By | Key Features |
|---------|---------|--------------|
| `ActionHandler` | Button, Toggle | Simple action on Enter/Space |
| `ItemListHandler` | List, Table | Up/Down/PgUp/PgDn, selection, F-keys |
| `TextFieldHandler` | TextField, SecureField | Text editing, cursor, selection |
| `SliderHandler` | Slider | Arrow/+- keys, Home/End |
| `StepperHandler` | Stepper | Arrow/+- keys, optional bounds |

### Views

| View | Purpose | Handler |
|------|---------|---------|
| `Text` | Styled text (leaf) | - |
| `Button` | Action trigger | ActionHandler |
| `Toggle` | Boolean switch | ActionHandler |
| `TextField` | Text input | TextFieldHandler |
| `SecureField` | Password input | TextFieldHandler |
| `Slider` | Range selection | SliderHandler |
| `Stepper` | Inc/dec control | StepperHandler |
| `RadioButtonGroup` | Single-select | ActionHandler per option |
| `List` | Scrollable list | ItemListHandler |
| `Table` | Tabular data | ItemListHandler |
| `Menu` | Selection menu | ActionHandler |
| `Alert` | Modal dialog | ActionHandler per button |
| `ProgressView` | Progress bar | - |
| `Spinner` | Loading indicator | - |
| `Box`, `Card`, `Panel` | Containers | - |
| `VStack`, `HStack`, `ZStack` | Layout | - |
| `Section` | Group with header | - |

### Modifiers

| Modifier | Effect |
|----------|--------|
| `.foregroundStyle(_:)` | Text/border color |
| `.bold()`, `.dim()`, `.italic()` | Text styling |
| `.padding(_:)` | Edge insets |
| `.frame(width:height:)` | Fixed dimensions |
| `.border(_:color:)` | Add border |
| `.disabled(_:)` | Disable interaction |
| `.focusSection(_:)` | Named focus region |
| `.equatable()` | Enable render caching |
| `.alert(isPresented:)` | Show modal alert |
| `.badge(_:)` | Show badge on list row |
| `.trackStyle(_:)` | Set track appearance (Slider, ProgressView) |
| `.onSubmit(_:)` | TextField submit action |

### TrackStyle

```swift
public enum TrackStyle {
    case block      // ████████░░░░░░░░
    case blockFine  // ████████▍░░░░░░░ (sub-char precision)
    case shade      // ▓▓▓▓▓▓▓▓░░░░░░░░
    case bar        // ▌▌▌▌▌▌▌▌────────
    case dot        // ▬▬▬▬▬▬▬▬●───────
}
```

Used by: `ProgressView`, `Slider`

## Patterns

### New Interactive View

```swift
// 1. Create handler in Focus/
final class MyHandler: Focusable {
    let focusID: String
    var canBeFocused: Bool = true
    
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        switch event.key {
        case .enter: doAction(); return true
        default: return false
        }
    }
}

// 2. Create view in Views/
public struct MyView: View {
    public var body: some View {
        _MyViewCore(...)
    }
}

private struct _MyViewCore: View, Renderable {
    var body: Never { fatalError() }
    
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Get handler from StateStorage
        let key = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let box: StateBox<MyHandler> = context.tuiContext.stateStorage.storage(for: key, default: MyHandler(...))
        
        // Register with FocusManager
        context.environment.focusManager.register(box.value, inSection: context.activeFocusSectionID)
        context.tuiContext.stateStorage.markActive(context.identity)
        
        // Check focus state
        let isFocused = context.environment.focusManager.isFocused(id: focusID)
        
        // Render...
    }
}
```

### Focus Indicator Pattern

```swift
// Pulsing vertical bars for focused state (TextField, Slider, Stepper)
if isFocused {
    let dimAccent = palette.accent.opacity(0.35)
    let barColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
    let bar = ANSIRenderer.colorize("❙", foreground: barColor)
    return "\(bar) \(content) \(bar)"
}
return "  \(content)  "  // Unfocused: spaces for alignment
```

### TextField Selection

```swift
// TextFieldHandler manages selection state
var selectionAnchor: Int?  // nil = no selection
var selectionRange: Range<Int>? {
    guard let anchor = selectionAnchor, anchor != cursorPosition else { return nil }
    return min(anchor, cursorPosition)..<max(anchor, cursorPosition)
}

// Shift+Arrow extends selection
func extendSelectionLeft() {
    startOrExtendSelection()
    if cursorPosition > 0 { cursorPosition -= 1 }
}

// Arrow without Shift clears selection
case .left:
    if event.shift { extendSelectionLeft() }
    else { clearSelection(); moveCursorLeft() }
```

### Keyboard Navigation

- Handler's `handleKeyEvent` called first
- Return `true` = consumed, `false` = pass to FocusManager
- Tab = cycle focus sections
- Up/Down/Left/Right = navigate within section
- Enter/Space = activate focused element

### CSI Modifier Parsing

```swift
// xterm modifier codes: ESC [1;2A = Shift+Up
// Modifier code - 1 = bit flags (bit0=Shift, bit1=Alt, bit2=Ctrl)
let bits = modifier - 1
let shift = (bits & 1) != 0
let alt = (bits & 2) != 0
let ctrl = (bits & 4) != 0
```

## Current State

**Branch:** `main`  
**Tests:** 947 / 131 suites  
**Build:** clean

### Recent Changes (2026-02-09)

- TextField/SecureField selection: Shift+Arrow, highlight, delete/replace (41 tests)
- CSI modifier parsing: Shift/Alt/Ctrl in escape sequences
- Test file refactoring: Split FocusTests and ModifierTests

### Known Issues

- None

---
**Last Updated:** 2026-02-09
