# Getting Started

Welcome to TUIKit! This guide will help you build your first Terminal UI application.

## What is TUIKit?

TUIKit is a declarative framework for building Terminal User Interfaces in Swift. It uses the same programming model as SwiftUI, making it familiar and intuitive for Swift developers.

```swift
import TUIKit

struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State var count = 0

    var body: some View {
        VStack(spacing: 1) {
            Text("Hello, TUIKit!")
                .bold()
                .foregroundColor(.green)

            Text("Count: \(count)")

            Button("Increment") {
                count += 1
            }
        }
    }
}
```

## Why TUIKit?

- **No Dependencies**: Pure Swift, no ncurses or C libraries
- **Familiar API**: If you know SwiftUI, you know TUIKit
- **Fast Development**: Declarative syntax means less code
- **Cross-Platform**: Works on macOS and Linux
- **Themeable**: 8 predefined themes + custom styling

## Next Steps

- [Installation](./installation.md) - Add TUIKit to your project
- [Quick Start](./quick-start.md) - Build your first app
- [API Reference](/api/overview.md) - Explore all components
