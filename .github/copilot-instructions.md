# Copilot Instructions for TUIkit

## Hard Constraints (non-negotiable)

- **Swift 6.0 only**: `swift-tools-version: 6.0`. Never use features that require a newer compiler.
- **Cross-platform**: Must build and run on both macOS and Linux. CI tests both (`macos-15` + `swift:6.0` container).
- **CI must pass**: All tests and linting must pass before merge.

## Project

TUIkit is a SwiftUI-like framework for building Terminal User Interfaces in pure Swift: no ncurses or C dependencies.

## Build, Test & Lint

```bash
# Build
swift build

# Run all tests (1037+ tests, Swift Testing framework)
swift test

# Run a single test suite
swift test --filter <TestSuiteName>

# Lint
swiftlint

# Format (configured but not enforced in CI)
swift-format format -i -r Sources Tests
```

## Architecture

### View System

TUIkit uses a dual rendering system:

1. **Composite views**: Implement `body` to compose other views. The renderer recurses into `body`.
2. **Primitive views**: Conform to `Renderable` and produce a `FrameBuffer` directly. Set `body: Never`.

The `renderToBuffer(_:context:)` function checks `Renderable` first, then falls back to `body`.

### View Architecture Rules

- Every **public** control must be a `View` with a real `body: some View`
- The `body` must return actual Views (not `Never`, not `fatalError()`)
- `Renderable` is only for leaf nodes (`Text`, `Spacer`, `Divider`) and private `_*Core` views
- All modifiers must propagate through the entire View hierarchy
- Environment values must flow down automatically

**The `_*Core` pattern:**
```swift
// Public View: real body, environment flows through
public struct MyControl<Content: View>: View {
    let content: Content
    public var body: some View {
        _MyControlCore(content: content)
    }
}

// Private Core: Renderable for terminal-specific rendering
private struct _MyControlCore<Content: View>: View, Renderable {
    let content: Content
    var body: Never { fatalError() }
    func renderToBuffer(context: RenderContext) -> FrameBuffer { ... }
}
```

Prefer pure composition (combining existing Views + modifiers) over `_*Core` + `Renderable`.

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

## SwiftUI API Parity (non-negotiable)

Public APIs **must** match SwiftUI signatures exactly unless terminal constraints require deviation.

| Aspect | Requirement |
|--------|-------------|
| Parameter names | Exact (`isPresented`, not `isVisible`) |
| Parameter order | Exact (title, binding, actions, message) |
| Parameter types | Match closely (ViewBuilder closures, not pre-built values) |
| Trailing closures | `@ViewBuilder () -> T`, not `String` |

**Before implementing any SwiftUI-equivalent API:** Look up the exact SwiftUI signature first.

## General Rules

- **No singletons**: All state flows through the Environment system
- **Search the codebase** for similar patterns before implementing anything new
- **Consolidate and reuse** before adding new functions or types
- **Never merge PRs autonomously**: Stop after creating, let the user merge

## Testing

- Uses Swift Testing framework (`@Test`, `#expect`, `@Suite`)
- Tests run in parallel
- Test files mirror source structure in `Tests/TUIkitTests/`

## Code Style

- Line length: 140 characters (warning), 200 (error)
- 4-space indentation
- Trailing commas in multi-line collections
- See `.swiftlint.yml` and `.swift-format` for full configuration
