# Quick Start

## Your First App

Create a new Swift executable and add TUIKit as a dependency.

### Step 1: Define Your View

```swift
import TUIKit

struct ContentView: View {
    @State var name = ""

    var body: some View {
        VStack(spacing: 1) {
            Text("Welcome to TUIKit!")
                .bold()
                .foregroundColor(.cyan)

            Spacer()

            Text("Enter your name:")
            TextField("Name", text: $name)

            Spacer()

            if !name.isEmpty {
                Text("Hello, \(name)!")
                    .foregroundColor(.green)
            }

            Spacer()

            Button("Exit") {
                exit(0)
            }
        }
        .padding(2)
    }
}
```

### Step 2: Create Your App

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

### Step 3: Run It

```bash
swift run
```

## Core Concepts

### Views

Everything in TUIKit is a `View`. Views are lightweight value types that describe what should be displayed.

```swift
Text("Hello")
Button("Click me") { print("Clicked!") }
VStack { Text("A"); Text("B") }
```

### State

Use `@State` to make views interactive:

```swift
@State var count = 0

var body: some View {
    VStack {
        Text("Count: \(count)")
        Button("Increment") { count += 1 }
    }
}
```

### Composition

Build complex UIs by composing simple views:

```swift
VStack(spacing: 1) {
    Header()
    Content()
    Footer()
}
```

## Next Steps

- Explore the [API Reference](/api/overview.md)
- Learn about [Styling](./styling.md)
- Try the [Example App](https://github.com/phranck/SwiftTUI/tree/main/Sources/TUIKitExample)
