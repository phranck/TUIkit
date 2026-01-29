# ``TUIKit``

Build beautiful, interactive terminal user interfaces in Swift.

## Overview

TUIKit is a modern Swift framework for creating sophisticated terminal user interfaces (TUIs) on macOS and Linux. It provides a declarative, SwiftUI-like API with support for themes, styling, focus management, and interactive components.

### Key Features

- **Declarative UI**: Build interfaces using Swift's result builders and view composition
- **5 Appearance Styles**: line, rounded, doubleLine, heavy, and block rendering modes
- **4 Phosphor Themes**: Green, Amber, White, and Red with customizable colors
- **Rich Components**: Text, Button, Menu, Alert, Dialog, Card, Panel, and more
- **Focus Management**: Tab/Shift+Tab navigation with keyboard shortcuts
- **State Management**: `@State`, `@Environment`, `@AppStorage`, `@SceneStorage` property wrappers
- **No Dependencies**: Pure Swift implementation for macOS 10.15+ and Linux

## Getting Started

Create your first TUIKit app in minutes:

```swift
import TUIKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 1) {
                Text("Welcome to TUIKit!")
                    .bold()
                    .foregroundColor(.theme.accent)

                Spacer()

                Button("Press me") {
                    print("Button pressed!")
                }

                Spacer()
            }
            .padding()
        }
    }
}
```

Run with: `swift run`

## Topics

### Essentials

- ``View``
- ``App``
- ``Scene``
- ``@main``

### Building Views

- <doc:ViewHierarchy>
- <doc:GettingStarted>
- ``VStack``
- ``HStack``
- ``ZStack``
- ``ForEach``

### Interactive Components

- ``Button``
- ``Menu``
- ``Alert``
- ``Dialog``
- ``Text``

### Styling & Appearance

- <doc:Theming>
- <doc:Appearance>
- ``Color``
- ``Theme``
- ``Appearance``

### Layout & Modifiers

- <doc:Modifiers>
- ``View/padding(_:)-19gu9``
- ``View/frame(width:height:alignment:)``
- ``View/border(_:style:)-4xzvw``

### State Management

- <doc:StateManagement>
- ``State``
- ``Binding``
- ``@Environment``
- ``@AppStorage``

### Advanced Topics

- <doc:Focus>
- <doc:Architecture>
- <doc:Rendering>
- ``FocusManager``
- ``KeyEvent``

### Examples

- <doc:BuildYourFirstApp>
- <doc:BuildInteractiveMenu>
- <doc:BuildThemableUI>

## Resources

- [GitHub Repository](https://github.com/anthropics/SwiftTUI)
- [Example Application](https://github.com/anthropics/SwiftTUI/tree/main/Sources/TUIKitExample)
- [Issue Tracker](https://github.com/anthropics/SwiftTUI/issues)

## Minimum Requirements

- Swift 6.0 or later
- macOS 10.15+ or Linux (glibc)
- Terminal with ANSI color support (256 colors or better)
