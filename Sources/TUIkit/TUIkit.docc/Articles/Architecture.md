# Architecture

Understand the layer model and rendering pipeline of TUIkit.

## Overview

TUIkit is structured in six layers, each building on the one below. This clean separation makes the framework easy to extend and maintain.

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

Built-in views include:

- **Content**: ``Text``, ``Spinner``, ``Divider``, ``EmptyView``
- **Interactive controls**: ``Button``, ``TextField``, ``SecureField``, ``Toggle``, ``Slider``, ``Stepper``, ``RadioButtonGroup``, ``Menu``, ``ProgressView``
- **Containers**: ``Card``, ``Panel``, ``Alert``, ``Dialog``, ``NavigationSplitView``
- **Data collections**: ``List``, ``Table``, ``Section``
- **Layout**: ``VStack``, ``HStack``, ``ZStack``, ``LazyVStack``, ``LazyHStack``, ``Spacer``, ``ForEach``

### 3. Layout Layer

Layout containers use a two-pass system to distribute space among children:

1. **Measure**: Each child is proposed a size (``ProposedSize``) and returns a ``ViewSize`` with flexibility flags
2. **Render**: The parent distributes remaining space among flexible children and renders each with its final allocation

This enables spacers, flexible text fields, and proportional sizing. See <doc:LayoutSystem> for details.

### 4. Modifier Layer

View modifiers implement the ``ViewModifier`` protocol. They operate in two phases: `adjustContext(_:)` modifies the ``RenderContext`` before children render (e.g. setting environment values), and `apply(to:context:)` transforms the rendered ``FrameBuffer`` (e.g. adding padding, borders, backgrounds).

```swift
Text("Hello")
    .padding(1)
    .border(.rounded)
    .frame(width: 40)
```

### 5. State & Environment Layer

- **``State``**: Mutable per-view state that triggers re-renders
- **``Binding``**: Two-way connection to a value owned elsewhere
- **``EnvironmentValues``**: Values propagated down the view tree
- **``AppStorage``**: Persistent key-value storage via `UserDefaults`

### 6. Rendering Layer

The rendering pipeline converts the view tree into terminal output:

1. **View tree traversal**: Each view produces a ``FrameBuffer``
2. **Modifier application**: Modifiers transform buffers
3. **ANSI rendering**: The `ANSIRenderer` converts colors and styles to escape codes
4. **Terminal output**: The ``FrameBuffer`` lines are written to the terminal

## Event Loop

`AppRunner` initializes all subsystems (Terminal, AppState, StatusBarState, AppHeaderState, FocusManager, ThemeManager x2, TUIContext), creates InputHandler and RenderLoop, installs POSIX signal handlers, sets up the terminal (alternate screen, raw mode), starts PulseTimer (100 ms) and CursorTimer (50 ms), registers state and focus observers, and performs an initial render before entering the main loop.

Each loop iteration checks `shouldShutdown` (set by SIGINT), consumes the resize flag to invalidate the diff cache if SIGWINCH fired, then renders when `consumeRerenderFlag()` or `appState.needsRender` is true. After rendering, it reads up to 128 non-blocking key events per frame and dispatches each through five handler layers. A `usleep(28_000)` throttles the loop to approximately 35 FPS. Asynchronous render triggers (timers, @State changes, SIGWINCH, focus changes) feed back into the render decision via `appState.needsRender` or `signals.requestRerender()`.

@Image(source: "architecture-event-loop.png", alt: "Flowchart of the TUIkit event loop: @main entry initializes subsystems, sets up terminal, starts timers and observers, performs an initial render, then enters the main loop. The loop checks shouldShutdown, consumes the resize flag to invalidate the diff cache, checks rerenderFlag or needsRender to conditionally render, reads key events non-blocking up to 128 per frame, dispatches through 5 input layers, and sleeps 28ms. SIGINT exits to cleanup. Async render triggers from timers, state changes, SIGWINCH, and focus changes feed back into the needsRender check.")

Input dispatch uses a first-consumer-wins model. Layer 0 and Layer 3 are mutually exclusive: when a text input element (TextField/SecureField) is focused, Layer 0 runs and Layer 3 is skipped; otherwise Layer 0 is skipped and Layer 3 runs. Both use `focusManager.dispatchKeyEvent()`, which first delegates to the focused element, then handles Tab/Shift+Tab navigation, then arrow key fallback.

@Image(source: "architecture-input-dispatch.png", alt: "Flowchart of the 5-layer input dispatch: A hasTextInputFocus check gates Layer 0 (Text Input via focusManager.dispatchKeyEvent for TextField/SecureField). Layer 1 Status Bar Items (statusBar.handleKeyEvent). Layer 2 View Handlers (keyEventDispatcher.dispatch, deepest view first). A second hasTextInputFocus check skips Layer 3 if text input was focused. Layer 3 Focus System (focusManager.dispatchKeyEvent: focused element delegation, Tab/Shift+Tab, arrow key fallback). Layer 4 Default Bindings (q quit, t theme, a appearance). Unmatched events are dropped.")

## Focus System

The `FocusManager` manages keyboard navigation between interactive elements. Views register as focusable, and the user navigates with Tab/Shift+Tab or arrow keys.
