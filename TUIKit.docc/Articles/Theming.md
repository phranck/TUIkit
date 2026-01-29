# Theming System

Customize the appearance of your application with TUIKit's flexible theming system.

## Built-in Themes

TUIKit includes 4 beautiful phosphor-style themes:

### Green Theme

Classic green phosphor aesthetic for a retro terminal feel:

```swift
.environment(\.themeManager.currentTheme, .green)
```

- **Accent**: Bright green
- **Background**: Deep dark green
- **Foreground**: Light green text

### Amber Theme

Warm amber/orange phosphor theme:

```swift
.environment(\.themeManager.currentTheme, .amber)
```

- **Accent**: Bright amber
- **Background**: Dark brown-orange
- **Foreground**: Light amber text

### White Theme

Cool white/blue-tinted theme for modern appearance:

```swift
.environment(\.themeManager.currentTheme, .white)
```

- **Accent**: Bright white
- **Background**: Deep blue-black
- **Foreground**: Light white text

### Red Theme

Bold red phosphor theme:

```swift
.environment(\.themeManager.currentTheme, .red)
```

- **Accent**: Bright red
- **Background**: Dark red-black
- **Foreground**: Light red text

## Using Themes

### Default Theme

By default, the Green theme is active:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Switching Themes

Use the theme manager to switch themes at runtime:

```swift
struct App: View {
    @Environment(\.themeManager) var themeManager

    var body: some View {
        VStack {
            Button("Switch to Amber") {
                themeManager.currentTheme = .amber
            }
            Button("Switch to White") {
                themeManager.currentTheme = .white
            }
        }
    }
}
```

### Accessing Theme Colors

Use `Color.theme` shorthand to access current theme colors:

```swift
VStack {
    Text("This uses the theme accent color")
        .foregroundColor(.theme.accent)

    Text("This uses the theme foreground")
        .foregroundColor(.theme.foreground)

    Text("This uses secondary text color")
        .foregroundColor(.theme.foregroundSecondary)
}
```

## Theme Protocol

Themes conform to the ``Theme`` protocol:

```swift
public protocol Theme {
    var background: Color { get }
    var containerBackground: Color { get }
    var containerHeaderBackground: Color { get }
    var buttonBackground: Color { get }
    var statusBarBackground: Color { get }
    var foreground: Color { get }
    var foregroundSecondary: Color { get }
    var foregroundTertiary: Color { get }
    var accent: Color { get }
    var border: Color { get }
    var statusBarForeground: Color { get }
}
```

## Creating Custom Themes

Implement the `Theme` protocol to create custom themes:

```swift
struct CompanyTheme: Theme {
    let background = Color.hex("0a0a0a")
    let containerBackground = Color.hex("1a1a2e")
    let containerHeaderBackground = Color.hex("16213e")
    let buttonBackground = Color.hex("0f3460")
    let statusBarBackground = Color.hex("0f3460")
    let foreground = Color.hex("eaeaea")
    let foregroundSecondary = Color.hex("999999")
    let foregroundTertiary = Color.hex("666666")
    let accent = Color.hex("00d4ff")
    let border = Color.hex("00d4ff")
    let statusBarForeground = Color.hex("666666")
}

// Use it
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.themeManager.currentTheme, CompanyTheme())
        }
    }
}
```

## Color System

TUIKit supports multiple color spaces:

### ANSI Colors

Use standard terminal colors:

```swift
Color.ansi(.brightGreen)
Color.ansi(.red)
```

### Hex Colors

Specify colors as hex strings or integers:

```swift
Color.hex("FF5500")
Color.hex("#FF5500")
Color.hex(0xFF5500)
```

### RGB Colors

Define colors by RGB values:

```swift
Color.rgb(red: 255, green: 85, blue: 0)
Color.rgb(red: 1.0, green: 0.33, blue: 0.0)
```

### 256-Color Palette

Use 256-color terminal palette (0-255):

```swift
Color.palette256(196)
```

### HSL Colors

Create colors using HSL (Hue, Saturation, Lightness):

```swift
Color.hsl(hue: 25, saturation: 100, lightness: 50)
```

## Color Modifiers

Adjust colors programmatically:

```swift
let baseColor = Color.hex("#FF5500")

let lighter = baseColor.lighter(by: 0.2)
let darker = baseColor.darker(by: 0.3)
let transparent = baseColor.opacity(0.5)
```

## Theme Cycling

The example app supports theme cycling with the `t` key:

```swift
@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .statusBarItems {
                    StatusBarItem(
                        label: "Theme",
                        shortcut: Shortcut.letter("t"),
                        action: {
                            // Cycle themes
                        }
                    )
                }
        }
    }
}
```

## Best Practices

1. **Use semantic colors**: Reference `Color.theme.accent` instead of hardcoding colors
2. **Test readability**: Ensure sufficient contrast in custom themes
3. **Support all modes**: Create both dark and light themed colors if needed
4. **Store preferences**: Use `@AppStorage` to remember user theme choice
5. **Provide visual feedback**: Show current theme in settings

## Related Topics

- ``Color``
- ``Theme``
- ``ThemeManager``
- <doc:Appearance>
- <doc:StateManagement>
