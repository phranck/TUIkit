# State Management

Manage reactive state in your TUIkit application.

## Overview

TUIkit provides a state management system modeled after SwiftUI. When state changes, the view tree is automatically re-rendered.

## @State

Use ``State`` for simple values owned by a single view:

```swift
struct CounterView: View {
    @State var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1  // Triggers re-render
            }
        }
    }
}
```

## Binding

``Binding`` provides a two-way connection to a value owned elsewhere. Use the `$` prefix on a `@State` property to get its binding:

```swift
struct ParentView: View {
    @State var selectedIndex = 0

    var body: some View {
        Menu(items: menuItems, selection: $selectedIndex)
    }
}
```

Create constant bindings for previews or static values:

```swift
let binding = Binding.constant(42)
```

## @Environment

``Environment`` reads values propagated down the view hierarchy:

```swift
struct MyView: View {
    @Environment(\.theme) var theme
    @Environment(\.statusBar) var statusBar

    var body: some View {
        Text("Themed text")
            .foregroundColor(theme.foreground)
    }
}
```

### Defining Custom Environment Keys

```swift
struct MyCustomKey: EnvironmentKey {
    static var defaultValue: String = "default"
}

extension EnvironmentValues {
    var myCustomValue: String {
        get { self[MyCustomKey.self] }
        set { self[MyCustomKey.self] = newValue }
    }
}
```

Inject values with the `.environment()` modifier:

```swift
ContentView()
    .environment(\.myCustomValue, "custom")
```

## @AppStorage

``AppStorage`` persists values across app launches using `UserDefaults`:

```swift
struct SettingsView: View {
    @AppStorage("username") var username = "Guest"

    var body: some View {
        Text("Hello, \(username)!")
    }
}
```

## How Re-Rendering Works

TUIkit uses a single-threaded event loop. When a ``State`` value changes:

1. ``AppState/setNeedsRender()`` is called
2. The main loop detects the change
3. The entire view tree is re-rendered
4. The new ``FrameBuffer`` output is written to the terminal

This is simple and predictable — no diffing, no virtual DOM, just full re-renders on every state change.
