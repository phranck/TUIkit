# ``TUIkit``

A declarative, SwiftUI-like framework for building Terminal User Interfaces in Swift.

@Metadata {
    @DisplayName("TUIkit")
    @PageImage(purpose: icon, source: "tuikit-logo", alt: "TUIkit Logo")
    @PageImage(purpose: card, source: "tuikit-logo", alt: "TUIkit Logo")
}

## Overview

TUIkit lets you build terminal applications using a familiar, declarative syntax inspired by SwiftUI. No ncurses, no C dependencies — pure Swift.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("Hello, TUIkit!")
                    .bold()
                    .foregroundColor(.cyan)
                Button("Press me") {
                    // handle action
                }
            }
        }
    }
}
```

### Key Features

- **Declarative syntax** — Build UIs with `VStack`, `HStack`, `Text`, `Button`, and more
- **SwiftUI-like API** — `@State`, `@ViewBuilder`, environment values, modifiers
- **Theming system** — 5 built-in phosphor themes with full RGB color support
- **Focus management** — Keyboard-driven navigation between interactive elements
- **Status bar** — Configurable shortcut bar with context stack
- **No dependencies** — Pure Swift, no ncurses or other C libraries
- **Cross-platform** — macOS and Linux

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- <doc:AppLifecycle>

### App Structure

- ``App``
- ``Scene``
- ``WindowGroup``

### Views

- ``View``
- ``Text``
- ``Button``
- ``Menu``
- ``Alert``
- ``Dialog``

### Layout

- ``VStack``
- ``HStack``
- ``ZStack``
- ``Spacer``
- ``ForEach``

### Containers

- ``Box``
- ``Card``
- ``Panel``
- ``ContainerView``

### State Management

- <doc:StateManagement>
- ``State``
- ``Binding``
- ``AppState``

### Environment

- ``EnvironmentKey``
- ``EnvironmentValues``

### Theming

- <doc:ThemingGuide>
- ``Palette``
- ``ThemeManager``
- ``PaletteRegistry``
- ``GreenPalette``
- ``AmberPalette``
- ``WhitePalette``
- ``RedPalette``
- ``NCursesPalette``

### Colors

- ``Color``
- ``ANSIColor``

### View Composition

- ``ViewBuilder``
- ``ViewModifier``
- ``ModifiedView``

### Appearance

- ``Appearance``
- ``BorderStyle``

### Focus System

- ``FocusManager``

### Status Bar

- ``StatusBar``
- ``StatusBarState``
- ``StatusBarItem``
- ``StatusBarItemProtocol``
- ``StatusBarStyle``
- ``StatusBarAlignment``

### Input Handling

- ``KeyEvent``
- ``QuitBehavior``

### Rendering

- ``Renderable``
- ``FrameBuffer``
- ``RenderContext``

### Persistence

- ``AppStorage``
