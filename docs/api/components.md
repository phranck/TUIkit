# Components

## Primitive Views

### Text
Display text content in the terminal.

```swift
Text("Hello, World!")
    .bold()
    .foregroundColor(.cyan)
```

### Spacer
Add flexible spacing between views.

```swift
VStack {
    Text("Top")
    Spacer()
    Text("Bottom")
}
```

## Layout Containers

### VStack
Arrange views vertically.

```swift
VStack(spacing: 1) {
    Text("First")
    Text("Second")
    Text("Third")
}
```

### HStack
Arrange views horizontally.

```swift
HStack(spacing: 2) {
    Text("Left")
    Spacer()
    Text("Right")
}
```

### ZStack
Overlay views on top of each other.

```swift
ZStack {
    Rectangle().fill(.red)
    Text("Overlay")
}
```

## Interactive Components

### Button
Create clickable buttons with focus support.

```swift
Button("Click me") {
    print("Clicked!")
}
```

### TextField
Single-line text input.

```swift
@State var text = ""
TextField("Enter text", text: $text)
```

### Menu
Dropdown menu with keyboard navigation.

```swift
Menu("Options") {
    Button("Option 1") { }
    Button("Option 2") { }
}
```

## Container Components

### Alert
Modal alert dialog.

```swift
Alert("Warning", message: "Are you sure?") {
    Button("Yes") { }
    Button("No") { }
}
```

### Panel
Bordered panel container.

```swift
Panel(title: "Info") {
    Text("Panel content")
}
```

## More Components

Explore the full API documentation for additional components and modifiers.
