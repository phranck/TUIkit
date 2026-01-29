# TUIKit API Reference

Complete API documentation for TUIKit framework.

## Core Components

### View

The base protocol for all UI components in TUIKit.

```swift
protocol View {
    var body: some View { get }
}
```

### Text

Display text content in the terminal.

```swift
struct Text: View {
    init(_ content: String)
    var body: some View
}
```

**Example:**

```swift
Text("Hello, World!")
    .bold()
    .foregroundColor(.green)
```

### Button

An interactive button that responds to user input.

```swift
struct Button: View {
    init(_ label: String, action: @escaping () -> Void)
    var body: some View
}
```

**Example:**

```swift
Button("Click me") {
    print("Button was clicked!")
}
```

## Layout Components

### VStack

Arranges views vertically.

```swift
struct VStack<Content: View>: View {
    init(spacing: Int = 0, @ViewBuilder content: () -> Content)
    var body: some View
}
```

**Example:**

```swift
VStack(spacing: 1) {
    Text("First")
    Text("Second")
    Text("Third")
}
```

### HStack

Arranges views horizontally.

```swift
struct HStack<Content: View>: View {
    init(spacing: Int = 0, @ViewBuilder content: () -> Content)
    var body: some View
}
```

**Example:**

```swift
HStack(spacing: 2) {
    Text("Left")
    Spacer()
    Text("Right")
}
```

### Spacer

Adds flexible spacing between views.

```swift
struct Spacer: View {
    var body: some View
}
```

## Modifiers

### Style Modifiers

#### bold()

Make text bold.

```swift
Text("Bold Text").bold()
```

#### padding(_:)

Add padding around a view.

```swift
Text("Padded").padding(1)
```

#### foregroundColor(_:)

Set the text color.

```swift
Text("Green").foregroundColor(.green)
```

#### border(_:)

Add a border around a view.

```swift
Text("Bordered").border(.rounded)
```

## Complete Example

```swift
import TUIKit

struct TodoApp: View {
    @State var todos: [String] = ["Learn TUIKit", "Build an app"]
    @State var newTodo: String = ""

    var body: some View {
        VStack(spacing: 1) {
            Text("My Todo App")
                .bold()
                .foregroundColor(.green)

            Spacer()

            Text("Todos:")
            ForEach(todos, id: \.self) { todo in
                Text("• \(todo)")
                    .foregroundColor(.cyan)
            }

            Spacer()

            Text("Add new todo:")
            TextField("New todo", text: $newTodo)

            Button("Add") {
                if !newTodo.isEmpty {
                    todos.append(newTodo)
                    newTodo = ""
                }
            }

            Spacer()

            Button("Exit") {
                exit(0)
            }
        }
    }
}

let app = TodoApp()
app.run()
```

## More Resources

- [Getting Started](../getting-started.md)
- [GitHub Repository](https://github.com/phranck/SwiftTUI)
- [Examples](https://github.com/phranck/SwiftTUI/tree/main/Sources/TUIKitExample)
