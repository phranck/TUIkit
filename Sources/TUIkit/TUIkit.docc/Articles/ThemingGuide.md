# Theming Guide

Customize the visual appearance of your TUIkit application with palettes.

## Overview

TUIkit includes a full theming system with six built-in palettes inspired by classic CRT terminals. Palettes define semantic colors for backgrounds, foregrounds, accents, and UI elements.

## Built-in Palettes

| Palette | Struct | Inspiration |
|---------|--------|-------------|
| Green | ``GreenPalette`` | IBM 5151, Apple II |
| Amber | ``AmberPalette`` | IBM 3278, Wyse 50 |
| Red | ``RedPalette`` | Military terminals |
| Violet | ``VioletPalette`` | Retro sci-fi displays |
| Blue | ``BluePalette`` | VFD displays |
| White | ``WhitePalette`` | DEC VT100, VT220 |

## Using Palettes

### Via PaletteManager

Access the palette manager through the environment to cycle or set palettes:

```swift
struct MyView: View {
    @Environment(\.paletteManager) var paletteManager

    var body: some View {
        VStack {
            Text("Current: \(paletteManager.currentName)")
            Button("Next Palette") {
                paletteManager.cycleNext()
            }
        }
    }
}
```

### Via Environment

Set a palette for a view and all its descendants:

```swift
ContentView()
    .palette(AmberPalette())
```

### Palette Colors in Views

Use ``Color/palette`` to access the current palette's colors:

```swift
Text("Styled text")
    .foregroundColor(.palette.foreground)
    .backgroundColor(.palette.surfaceBackground)
```

Or read the palette directly from the environment:

```swift
@Environment(\.palette) var palette

Text("Hello").foregroundColor(palette.accent)
```

## Creating Custom Palettes

### Minimal Palette (Palette protocol)

Implement the ``Palette`` protocol for a palette with just the essential colors:

```swift
struct MyCustomPalette: Palette {
    let id = "custom"
    let name = "Custom"

    let background = Color.hex(0x1A1A2E)
    let foreground = Color.hex(0xE0E0E0)
    let accent = Color.hex(0x00D4FF)
    let success = Color.hex(0x00FF88)
    let warning = Color.hex(0xFFCC00)
    let error = Color.hex(0xFF4444)
    let info = Color.hex(0x44AAFF)
    let border = Color.hex(0x333355)

    // Optional: override defaults for statusBarBackground,
    // appHeaderBackground, overlayBackground,
    // foregroundSecondary, foregroundTertiary
}
```

### Block-Aware Palette (BlockPalette protocol)

For palettes that provide block-appearance surface colors, conform to ``BlockPalette``:

```swift
struct MyBlockPalette: BlockPalette {
    let id = "custom-block"
    let name = "Custom Block"

    // ... same required properties as Palette ...

    // Optional: override computed defaults
    // var surfaceBackground: Color { ... }
    // var surfaceHeaderBackground: Color { ... }
    // var elevatedBackground: Color { ... }
}
```

The ``BlockPalette`` defaults compute surface colors from `background` using `lighter(by:)`:
- `surfaceBackground` = `background.lighter(by: 0.08)`
- `surfaceHeaderBackground` = `background.lighter(by: 0.05)`
- `elevatedBackground` = `surfaceHeaderBackground.lighter(by: 0.05)`

## Palette Color Properties

### Palette (Base Protocol)

- **Backgrounds**: `background`, `statusBarBackground`, `appHeaderBackground`, `overlayBackground`
- **Foregrounds**: `foreground`, `foregroundSecondary`, `foregroundTertiary`
- **Accent**: `accent`
- **Semantic**: `success`, `warning`, `error`, `info`
- **UI Elements**: `border`

### BlockPalette (extends Palette)

- **Surfaces**: `surfaceBackground`, `surfaceHeaderBackground`, `elevatedBackground`

Only 8 properties are required (`background`, `foreground`, `accent`, `border`, `success`, `warning`, `error`, `info`). All others have default implementations that derive from these.
