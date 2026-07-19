# Getting Started

Build your first terminal application with TUIkit.

## Overview

TUIkit is a Swift package that lets you create terminal user interfaces with a declarative, SwiftUI-like syntax. This guide walks you through setting up a project and building a simple app.

## Adding TUIkit to Your Project

Add TUIkit as a dependency in your `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyTUIApp",
    platforms: [.macOS(.v10_15)],
    dependencies: [
        .package(url: "https://github.com/phranck/TUIkit.git", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "MyTUIApp",
            dependencies: ["TUIkit"]
        ),
    ]
)
```

## Creating Your First App

Create a `main.swift` file with the ``App`` protocol as your entry point:

```swift
import TUIkit

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
            Text("Welcome to TUIkit!")
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

For scripts that don't need an event loop, use ``renderOnce(content:)``:

```swift
import TUIkit

renderOnce {
    VStack {
        Text("Hello, TUIkit!")
            .bold()
            .foregroundColor(.green)
        Divider()
        Text("Version \(tuiKitVersion)")
            .dim()
    }
}
```

One-shot rendering uses the same complete runtime contract as an app render.
Composite views and property wrappers such as ``State``, ``AppStorage``, and
``Environment`` are supported, but no input loop is started after the frame is written.

## Next Steps

- Learn about the framework's <doc:Architecture>
- Explore <doc:StateManagement> for reactive UIs
- Customize your app's look with <doc:ThemingGuide>
- Build multilingual apps with <doc:Localization>
