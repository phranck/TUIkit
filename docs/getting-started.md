# Getting Started with TUIKit

This guide will help you build your first Terminal UI application with TUIKit.

## Installation

### Swift Package Manager

Add TUIKit to your `Package.swift`:

```swift
let package = Package(
    name: "MyTUIApp",
    dependencies: [
        .package(url: "https://github.com/phranck/SwiftTUI.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MyTUIApp",
            dependencies: ["TUIKit"]
        )
    ]
)
```

### Building Your First App

Create a new Swift Package:

```bash
swift package init --type executable --name MyTUIApp
cd MyTUIApp
```

Update your `main.swift`:

```swift
import TUIKit

struct MyApp: View {
    var body: some View {
        VStack(spacing: 1) {
            Text("Welcome to TUIKit!")
                .bold()

            Spacer()

            Text("Build beautiful terminal interfaces in Swift")
                .foregroundColor(.green)

            Spacer()

            Button("Exit") {
                exit(0)
            }
        }
    }
}

let app = MyApp()
app.run()
```

Build and run:

```bash
swift run
```

## Core Concepts

### Views

TUIKit uses a declarative view hierarchy, similar to SwiftUI:

```swift
VStack {
    Text("Title")
    Spacer()
    Button("Action") { }
}
```

### State Management

Manage state with simple properties:

```swift
struct Counter: View {
    @State var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
        }
    }
}
```

### Styling

Apply styles and colors to your UI:

```swift
Text("Styled Text")
    .bold()
    .foregroundColor(.green)
    .padding(1)
```

## Next Steps

- Explore the [API Reference](api/tuikit.md) for all available components
- Check out [example applications](https://github.com/phranck/SwiftTUI/tree/main/Sources/TUIKitExample)
- Visit the [GitHub repository](https://github.com/phranck/SwiftTUI) for more information
