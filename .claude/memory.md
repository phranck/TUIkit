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
│   │   │   ├── TApp.swift             # TApp protocol, AppRunner, StatusBarState
│   │   │   └── TScene.swift           # TScene protocol, WindowGroup, SceneBuilder
│   │   ├── Core/
│   │   │   ├── TView.swift            # TView protocol (central)
│   │   │   ├── TViewBuilder.swift     # @resultBuilder for declarative composition
│   │   │   ├── TupleViews.swift       # TupleView2–TupleView10
│   │   │   ├── PrimitiveViews.swift   # Never, EmptyView, ConditionalView, etc.
│   │   │   ├── ViewModifier.swift     # TViewModifier protocol, ModifiedView
│   │   │   ├── Color.swift            # Color struct (ANSI, 256, RGB, hex, HSL)
│   │   │   ├── BorderStyle.swift      # Border styles for boxes/cards
│   │   │   ├── State.swift            # AppState, @TState, Binding
│   │   │   ├── KeyEvent.swift         # KeyEvent, Key enum, KeyEventDispatcher
│   │   │   ├── Focus.swift            # FocusManager, Focusable protocol
│   │   │   ├── Environment.swift      # @Environment, EnvironmentValues, EnvironmentKey
│   │   │   ├── Preferences.swift      # PreferenceKey, PreferenceValues (bottom-up)
│   │   │   ├── Theme.swift            # Theme protocol, predefined themes (Phosphor, ncurses, etc.)
│   │   │   ├── AppStorage.swift       # @AppStorage, @SceneStorage, StorageBackend
│   │   │   └── UserDefaultsStorage.swift # Platform-specific UserDefaults implementation
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
│   │       ├── Card.swift             # Styled bordered container
│   │       ├── Box.swift              # Simple bordered container
│   │       ├── Panel.swift            # Titled bordered container
│   │       ├── Button.swift           # Interactive button with focus
│   │       ├── Menu.swift             # Menu with selection and shortcuts
│   │       ├── Alert.swift            # Modal alert with presets
│   │       ├── Dialog.swift           # Modal dialog + .modal() modifier
│   │       └── StatusBar.swift        # TStatusBar, TStatusBarItem, Shortcut
│   └── SwiftTUIExample/               # Executable example target
│       ├── main.swift
│       ├── AppState.swift
│       ├── ContentView.swift
│       ├── Components/
│       │   ├── HeaderView.swift
│       │   └── DemoSection.swift
│       └── Pages/
│           ├── MainMenuPage.swift
│           ├── TextStylesPage.swift
│           ├── ColorsPage.swift
│           ├── ContainersPage.swift
│           ├── OverlaysPage.swift
│           ├── LayoutPage.swift
│           └── ButtonsPage.swift
└── Tests/
    └── SwiftTUITests/
        ├── TViewTests.swift
        ├── StatusBarTests.swift
        ├── ButtonTests.swift
        ├── FocusTests.swift
        ├── ColorTests.swift
        ├── ContainerViewTests.swift
        ├── FrameBufferTests.swift
        └── RenderingTests.swift
```

## Architecture

### Core Patterns

- **TView** is a protocol (value types, like SwiftUI's View)
- **@TViewBuilder** is a `@resultBuilder` supporting up to 10 children, conditionals, optionals, for-in
- **Primitive views** have `body: Never` and conform to `Renderable`
- **Composite views** define `body` — renderer walks tree recursively
- **Environment** for top-down data flow (theme, statusBar, etc.)
- **Preferences** for bottom-up data flow (child → parent)

### Rendering Pipeline

1. `AppRunner` manages the run loop
2. `renderToBuffer()` traverses view tree
3. Views conforming to `Renderable` produce `FrameBuffer`
4. Composite views recurse via `body`
5. `FrameBuffer` supports character-level compositing for overlays

### Data Flow

- **Environment** (top-down): Theme, StatusBar, custom values
- **Preferences** (bottom-up): Navigation title, anchors, custom values
- **@TState**: Local view state with automatic re-render
- **@AppStorage**: Persistent settings (JSON file or UserDefaults)
- **@SceneStorage**: Scene state restoration

### Platform Support

- **macOS**: Full support with UserDefaults
- **Linux**: Full support with JSON file storage, XDG paths

## Conventions

- All code comments and documentation in English
- Communication with user in German (informal Du)
- Feature work on dedicated branches
- No external dependencies
- No singletons for state (use Environment instead)

## Current Branch

`feature/tview-foundation`

## Test Execution

```bash
swift test --no-parallel
```

Note: `--no-parallel` required due to FocusManager singleton (candidate for Environment refactoring)
