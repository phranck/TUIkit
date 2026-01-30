# Getting Started

Build your first terminal application with TUIKit.

## Overview

TUIKit is a Swift package that lets you create terminal user interfaces with a declarative, SwiftUI-like syntax. This guide walks you through setting up a project and building a simple app.

## Adding TUIKit to Your Project

Add TUIKit as a dependency in your `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyTUIApp",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIKit.git", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyTUIApp",
            dependencies: ["TUIKit"]
        ),
    ]
)
```

## Creating Your First App

Create a `main.swift` file with the ``App`` protocol as your entry point:

```swift
import TUIKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Welcome to TUIKit!")
                .bold()
                .foregroundColor(.cyan)

            Spacer()

            Text("Press 'q' to quit")
                .dim()
        }
    }
}
```

## Using State

Add interactivity with the ``State`` property wrapper:

```swift
struct CounterView: View {
    @State var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
                .bold()
            Button("Increment") {
                count += 1
            }
        }
    }
}
```

## One-Shot Rendering

For simple scripts that don't need a full app lifecycle, use ``renderOnce(content:)``:

```swift
import TUIKit

renderOnce {
    VStack {
        Text("Hello, TUIKit!")
            .bold()
            .foregroundColor(.green)
        Divider()
        Text("Version \(tuiKitVersion)")
            .dim()
    }
}
```

## Next Steps

- Learn about the framework's <doc:Architecture>
- Explore <doc:StateManagement> for reactive UIs
- Customize your app's look with <doc:ThemingGuide>
