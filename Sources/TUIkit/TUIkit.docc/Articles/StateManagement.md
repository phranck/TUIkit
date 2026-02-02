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

``EnvironmentValues`` provides values propagated down the view hierarchy:

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

## How State Survives Re-Rendering

TUIkit re-evaluates the entire view tree on every frame. When `body` is called, views are
reconstructed from scratch. Despite this, `@State` values persist — they are never reset
to their initial value.

### Structural Identity

Each view in the tree has a **structural identity** — a path like `"ContentView/VStack.0/Menu"`.
This path is built automatically during rendering based on:
- The view's type name
- Its position among siblings (child index)
- Conditional branches (`true`/`false` for `if`/`else`)

### Persistent State Storage

All `@State` values live in a central `StateStorage` (owned by `TUIContext`), keyed by:
- The view's structural identity
- The property's declaration index within the view (0, 1, 2, ...)

When `@State var count = 0` is declared, the `init` checks if a persistent value already
exists for this position. If it does, the existing value is used instead of the default.

### Re-Render Trigger

When a ``State`` value changes:

1. The ``StateBox`` triggers ``RenderNotifier/current`` → ``AppState/setNeedsRender()``
2. The observer registered by `AppRunner` requests a re-render
3. The main loop re-evaluates `app.body` fresh — reconstructing all views
4. Each `@State.init` self-hydrates from `StateStorage`, recovering persisted values
5. The new ``FrameBuffer`` output is written to the terminal

### Garbage Collection

Views that disappear from the tree (e.g., a conditional branch switches) have their state
automatically cleaned up at the end of each render pass. `ConditionalView` also immediately
invalidates the inactive branch's state to prevent stale values.

This is simple and predictable — no diffing, no virtual DOM, just full re-renders with
persistent state.
