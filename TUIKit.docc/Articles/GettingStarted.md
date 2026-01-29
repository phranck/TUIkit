# Getting Started with TUIKit

Create your first terminal user interface in minutes.

## Installation

### Using Swift Package Manager

Add TUIKit to your `Package.swift`:

```swift
.package(url: "https://github.com/anthropics/SwiftTUI.git", from: "0.1.0")
```

Or via Xcode: File > Add Packages > Enter repository URL

## Creating Your First App

### 1. Define Your App

Every TUIKit app needs an `@main` entry point that conforms to the `App` protocol:

```swift
import TUIKit

@main
struct HelloApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Hello, TUIKit!")
        }
    }
}
```

### 2. Add Some Layout

Use `VStack` and `HStack` to organize your content:

```swift
@main
struct LayoutApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 1) {
                Text("Welcome")
                    .bold()

                Text("Build terminal UIs in Swift")

                Spacer()

                Text("Press 'q' to quit")
                    .foregroundColor(.theme.foregroundSecondary)
            }
            .padding()
        }
    }
}
```

### 3. Make It Interactive

Add buttons and state to create interactive interfaces:

```swift
import TUIKit

@main
struct InteractiveApp: App {
    @State var count: Int = 0

    var body: some Scene {
        WindowGroup {
            VStack(spacing: 1) {
                Text("Counter: \(count)")
                    .bold()

                HStack(spacing: 2) {
                    Button("Increment") { count += 1 }
                    Button("Decrement") { count = max(0, count - 1) }
                }

                Spacer()
            }
            .padding()
        }
    }
}
```

## Running Your App

### From Command Line

```bash
swift run
```

### With a Custom Executable Name

Add to `Package.swift`:

```swift
.executableTarget(
    name: "MyApp",
    dependencies: [.product(name: "TUIKit", package: "SwiftTUI")]
)
```

Then run:

```bash
swift run MyApp
```

## Understanding the Basics

### Views

Everything in TUIKit is a `View`. Views are lightweight, composable units that render content to the terminal.

Common views:
- **`Text`**: Display text with optional styling
- **`Button`**: Interactive button with action handler
- **`VStack`**: Arrange views vertically
- **`HStack`**: Arrange views horizontally
- **`Spacer`**: Fill available space

### State Management

Use `@State` to make your views interactive:

```swift
@State var isVisible: Bool = true

VStack {
    if isVisible {
        Text("Visible")
    }
    Button("Toggle") { isVisible.toggle() }
}
```

### Modifiers

Customize views with modifiers:

```swift
Text("Hello")
    .bold()
    .foregroundColor(.theme.accent)
    .padding(1)
    .border(.rounded)
```

## Next Steps

- Explore the <doc:ViewHierarchy> to understand component organization
- Learn <doc:StateManagement> for complex state scenarios
- Discover <doc:Theming> to customize colors and appearance
- Check out <doc:Modifiers> for all available styling options
- Try <doc:BuildYourFirstApp> tutorial for step-by-step guidance

## Key Bindings

By default, TUIKit apps support:
- **`q`**: Quit the application
- **`t`**: Cycle through themes
- **`a`**: Cycle through appearance styles
- **`?`**: Show help

See ``KeyEvent`` for custom keyboard handling.

## Terminal Requirements

- Minimum 80x24 character terminal
- ANSI color support (256 colors recommended)
- UTF-8 encoding
- Supports: macOS Terminal, iTerm2, Kitty, and Linux terminals (gnome-terminal, konsole, etc.)
