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
├── .claude/plans/           # Feature plans (open/ + done/)
└── docs/                    # Astro site + DocC
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

### Two-Pass Layout System (NEW)

```
Phase 1: Measure          Phase 2: Render
──────────────────        ─────────────────
sizeThatFits(proposal)    renderToBuffer(context)
  └─ returns ViewSize       └─ uses allocated size
     (width, height,
      isWidthFlexible,
      isHeightFlexible)
```

**Key Types:**
- `ProposedSize` - Parent suggests size (nil = ideal, value = constraint)
- `ViewSize` - View reports needed size + flexibility
- `Layoutable` - Protocol for views supporting two-pass layout
- `ChildView` - Type-erased wrapper for measure/render

**Flexible Views:** TextField, SecureField, Slider, Spacer
**Fixed Views:** Text, Button, Toggle

### Directory Map

| Directory | Purpose |
|-----------|---------|
| `App/` | App, Scene, AppRunner, SignalManager, PulseTimer, InputHandler |
| `Core/` | View, ViewBuilder, KeyEvent, Lock, Binding, ViewIdentity |
| `Environment/` | EnvironmentValues, EnvironmentKey, TUIContext |
| `Focus/` | FocusManager, Focusable, ActionHandler, ItemListHandler, TextFieldHandler, SliderHandler, StepperHandler |
| `Modifiers/` | All ViewModifier implementations |
| `Rendering/` | Terminal, FrameBuffer, RenderCache, ANSIRenderer, TrackRenderer, BorderRenderer, ChildInfo |
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
       │         │    └─ Two-pass for HStack/VStack:
       │         │         1. Measure all children
       │         │         2. Distribute space
       │         │         3. Render with final sizes
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
| `Layoutable` | Two-pass layout support | `func sizeThatFits(proposal:context:) -> ViewSize` |
| `Focusable` | Keyboard focus | `func handleKeyEvent(_:) -> Bool` |
| `ChildViewProvider` | Extract children for layout | `func childViews(context:) -> [ChildView]` |
| `ViewModifier` | View transformation | `func modify(buffer:context:) -> FrameBuffer` |
| `Palette` | Color theme | foreground, background, accent, etc. |

### Layout Types

| Type | Purpose | Key Members |
|------|---------|-------------|
| `ProposedSize` | Parent's size suggestion | `width: Int?`, `height: Int?`, `.unspecified` |
| `ViewSize` | View's size response | `width`, `height`, `isWidthFlexible`, `isHeightFlexible` |
| `ChildView` | Type-erased child | `measure(proposal:context:)`, `render(width:height:context:)` |
| `ChildInfo` | Legacy child info | `buffer`, `isSpacer`, `size` |

### Focus Handlers

| Handler | Used By | Key Features |
|---------|---------|--------------|
| `ActionHandler` | Button, Toggle | Simple action on Enter/Space |
| `ItemListHandler` | List, Table | Up/Down/PgUp/PgDn, selection, F-keys |
| `TextFieldHandler` | TextField, SecureField | Text editing, cursor, selection, clipboard |
| `SliderHandler` | Slider | Arrow/+- keys, Home/End |
| `StepperHandler` | Stepper | Arrow/+- keys, optional bounds |

### Views

| View | Purpose | Layoutable | Handler |
|------|---------|------------|---------|
| `Text` | Styled text (leaf) | ✓ fixed | - |
| `Spacer` | Flexible space | ✓ flexible | - |
| `Divider` | Horizontal line | ✓ width-flex | - |
| `HStack` | Horizontal layout | ✓ depends | - |
| `VStack` | Vertical layout | ✓ depends | - |
| `TextField` | Text input | ✓ width-flex | TextFieldHandler |
| `SecureField` | Password input | ✓ width-flex | TextFieldHandler |
| `Slider` | Range selection | ✓ width-flex | SliderHandler |
| `Button` | Action trigger | - | ActionHandler |
| `Toggle` | Boolean switch | - | ActionHandler |
| `List` | Scrollable list | - | ItemListHandler |
| `Table` | Tabular data | - | ItemListHandler |
| `Panel`, `Card` | Containers | - (content-based) | - |

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
| `.trackStyle(_:)` | Set track appearance |

## Patterns

### Two-Pass Layout in Stacks

```swift
// HStack/VStack renderToBuffer pattern
func renderToBuffer(context: RenderContext) -> FrameBuffer {
    let children = resolveChildViews(from: content, context: context)
    
    // Pass 1: Measure
    var childSizes: [ViewSize] = []
    var totalFixed = 0, flexibleCount = 0
    for child in children {
        let size = child.measure(proposal: .unspecified, context: context)
        childSizes.append(size)
        if child.isSpacer || size.isWidthFlexible {
            flexibleCount += 1
            totalFixed += size.width  // minimum
        } else {
            totalFixed += size.width
        }
    }
    
    // Calculate flexible allocation
    let remaining = context.availableWidth - totalFixed - spacing
    let flexWidth = flexibleCount > 0 ? remaining / flexibleCount : 0
    
    // Pass 2: Render with final sizes
    for (child, size) in zip(children, childSizes) {
        let finalWidth = size.isWidthFlexible ? size.width + flexWidth : size.width
        let buffer = child.render(width: finalWidth, height: ..., context: context)
        result.appendHorizontally(buffer, spacing: ...)
    }
}
```

### Making a View Width-Flexible

```swift
private struct _MyViewCore: View, Renderable, Layoutable {
    private let minWidth = 10
    private let defaultWidth = 20
    
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        let width = proposal.width ?? defaultWidth
        return ViewSize(
            width: max(minWidth, width),
            height: 1,
            isWidthFlexible: true,
            isHeightFlexible: false
        )
    }
    
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let width = max(minWidth, context.availableWidth)
        // render with width...
    }
}
```

### Focus Indicator Pattern

```swift
// Pulsing vertical bars for focused state
if isFocused {
    let dimAccent = palette.accent.opacity(0.35)
    let barColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
    let bar = ANSIRenderer.colorize("❙", foreground: barColor)
    return "\(bar) \(content) \(bar)"
}
```

## Current State

**Branch:** `refactor/two-pass-layout`  
**Tests:** 1034 / 143 suites  
**Build:** clean

### Recent Changes

- Two-pass layout: ProposedSize, ViewSize, Layoutable protocol
- HStack/VStack: Measure-then-render with flexible space distribution
- TextField/SecureField/Slider: Now width-flexible (expand in HStack)
- ChildView: Type-erased wrapper for two-pass layout
- Focus fix: RenderContext.isMeasuring flag prevents double registration
- All focusable views skip focusManager.register() during measurement pass

### Pending

- Verify focus behavior in Example App (TextField Demo page)
- Phase 5: Remove hasExplicitWidth/hasExplicitHeight (deferred)
- List/Table: Not yet Layoutable

---
**Last Updated:** 2026-02-11
