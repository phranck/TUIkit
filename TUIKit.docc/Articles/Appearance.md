# Appearance System

Learn about the 5 structural appearance styles for rendering borders and containers.

## Overview

TUIKit provides 5 appearance styles that control how borders and containers are rendered:

- **Line**: Simple ASCII lines
- **Rounded**: Rounded corners (default)
- **DoubleLine**: Double-line borders
- **Heavy**: Heavy/bold borders
- **Block**: Half-block Unicode characters for solid appearance

## Appearance Styles

### Line Appearance

Simple single-line ASCII borders:

```swift
VStack {
    Text("Content")
}
.border(.line)
```

Characters used:
- Horizontal: `-`
- Vertical: `|`
- Corners: `+`

### Rounded Appearance

Rounded corners (default appearance):

```swift
VStack {
    Text("Content")
}
.border(.rounded)
```

Characters used:
- Top-left: `╭`
- Top-right: `╮`
- Bottom-left: `╰`
- Bottom-right: `╯`
- Horizontal: `─`
- Vertical: `│`

### DoubleLine Appearance

Double-line borders for emphasis:

```swift
VStack {
    Text("Content")
}
.border(.doubleLine)
```

Characters used:
- Top-left: `╔`
- Top-right: `╗`
- Bottom-left: `╚`
- Bottom-right: `╝`
- Horizontal: `═`
- Vertical: `║`

### Heavy Appearance

Bold/heavy borders:

```swift
VStack {
    Text("Content")
}
.border(.heavy)
```

Characters used:
- Top-left: `┏`
- Top-right: `┓`
- Bottom-left: `┗`
- Bottom-right: `┛`
- Horizontal: `━`
- Vertical: `┃`

### Block Appearance

Modern half-block Unicode characters for a solid, integrated look:

```swift
VStack {
    Text("Content")
}
.border(.block)
```

Special rendering:
- **Top border**: `▄` (lower half-block) with foreground = container background
- **Side borders**: `█` (full block) with foreground = container background
- **Bottom border**: `▀` (upper half-block) with foreground = container background
- **Content**: Filled with container background color
- Uses full-block characters to create solid visual edges

The block appearance creates a seamless, filled container that appears integrated with the terminal background.

## Setting Global Appearance

Use the appearance environment to set the default for all components:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appearance, .block)
        }
    }
}
```

## Cycling Appearances

The example app supports appearance cycling with the `a` key:

```swift
@main
struct ExampleApp: App {
    @State private var currentAppearance: Appearance = .rounded

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appearance, currentAppearance)
                .statusBarItems {
                    StatusBarItem(
                        label: "Appearance",
                        shortcut: Shortcut.letter("a"),
                        action: {
                            currentAppearance = currentAppearance.next()
                        }
                    )
                }
        }
    }
}
```

## Using Appearance with Containers

All container views respect the appearance setting:

```swift
// Using Panel with different appearances
VStack {
    Panel(title: "Settings") {
        Text("Configure options here")
    }
    .border(.rounded)

    Panel(title: "Status") {
        Text("System information")
    }
    .border(.block)

    Card {
        Text("Card content")
    }
    .border(.heavy)
}
```

## BorderStyle

Use the ``BorderStyle`` type to customize individual borders:

```swift
extension View {
    func border(
        _ style: BorderStyle = .default,
        width: Int = 1,
        color: Color = .theme.border,
        appearance: Appearance = .rounded
    ) -> some View {
        // Returns bordered view
    }
}

// Custom border
Text("Custom border")
    .border(.custom, width: 2, color: .theme.accent)
```

## Appearance in Components

Different components use appearance differently:

### Text with Border

```swift
Text("Bordered text")
    .border(.block)
```

### Card with Appearance

```swift
Card {
    Text("Content")
}
.border(.rounded)
```

### Panel with Title

```swift
Panel(title: "Title") {
    Text("Content")
}
.border(.block)
```

### Alerts and Dialogs

Alerts automatically use the current appearance:

```swift
Alert(
    title: "Confirm",
    message: "Are you sure?",
    borderColor: .theme.border,
    titleColor: .theme.accent
)
```

## Best Practices

1. **Consistency**: Choose one appearance and stick with it
2. **Theme integration**: Use theme colors for borders
3. **Readability**: Ensure sufficient contrast for borders
4. **Performance**: Complex borders render efficiently
5. **Testing**: Test appearance on various terminal sizes

## Related Topics

- ``Appearance``
- ``BorderStyle``
- ``View/border(_:style:)-4xzvw``
- <doc:Theming>
- ``Panel``
- ``Card``
- ``ContainerView``
