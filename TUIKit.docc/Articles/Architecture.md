# Architecture Overview

Understand the architecture and design patterns that power TUIKit.

## Core Design Principles

TUIKit follows these key principles:

1. **Declarative UI**: Describe what you want, not how to build it
2. **Composability**: Build complex UIs from simple, reusable components
3. **Value Semantics**: Views are lightweight value types, not stateful objects
4. **Data Flow**: Clear, unidirectional data flow through Environment and State
5. **Pure Swift**: No external dependencies or C bindings

## The View System

### View Protocol

The `View` protocol is the foundation of TUIKit:

```swift
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}
```

Views are **not** UI elements—they're descriptions of UI that get rendered when needed. This enables:
- Lightweight composition
- Efficient updates
- Declarative syntax

### Primitive vs Composite Views

**Primitive Views** directly render content:
- Conform to `Renderable`
- Have `body: Never`
- Examples: `Text`, `Button`, `Menu`

**Composite Views** combine other views:
- Define a `body` property
- Renderer walks the tree recursively
- Examples: `VStack`, `HStack`, `Card`

### Rendering Pipeline

1. **View Tree**: User creates view hierarchy
2. **Traversal**: Renderer walks tree depth-first
3. **Rendering**: Primitive views produce `FrameBuffer` character data
4. **Compositing**: Overlays blend on top with character-level precision
5. **Output**: Terminal renders the final buffer

## State Management Architecture

### Local State (@State)

Stored in the view itself:
```swift
@State var count: Int = 0
```

When `@State` changes, the view re-renders automatically.

### Environment (Top-Down)

Parent views pass data to children:

```swift
@Environment(\.theme) var theme

// Theme flows from App → all children
```

### Preferences (Bottom-Up)

Children can propagate values to parents (rarely used in TUIKit).

### Storage (@AppStorage, @SceneStorage)

Persistent storage via:
- **@AppStorage**: UserDefaults (macOS) or JSON file (Linux)
- **@SceneStorage**: Per-scene state restoration

## Data Flow Pattern

```
┌─────────────────────────────────────┐
│           App or Scene              │
│  @AppStorage, @State, Environment   │
└────────┬────────────────────────────┘
         │ passes theme, data
         ▼
┌─────────────────────────────────────┐
│    Composite Views (VStack, etc)    │
│  pass Environment to children       │
└────────┬────────────────────────────┘
         │ may use @State locally
         ▼
┌─────────────────────────────────────┐
│     Primitive Views (Text, Button)  │
│  render to FrameBuffer              │
└─────────────────────────────────────┘
```

## Theme and Appearance System

### Theme Protocol

Defines semantic colors:

```swift
public protocol Theme {
    var background: Color { get }
    var accent: Color { get }
    // ... other colors
}
```

### Appearance Protocol

Defines structural styles:

```swift
public enum Appearance {
    case line, rounded, doubleLine, heavy, block
}
```

Both are passed through Environment, enabling:
- Global theme switching
- Dynamic appearance changes
- Consistent styling across app

## Focus Management System

``FocusManager`` tracks which element has keyboard focus:

1. **Focus ID**: Each interactive element has a unique ID
2. **Navigation**: Tab/Shift+Tab moves focus
3. **Rendering**: Focused element shows visual indicator
4. **Events**: Keyboard events route to focused element

```swift
@Environment(\.focusManager) var focusManager

// Navigation automatically updates focusManager
// onKeyPress receives keyboard events
```

## Modifier System

Modifiers wrap views to add behavior:

```swift
extension View {
    func padding(_ amount: Int) -> some View {
        ModifiedView(content: self, modifier: PaddingModifier(amount))
    }
}
```

Modifiers compose:
```swift
Text("Hello")
    .bold()           // Text → BoldView
    .padding(1)       // BoldView → PaddedView
    .border(.rounded) // PaddedView → BorderedView
```

## Component Library

### Container Views
- `VStack`, `HStack`, `ZStack`: Layout primitives
- `Card`, `Box`, `Panel`: Styled containers
- `ContainerView`: Header/body/footer structure

### Interactive Views
- `Button`: Clickable button with focus
- `Menu`: Selection menu with keyboard
- `Alert`, `Dialog`: Modal overlays

### Structural Views
- `ForEach`: Render collections
- `Text`: Display text
- `Spacer`, `Divider`: Layout helpers

### Status Bar
- `StatusBar`: Application status bar
- `StatusBarItem`: Individual item
- `Shortcut`: Keyboard shortcut display

## Rendering Engine

### FrameBuffer

Character-level buffer for compositing:
- 2D array of characters and attributes
- Supports color, styling (bold, italic, etc.)
- Compositing for overlays

### ANSI Renderer

Converts buffer to ANSI escape codes:
- Color codes (foreground/background)
- Styling (bold, italic, underline)
- Terminal state management

### Terminal Abstraction

Platform-specific terminal handling:
- macOS: termios
- Linux: termios via libc
- Raw mode, alternate screen, signal handling

## Performance Considerations

1. **Lazy Rendering**: Only visible areas render
2. **Diff Optimization**: Only changed areas redraw
3. **Buffer Reuse**: FrameBuffer recycled across frames
4. **View Value Semantics**: Lightweight copying and discarding

## Error Handling

TUIKit uses Swift's error handling:
- Fatal errors for programmer mistakes
- Non-fatal errors for recovery scenarios
- Storage backend errors are silenced (fallback to defaults)

## Platform Support

### macOS
- Native UserDefaults for @AppStorage
- Full terminal support
- Modern Swift runtime

### Linux
- JSON file storage for @AppStorage
- glibc-based terminal support
- XDG paths for configuration

## Future Extensibility

The architecture supports:
- Custom storage backends
- Custom themes
- Custom appearances
- Custom view components
- Animation system (planned)

## Related Topics

- ``View``
- ``Theme``
- ``Appearance``
- ``FocusManager``
- ``FrameBuffer``
- <doc:Rendering>
- <doc:StateManagement>
