# Theming Guide

Customize the visual appearance of your TUIkit application with palettes.

## Overview

TUIkit includes a full theming system with seven built-in palettes inspired by classic CRT terminals. Palettes define semantic colors for backgrounds, foregrounds, accents, and UI elements.

## Built-in Palettes

| Palette | Struct | Inspiration |
|---------|--------|-------------|
| Green | ``GreenPalette`` | IBM 5151, Apple II |
| Amber | ``AmberPalette`` | IBM 3278, Wyse 50 |
| Red | ``RedPalette`` | Military terminals |
| Violet | ``VioletPalette`` | Retro sci-fi displays |
| Blue | ``BluePalette`` | VFD displays |
| White | ``WhitePalette`` | DEC VT100, VT220 |
| ncurses | ``NCursesPalette`` | Classic ncurses apps |

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
    .backgroundColor(.palette.containerBodyBackground)
```

Or read the palette directly from the environment:

```swift
@Environment(\.palette) var palette

Text("Hello").foregroundColor(palette.accent)
```

## Creating Custom Palettes

Implement the ``Palette`` protocol:

```swift
struct MyCustomPalette: Palette {
    let id = "custom"
    let name = "Custom"

    let background = Color.hex(0x1A1A2E)
    let foreground = Color.hex(0xE0E0E0)
    let accent = Color.hex(0x00D4FF)

    // ... implement remaining required properties
    // Many have default implementations via Palette extension
}
```

## Palette Color Properties

The ``Palette`` protocol defines these semantic color categories:

- **Backgrounds**: `background`, `containerBodyBackground`, `containerCapBackground`, `buttonBackground`, `statusBarBackground`, `appHeaderBackground`, `overlayBackground`
- **Foregrounds**: `foreground`, `foregroundSecondary`, `foregroundTertiary`
- **Accents**: `accent`, `accentSecondary`
- **Semantic**: `success`, `warning`, `error`, `info`
- **UI Elements**: `border`, `borderFocused`, `separator`, `selection`, `selectionBackground`, `disabled`
- **Status Bar**: `statusBarForeground`, `statusBarHighlight`

Many of these have default implementations that derive from the primary colors, so a minimal palette only needs to define a handful of values.
