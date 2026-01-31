# Appearance and Colors

Control border styles, visual appearances, and the color system.

## Overview

TUIkit separates visual styling into two systems:

- **Appearance** — Controls border characters and container styling (rounded, doubleLine, block, etc.)
- **Colors** — A palette-aware color system with semantic tokens that resolve at render time

Both systems integrate with the theming pipeline described in <doc:ThemingGuide>.

## Appearances

An ``Appearance`` defines the border characters used by containers and the `.border()` modifier. TUIkit ships with five built-in appearances:

| Appearance | Border Characters | Example |
|------------|-------------------|---------|
| `.line` | `─ │ ┌ ┐ └ ┘` | Thin ASCII lines |
| `.rounded` | `─ │ ╭ ╮ ╰ ╯` | Rounded corners (default) |
| `.doubleLine` | `═ ║ ╔ ╗ ╚ ╝` | Double-line borders |
| `.heavy` | `━ ┃ ┏ ┓ ┗ ┛` | Bold / heavy lines |
| `.block` | `█ ▄ ▀` | Half-block characters (smooth look) |

### Setting the Appearance

The active appearance flows through the environment:

```swift
// Set appearance for all children
VStack {
    Panel("Settings") {
        Text("Uses doubleLine borders")
    }
}
.environment(\.appearance, .doubleLine)
```

### Cycling Appearances at Runtime

Users can press `a` to cycle through appearances. The ``ThemeManager`` handles this via the `AppearanceRegistry`.

### Custom Appearances

Register additional appearances with the `AppearanceRegistry`:

```swift
let custom = Appearance(
    id: .init("dashed"),
    borderStyle: .line,  // or create a custom BorderStyle
    displayName: "Dashed"
)
```

## The Color System

TUIkit's ``Color`` type supports multiple color modes:

### Standard ANSI Colors (8)

```swift
.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white
```

### Bright ANSI Colors (8)

```swift
.brightBlack, .brightRed, .brightGreen, .brightYellow,
.brightBlue, .brightMagenta, .brightCyan, .brightWhite
```

### 256-Color Palette

```swift
Color.palette256(index: 202)  // orange
```

### True Color (RGB)

```swift
Color.rgb(255, 128, 0)   // orange via RGB components
Color.hex(0xFF8000)       // orange via hex integer
Color.hex("#FF8000")      // orange via hex string
Color.hsl(30, 1.0, 0.5)  // orange via HSL
```

### Color Manipulation

```swift
let lighter = color.lighter(by: 0.2)  // 20% lighter
let darker = color.darker(by: 0.3)    // 30% darker
```

## Semantic Colors

`SemanticColor` provides palette-aware color tokens that resolve at render time. This is the bridge between the color system and the theming system.

### In View Bodies (no RenderContext)

Use `Color.palette.*` — these return semantic tokens:

```swift
Text("Hello")
    .foregroundColor(.palette.accent)    // resolves to palette's accent color
    .background(.palette.containerBodyBackground)
```

Available semantic tokens include:

| Token | Typical Use |
|-------|-------------|
| `.palette.foreground` | Primary text |
| `.palette.foregroundSecondary` | Secondary / dimmed text |
| `.palette.accent` | Highlighted elements, titles |
| `.palette.border` | Container borders |
| `.palette.borderFocused` | Focused element borders |
| `.palette.containerBodyBackground` | Container body / content area background |
| `.palette.containerCapBackground` | Container header / footer background |
| `.palette.success` / `.warning` / `.error` / `.info` | Status indicators |
| `.palette.selection` / `.selectionBackground` | Selected items |
| `.palette.disabled` | Inactive elements |

### In renderToBuffer (with RenderContext)

Use `context.environment.palette.*` directly — these return concrete colors:

```swift
func renderToBuffer(context: RenderContext) -> FrameBuffer {
    let accent = context.environment.palette.accent
    let border = context.environment.palette.border
    // use directly with ANSIRenderer
}
```

> Important: Unresolved semantic colors hitting the `ANSIRenderer` trigger a `fatalError`. Always resolve via `Color.resolve(with:)` or use `context.environment.palette.*` in rendering code.

## BorderStyle

``BorderStyle`` defines the actual Unicode characters for border rendering:

```swift
public struct BorderStyle {
    let topLeft, topRight, bottomLeft, bottomRight: Character
    let horizontal, vertical: Character
    let leftT, rightT, topT, bottomT, cross: Character
}
```

Built-in styles: `.line`, `.rounded`, `.doubleLine`, `.heavy`. The `.block` appearance uses special half-block rendering instead of `BorderStyle` characters.
