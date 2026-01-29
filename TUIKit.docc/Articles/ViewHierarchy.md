# Understanding the View Hierarchy

Learn how TUIKit's declarative view model works and how to compose views effectively.

## The View Protocol

Everything in TUIKit conforms to the `View` protocol. A view is a lightweight value type that describes a piece of UI:

```swift
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
}
```

Views are **not** the rendered output—they're descriptions of UI that get rendered when needed.

### Primitive Views

Some views have `body: Never` and directly conform to `Renderable`. These render their own content:

- **`Text`**: Display text with styling
- **`Button`**: Interactive clickable element
- **`Menu`**: Selection menu with keyboard navigation
- **`Spacer`**: Occupy available space
- **`Divider`**: Horizontal or vertical separator
- **`EmptyView`**: Invisible placeholder view

### Composite Views

Most views define a `body` that combines other views:

```swift
struct MyCard: View {
    var body: some View {
        VStack(spacing: 1) {
            Text("Title").bold()
            Text("Content")
        }
        .border(.rounded)
    }
}
```

Composite views don't render directly—the renderer walks the view tree and renders primitives.

## Container Views

### VStack (Vertical Stack)

Stack views vertically with optional spacing:

```swift
VStack(spacing: 1) {
    Text("First")
    Text("Second")
    Text("Third")
}
```

### HStack (Horizontal Stack)

Stack views horizontally:

```swift
HStack(spacing: 2) {
    Button("OK") { }
    Button("Cancel") { }
}
```

### ZStack (Depth Stack)

Layer views on top of each other:

```swift
ZStack {
    Text("Background")
    Text("Foreground")
}
```

### ForEach

Render a collection of items:

```swift
ForEach(items) { item in
    Text(item.name)
}
```

## Control Flow

### Conditionals

Use standard Swift `if` statements:

```swift
if isLoading {
    Text("Loading...")
} else {
    Text("Loaded!")
}
```

### Optional Values

Handle optional views:

```swift
if let name = userName {
    Text("Hello, \(name)")
} else {
    Text("Not logged in")
}
```

## The ViewBuilder Result Builder

`@ViewBuilder` is a result builder that enables the declarative syntax:

```swift
@ViewBuilder
var content: some View {
    if condition {
        Text("A")
    } else {
        Text("B")
    }
    Text("C")
}
```

It supports:
- Up to 10 children without nesting
- `if/else if/else` conditionals
- `if let` optional unwrapping
- Arrays and `ForEach`
- Nested result builders

## Type Erasure with AnyView

When you need to return different view types, use `AnyView`:

```swift
func makeView(condition: Bool) -> AnyView {
    if condition {
        return AnyView(Text("A"))
    } else {
        return AnyView(VStack { Text("B") })
    }
}
```

> Note: Use `AnyView` sparingly—prefer `@ViewBuilder` when possible.

## Custom Views

Create your own reusable components:

```swift
struct CustomButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(label, action: action)
            .padding(1)
            .border(.rounded)
    }
}

// Usage
CustomButton(label: "Click me", action: {
    print("Clicked")
})
```

## View Composition Pattern

Build complex UIs by composing smaller views:

```swift
struct ContentView: View {
    var body: some View {
        VStack(spacing: 1) {
            HeaderView()
            BodyView()
            FooterView()
        }
    }
}

struct HeaderView: View {
    var body: some View {
        Text("Header").bold()
    }
}

struct BodyView: View {
    var body: some View {
        Text("Content").padding(1)
    }
}

struct FooterView: View {
    var body: some View {
        Text("Footer")
    }
}
```

## View Lifetime

Views are value types—they're created, rendered, and discarded. They don't have persistent storage. Use `@State` for state that persists across renders:

```swift
struct Counter: View {
    @State var count: Int = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}
```

## Related Topics

- ``View``
- ``@ViewBuilder``
- ``VStack``
- ``HStack``
- ``ZStack``
- <doc:StateManagement>
- <doc:Modifiers>
