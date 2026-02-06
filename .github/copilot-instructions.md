# Copilot Instructions for TUIkit

TUIkit is a SwiftUI-like framework for building Terminal User Interfaces in pure Swift: no ncurses or C dependencies.

## Build, Test & Lint

```bash
# Build
swift build

# Run all tests (503 tests, Swift Testing framework)
swift test

# Run a single test file
swift test --filter <TestSuiteName>

# Run a specific test
swift test --filter <TestSuiteName>/<testMethodName>

# Lint
swiftlint

# Format (optional - configured but not enforced in CI)
swift-format format -i -r Sources Tests
```

## Architecture

### Dual Rendering System

TUIkit uses two rendering paths:

1. **Composite views**: Implement `body` to compose other views. The renderer recurses into `body`.
2. **Primitive views**: Conform to `Renderable` protocol and produce a `FrameBuffer` directly. Set `body: Never` (with `fatalError()`).

The `renderToBuffer(_:context:)` function checks `Renderable` first, then falls back to `body`.

**When adding a new view:**
- Composing other views → implement `body`, skip `Renderable`
- Producing terminal output directly → conform to `Renderable`, set `body: Never`

### Key Components

- **`FrameBuffer`**: 2D grid of styled cells representing terminal output
- **`RenderContext`**: Carries layout constraints, environment values, and `TUIContext`
- **`TUIContext`**: Central DI container for lifecycle, key events, preferences, state storage
- **`ViewIdentity`**: Structural identity path for `@State` persistence across renders

### Directory Structure

```
Sources/TUIkit/
├── App/           App lifecycle, Scene, WindowGroup
├── Core/          View protocol, ViewBuilder, TupleViews
├── Environment/   EnvironmentValues, @Environment
├── State/         @State, StateStorage, @AppStorage
├── Rendering/     FrameBuffer, Renderable, Terminal, ANSIRenderer
├── Modifiers/     Border, Frame, Padding, Overlay, Lifecycle
├── Views/         Text, Stacks, Button, Menu, Alert, Dialog, etc.
├── Focus/         FocusManager, focus sections
├── Styling/       Color, Palette, Theme
└── StatusBar/     StatusBar, StatusBarItem
```

## Key Conventions

### SwiftUI API Parity (Non-Negotiable)

Public APIs **must** match SwiftUI signatures exactly unless terminal constraints require deviation.

| Aspect | Requirement |
|--------|-------------|
| Parameter names | Exact (`isPresented`, not `isVisible`) |
| Parameter order | Exact (title, binding, actions, message) |
| Parameter types | Match closely (ViewBuilder closures, not pre-built values) |
| Trailing closures | `@ViewBuilder () -> T`, not `String` |

**Before implementing any SwiftUI-equivalent API:** Look up the exact SwiftUI signature first.

### Architecture Rules

- **No singletons**: All state flows through the Environment system
- **Consolidate existing functions** before adding new ones
- **Never merge PRs autonomously**: Stop after creating, let the user merge

### Testing

- Uses Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Tests run in parallel
- Test files mirror source structure in `Tests/TUIkitTests/`

### Code Style

- Line length: 140 characters (warning), 200 (error)
- 4-space indentation
- Trailing commas in multi-line collections (swift-format enforced)
- See `.swiftlint.yml` and `.swift-format` for full configuration
