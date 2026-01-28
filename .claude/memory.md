# SwiftTUI - Technical Reference

## Tech Stack

- **Language:** Swift 6.0 (strict concurrency)
- **Platforms:** macOS (10.15+), Linux
- **Build System:** Swift Package Manager (swift-tools-version 6.0)
- **Testing:** Swift Testing framework (`@Test`, `#expect`)
- **Dependencies:** None (pure Swift, no ncurses, no C libs)

## Project Structure

```
SwiftTUI/
├── Package.swift
├── README.md
├── Sources/
│   ├── SwiftTUI/                      # Main library target
│   │   ├── SwiftTUI.swift             # Version constant, renderOnce() helper
│   │   ├── App/
│   │   │   ├── App.swift              # App protocol, AppRunner, StatusBarState
│   │   │   └── Scene.swift            # Scene protocol, WindowGroup, SceneBuilder
│   │   ├── Core/
│   │   │   ├── View.swift             # View protocol (central)
│   │   │   ├── ViewBuilder.swift      # @resultBuilder for declarative composition
│   │   │   ├── ViewModifier.swift     # ViewModifier protocol, ModifiedView
│   │   │   ├── TupleViews.swift       # TupleView2–TupleView10
│   │   │   ├── PrimitiveViews.swift   # Never, EmptyView, ConditionalView, etc.
│   │   │   ├── Color.swift            # Color struct (ANSI, 256, RGB, hex, HSL)
│   │   │   ├── BorderStyle.swift      # Border styles for boxes/cards
│   │   │   ├── State.swift            # AppState, @State, Binding
│   │   │   ├── KeyEvent.swift         # KeyEvent, Key enum, KeyEventDispatcher
│   │   │   ├── Focus.swift            # FocusManager, Focusable protocol
│   │   │   ├── Environment.swift      # @Environment, EnvironmentValues, EnvironmentKey
│   │   │   ├── Preferences.swift      # PreferenceKey, PreferenceValues (bottom-up)
│   │   │   ├── Theme.swift            # Theme protocol, 8 predefined themes
│   │   │   ├── AppStorage.swift       # @AppStorage, @SceneStorage, StorageBackend
│   │   │   └── UserDefaultsStorage.swift # Platform-specific UserDefaults
│   │   ├── Modifiers/
│   │   │   ├── PaddingModifier.swift
│   │   │   ├── FrameModifier.swift    # Fixed + flexible frames (min/max/infinity)
│   │   │   ├── BorderModifier.swift   # BorderedView (width-aware)
│   │   │   ├── BackgroundModifier.swift
│   │   │   ├── DimmedModifier.swift
│   │   │   ├── OverlayModifier.swift
│   │   │   ├── KeyPressModifier.swift
│   │   │   ├── StatusBarItemsModifier.swift
│   │   │   └── LifecycleModifier.swift # onAppear, onDisappear, task
│   │   ├── Rendering/
│   │   │   ├── Terminal.swift         # Terminal (raw mode, size, I/O, signals)
│   │   │   ├── ANSIRenderer.swift     # ANSI escape code generation
│   │   │   ├── FrameBuffer.swift      # Character-level buffer with compositing
│   │   │   ├── Renderable.swift       # Renderable protocol, RenderContext
│   │   │   └── ViewRenderer.swift     # Renderable extensions for all views
│   │   └── Views/
│   │       ├── Text.swift             # Text view + TextStyle + modifiers
│   │       ├── Stacks.swift           # VStack, HStack, ZStack + Alignment types
│   │       ├── Spacer.swift           # Spacer, Divider
│   │       ├── ForEach.swift          # ForEach (Identifiable, KeyPath, Range)
│   │       ├── Card.swift, Box.swift, Panel.swift  # Containers
│   │       ├── Button.swift           # Interactive button with focus
│   │       ├── Menu.swift             # Menu with selection and shortcuts
│   │       ├── Alert.swift            # Modal alert with presets
│   │       ├── Dialog.swift           # Modal dialog + .modal() modifier
│   │       └── StatusBar.swift        # StatusBar, StatusBarItem, Shortcut
│   └── SwiftTUIExample/               # Executable example target
│       ├── main.swift
│       ├── AppState.swift
│       ├── ContentView.swift
│       ├── Components/ (HeaderView, DemoSection)
│       └── Pages/ (7 demo pages)
└── Tests/SwiftTUITests/               # 178 tests in 26 suites
```

## Architecture

### Core Patterns

- **View** is a protocol (value types, like SwiftUI's View)
- **@ViewBuilder** is a `@resultBuilder` supporting up to 10 children
- **Primitive views** have `body: Never` and conform to `Renderable`
- **Composite views** define `body` — renderer walks tree recursively
- **Environment** for top-down data flow (theme, statusBar)
- **Preferences** for bottom-up data flow (child → parent)

### Rendering Pipeline

1. `AppRunner` manages the run loop
2. `renderToBuffer()` traverses view tree
3. Views conforming to `Renderable` produce `FrameBuffer`
4. `FrameBuffer` supports character-level compositing for overlays

### Data Flow

- **Environment** (top-down): Theme, StatusBar, custom values
- **Preferences** (bottom-up): Navigation title, anchors
- **@State**: Local view state with automatic re-render
- **@AppStorage**: Persistent settings (JSON or UserDefaults)
- **@SceneStorage**: Scene state restoration

### Platform Support

- **macOS**: Full support with native UserDefaults
- **Linux**: Full support with JSON storage, XDG paths

## Naming Conventions

All types use clean names without prefixes:
- `View`, `App`, `Scene`, `State` (not TView, TApp, etc.)
- `ViewBuilder`, `ViewModifier`
- `StatusBar`, `StatusBarItem`, `StatusBarStyle`

## Test Execution

```bash
swift test --no-parallel
```

Note: `--no-parallel` required due to FocusManager singleton

## Current Branch

`feature/tview-foundation`
