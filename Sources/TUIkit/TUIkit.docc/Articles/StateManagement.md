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

``AppStorage`` persists values across app launches using the application's
runtime-owned storage backend. TUIkit apps use ``JSONFileStorage`` by default:

```swift
struct SettingsView: View {
    @AppStorage("username") var username = "Guest"

    var body: some View {
        Text("Hello, \(username)!")
    }
}
```

Pass an explicit backend when a property wrapper is created outside the app
runtime or needs dedicated storage:

```swift
@AppStorage("username", storage: MyStorageBackend()) var username = "Guest"
```

An `@AppStorage` property accessed before any runtime hydrates it falls back
to volatile in-memory storage: nothing reaches the file system without an
owning runtime or an explicit backend.

### Persistence Guarantees

``JSONFileStorage`` captures an immutable snapshot for every mutation and
persists snapshots through one ordered writer, so an older state can never
overwrite a newer one. `synchronize()` returns only after every previously
issued write has completed; the runtime flushes storage this way during
cleanup. Persistence failures are reported as ``StoragePersistenceError``
values whose reasons are sanitized: they identify the failing step and error
code, but never contain file paths or stored content.

## How State Survives Re-Rendering

TUIkit re-evaluates the entire view tree on every frame. When `body` is called, views are
reconstructed from scratch. Despite this, `@State` values persist: they are never reset
to their initial value.

### Structural Identity

Each view in the tree has a **structural identity**: a path like `"ContentView/VStack.0/Menu"`.
This path is built automatically during rendering based on:
- The view's type name
- Its position among siblings (child index)
- Conditional branches (`true`/`false` for `if`/`else`)
- Nested modifier and runtime slots

### Persistent State Storage

All `@State` values live in the owning runtime's `StateStorage`, keyed by:
- The view's structural identity
- The property's declaration index within the view (0, 1, 2, ...)

When `@State var count = 0` is constructed, it initially holds the declared default.
Immediately before the renderer evaluates that view's `body`, it binds each direct dynamic
property to the persistent location at the view's final structural identity. A reconstructed
view therefore reads the stored value instead of resetting to its default.

### Re-Render Trigger

When a ``State`` value changes:

1. The `StateBox` sends a subtree invalidation to its runtime's `RenderInvalidationSink`
2. That runtime's `AppState` notifies the observer registered by `AppRunner`
3. The main loop re-evaluates `app.body` fresh: reconstructing all views
4. The renderer rebinds each view's dynamic properties to the same runtime's `StateStorage`
5. The owning runtime clears the affected cached subtree and writes the new ``FrameBuffer``

Observable dependencies read while evaluating `body` are tracked at the same committed
identity. Re-evaluating an identity replaces its active observation generation, so callbacks
from earlier view values become inert. Registrations are removed when their identity unmounts.

### Garbage Collection

Views that disappear from the tree (e.g., a conditional branch switches) have their state
automatically cleaned up at the end of each render pass. `_ConditionalContent` also immediately
invalidates the inactive branch's state to prevent stale values.

This is simple and predictable: the view tree is fully re-evaluated each frame (no virtual DOM), with persistent state. Terminal output is then diffed at the line level: only changed lines are written. See <doc:RenderCycle> for details on the output optimization pipeline.
