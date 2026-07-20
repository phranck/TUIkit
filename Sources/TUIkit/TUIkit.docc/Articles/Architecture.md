# Architecture

Understand the layer model and rendering pipeline of TUIkit.

## Overview

TUIkit is structured in six layers, each building on the one below. This clean separation makes the framework easy to extend and maintain.

## Layer Model

### 1. App Layer

The ``App`` protocol is the entry point. It defines one or more scenes that make up your application. The internal `AppRunner` manages the async event loop, terminal setup, signal handling, and event dispatching.

```
@main → App → AppRunner → RuntimeEventChannel
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
- **``AppStorage``**: Persistent key-value storage through the app runtime

### 6. Rendering Layer

The rendering pipeline converts the view tree into terminal output:

1. **View tree traversal**: Each view produces a ``FrameBuffer``
2. **Modifier application**: Modifiers transform buffers
3. **ANSI rendering**: The `ANSIRenderer` converts colors and styles to escape codes
4. **Terminal output**: The ``FrameBuffer`` lines are written to the terminal

## Package Boundaries

The framework is split into five Swift library modules. `TUIkitImage` depends on `TUIkitStyling` plus vendored, namespaced pure Swift PNG,
JPEG, and checksum targets with documented upstream revisions. The package graph has no C or C++ target and no native decoder dependency.

``PlatformImageLoader`` accepts static PNG and JPEG data and produces non-premultiplied 8-bit RGBA pixels. Before a format decoder runs,
the internal decoding layer validates encoded bytes, dimensions, pixel and frame counts, decompressed samples, and final allocation. File
and URL loading feed data into that deterministic decoder rather than participating in format parsing.

## Event Loop

`AppRunner` owns the terminal session and signal manager plus one `TUIContext`.
That context owns the application's render state, storage, caches, localization,
notifications, focus, themes, image loading, and other view-facing services.
`AppRunner` creates `InputHandler`, `RenderLoop`, and a
`RuntimeAnimationScheduler`; installs dispatch-backed signal and terminal-input
sources; registers state and focus observers; and performs an initial render.
`PulseTimer` and `CursorTimer` are monotonic phase calculators rather than
background timers.

The runner then awaits `RuntimeEventChannel`. State invalidations request a
render, input readiness drains up to 128 key events, SIGWINCH invalidates the
diff cache, animation deadlines advance visible focus effects, and termination
events begin cleanup. These paths are serialized on the main actor. With no
pending event or visible animation deadline, the runtime remains suspended and
does no periodic work.

Signal and input callbacks only enqueue events. Shutdown stops every event
source, finishes the channel, cancels view tasks through `TUIContext.reset()`,
and restores raw mode, cursor visibility, and the alternate screen before an
I/O failure is propagated.

Input dispatch uses a first-consumer-wins model. Layer 0 and Layer 3 are mutually exclusive: when a text input element (TextField/SecureField) is focused, Layer 0 runs and Layer 3 is skipped; otherwise Layer 0 is skipped and Layer 3 runs. Both use `focusManager.dispatchKeyEvent()`, which first delegates to the focused element, then handles Tab/Shift+Tab navigation, then arrow key fallback.

@Image(source: "architecture-input-dispatch.png", alt: "Flowchart of the 5-layer input dispatch: A hasTextInputFocus check gates Layer 0 (Text Input via focusManager.dispatchKeyEvent for TextField/SecureField). Layer 1 Status Bar Items (statusBar.handleKeyEvent). Layer 2 View Handlers (keyEventDispatcher.dispatch, deepest view first). A second hasTextInputFocus check skips Layer 3 if text input was focused. Layer 3 Focus System (focusManager.dispatchKeyEvent: focused element delegation, Tab/Shift+Tab, arrow key fallback). Layer 4 Default Bindings (q quit, t theme, a appearance). Unmatched events are dropped.")

## Focus System

The `FocusManager` manages keyboard navigation between interactive elements. Views register as focusable, and the user navigates with Tab/Shift+Tab or arrow keys.
