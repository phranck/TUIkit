# Architecture

Understand the layer model and rendering pipeline of TUIkit.

## Overview

TUIkit is structured in five layers, each building on the one below. This clean separation makes the framework easy to extend and maintain.

## Layer Model

### 1. App Layer

The ``App`` protocol is the entry point. It defines one or more scenes that make up your application. The internal `AppRunner` manages the main run loop, terminal setup, signal handling, and event dispatching.

```
@main → App → AppRunner → Main Loop
```

### 2. View Layer

Every UI component conforms to the ``View`` protocol. Views are composed declaratively using ``ViewBuilder``, which supports:

- Single and multiple child views (up to 10)
- Conditionals (`if`, `if-else`, `if let`)
- Loops (`for-in` via ``ForEach``)

Built-in views include ``Text``, ``Button``, ``Menu``, ``Alert``, ``Dialog``, ``Box``, ``Card``, ``Panel``, and layout primitives like ``VStack``, ``HStack``, ``ZStack``, and ``Spacer``.

### 3. Modifier Layer

View modifiers implement the ``ViewModifier`` protocol and operate at the ``FrameBuffer`` level. They transform rendered output — adding padding, borders, frames, backgrounds, or overlays.

```swift
Text("Hello")
    .padding(1)
    .border(.rounded)
    .frame(width: 40)
```

### 4. State & Environment Layer

- **``State``** — Mutable per-view state that triggers re-renders
- **``Binding``** — Two-way connection to a value owned elsewhere
- **``Environment``** — Values propagated down the view tree
- **``AppStorage``** — Persistent key-value storage via `UserDefaults`

### 5. Rendering Layer

The rendering pipeline converts the view tree into terminal output:

1. **View tree traversal** — Each view produces a ``FrameBuffer``
2. **Modifier application** — Modifiers transform buffers
3. **ANSI rendering** — The `ANSIRenderer` converts colors and styles to escape codes
4. **Terminal output** — The ``FrameBuffer`` lines are written to the terminal

## Event Loop

TUIkit runs a synchronous event loop:

```
┌─────────────────────────┐
│   Check resize/state    │
│   ↓                     │
│   Render view tree      │
│   ↓                     │
│   Read key event        │
│   ↓                     │
│   Dispatch to handlers  │
│   ↓                     │
│   Loop                  │
└─────────────────────────┘
```

Key events are dispatched in order:
1. Status bar items (system and user)
2. Registered key event handlers (from `onKeyPress`)
3. Default handlers (quit, theme cycling, appearance cycling)

## Focus System

The ``FocusManager`` manages keyboard navigation between interactive elements. Views register as focusable, and the user navigates with Tab/Shift+Tab or arrow keys.
