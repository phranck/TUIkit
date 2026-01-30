# Theming Guide

Customize the visual appearance of your TUIKit application with themes.

## Overview

TUIKit includes a full theming system with five built-in themes inspired by classic CRT terminals. Themes define semantic colors for backgrounds, foregrounds, accents, and UI elements.

## Built-in Themes

| Theme | Struct | Inspiration |
|-------|--------|-------------|
| Green Phosphor | ``GreenPhosphorTheme`` | IBM 5151, Apple II |
| Amber Phosphor | ``AmberPhosphorTheme`` | IBM 3278, Wyse 50 |
| White Phosphor | ``WhitePhosphorTheme`` | DEC VT100, VT220 |
| Red Phosphor | ``RedPhosphorTheme`` | Military terminals |
| ncurses | ``NCursesTheme`` | Classic ncurses apps |

## Using Themes

### Via ThemeManager

Access the ``ThemeManager`` through the environment to cycle or set themes:

```swift
struct MyView: View {
    @Environment(\.themeManager) var themeManager

    var body: some View {
        VStack {
            Text("Current: \(themeManager.currentThemeName)")
            Button("Next Theme") {
                themeManager.cycleTheme()
            }
        }
    }
}
```

### Via Environment

Set a theme for a view and all its descendants:

```swift
ContentView()
    .theme(AmberPhosphorTheme())
```

### Theme Colors in Views

Use ``Color/theme`` to access the current theme's colors:

```swift
Text("Styled text")
    .foregroundColor(.theme.foreground)
    .backgroundColor(.theme.backgroundSecondary)
```

Or read the theme directly from the environment:

```swift
@Environment(\.theme) var theme

Text("Hello").foregroundColor(theme.accent)
```

## Creating Custom Themes

Implement the ``Theme`` protocol:

```swift
struct MyCustomTheme: Theme {
    let id = "custom"
    let name = "Custom"

    let background = Color.hex(0x1A1A2E)
    let foreground = Color.hex(0xE0E0E0)
    let accent = Color.hex(0x00D4FF)

    // ... implement remaining required properties
    // Many have default implementations via Theme extension
}
```

## Theme Color Properties

The ``Theme`` protocol defines these semantic color categories:

- **Backgrounds**: `background`, `backgroundSecondary`, `backgroundTertiary`
- **Foregrounds**: `foreground`, `foregroundSecondary`, `foregroundTertiary`
- **Accents**: `accent`, `accentSecondary`
- **Semantic**: `success`, `warning`, `error`, `info`
- **UI Elements**: `border`, `borderFocused`, `separator`, `selection`, `disabled`
- **Status Bar**: `statusBarBackground`, `statusBarForeground`, `statusBarHighlight`
- **Containers**: `containerBackground`, `containerHeaderBackground`, `buttonBackground`

Many of these have default implementations that derive from the primary colors, so a minimal theme only needs to define a handful of values.
