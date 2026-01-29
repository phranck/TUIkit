# TUIKit

A declarative, SwiftUI-like framework for building Terminal User Interfaces in Swift — no ncurses, no C dependencies, just pure Swift.

## Features

- **Declarative API**: Build UIs with a familiar, SwiftUI-like syntax
- **Zero Dependencies**: Pure Swift implementation, no external C libraries
- **Multiple Appearance Styles**: Support for different terminal themes and styles
- **Keyboard Navigation**: Full keyboard support with customizable keybindings
- **Cross-Platform**: Works on macOS and Linux

## Quick Start

```swift
import TUIKit

struct MyApp: View {
    var body: some View {
        VStack {
            Text("Hello, TUIKit!")
                .bold()

            Button("Press me") {
                print("Button pressed!")
            }
        }
    }
}

let app = MyApp()
app.run()
```

## Installation

Add this to your `Package.swift`:

```swift
.package(url: "https://github.com/phranck/SwiftTUI.git", from: "1.0.0")
```

Or use Xcode to add it via `File > Add Packages`.

## Next Steps

- [Getting Started Guide](getting-started.md) - Learn the basics
- [API Reference](api/tuikit.md) - Explore all available components
- [GitHub Repository](https://github.com/phranck/SwiftTUI) - View source code
