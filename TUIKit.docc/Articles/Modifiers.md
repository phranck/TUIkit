# View Modifiers

Learn how to use modifiers to customize the appearance and behavior of views.

## Overview

Modifiers are methods that return a modified copy of a view. Chain them together to build complex layouts and styling:

```swift
Text("Hello")
    .bold()
    .foregroundColor(.theme.accent)
    .padding(1)
    .border(.rounded)
```

## Layout Modifiers

### padding(_:)

Add padding around content:

```swift
Text("Content")
    .padding()          // Default 1 unit
    .padding(2)         // 2 units all sides
    .padding(.top, 1)   // 1 unit top
    .padding(.horizontal, 2)  // 2 units left/right
```

### frame(width:height:alignment:)

Set fixed size:

```swift
Text("Fixed")
    .frame(width: 20, height: 5)

Button("Button")
    .frame(width: 15)
```

### frame(minWidth:maxWidth:minHeight:maxHeight:)

Set flexible size constraints:

```swift
Text("Flexible")
    .frame(minWidth: 10, maxWidth: 50)
    .frame(minHeight: 3, maxHeight: 10)

Text("Fill available space")
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```

## Color Modifiers

### foregroundColor(_:)

Set text color:

```swift
Text("Colored")
    .foregroundColor(.theme.accent)

Text("Green")
    .foregroundColor(.ansi(.brightGreen))

Text("Custom")
    .foregroundColor(.hex("FF5500"))
```

### background(_:)

Add background color:

```swift
Text("Background")
    .background(.theme.accent)
    .foregroundColor(.theme.background)
```

## Text Styling

### Bold, Italic, Underline

```swift
Text("Bold").bold()
Text("Italic").italic()
Text("Underline").underlined()
Text("Strikethrough").strikethrough()
Text("Dim").dimmed()
Text("Blinking").blinking()
Text("Inverted").inverted()
```

Combine multiple modifiers:

```swift
Text("Complex")
    .bold()
    .italic()
    .foregroundColor(.theme.accent)
```

## Border and Structure

### border(_:)

Add borders with different styles:

```swift
Text("Bordered")
    .border(.rounded)

Text("Heavy border")
    .border(.heavy, width: 2)

VStack {
    Text("Content")
}
.border(.block, color: .theme.accent)
```

## Overlay and Compositing

### overlay(_:)

Layer content on top:

```swift
Text("Background")
    .overlay {
        Text("Foreground")
    }
```

### dimmed()

Reduce visual emphasis:

```swift
VStack {
    Text("Normal")
    Text("Dimmed")
        .dimmed()
}
```

### modal()

Combine dimmed + centered overlay:

```swift
showAlert {
    Alert(title: "Alert", message: "Message")
        .modal()
}
```

## Event Modifiers

### onKeyPress(_:)

Handle keyboard input:

```swift
VStack {
    ContentView()
}
.onKeyPress { event in
    if event.key == .character("q") {
        // Quit
        return true
    }
    return false
}
```

### onAppear(_:)

Run code when view appears:

```swift
Text("Content")
    .onAppear {
        print("View appeared")
    }
```

### onDisappear(_:)

Run code when view disappears:

```swift
Text("Content")
    .onDisappear {
        print("View disappearing")
    }
```

### task(_:)

Run async code:

```swift
VStack {
    ContentView()
}
.task {
    // Fetch data
    let data = try await fetchData()
}
```

## Data Flow Modifiers

### environment(_:_:)

Pass environment values to children:

```swift
VStack {
    ContentView()
}
.environment(\.theme, customTheme)
```

### statusBarItems(_:)

Define status bar items:

```swift
VStack {
    ContentView()
}
.statusBarItems {
    StatusBarItem(
        label: "Help",
        shortcut: Shortcut.letter("?"),
        action: { print("Help") }
    )
}
```

## Combining Modifiers

Modifiers are applied in order—the order matters:

```swift
// This looks different...
Text("Order matters")
    .foregroundColor(.theme.accent)
    .padding(1)
    .border(.rounded)

// ...than this
Text("Order matters")
    .border(.rounded)
    .padding(1)
    .foregroundColor(.theme.accent)
```

### Creating Custom Modifiers

Create reusable modifiers:

```swift
struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .bold()
            .foregroundColor(.theme.background)
            .background(.theme.accent)
            .padding(1)
            .border(.rounded)
    }
}

extension View {
    func primaryButton() -> some View {
        modifier(PrimaryButtonStyle())
    }
}

// Usage
Button("Click") { }
    .primaryButton()
```

## Common Patterns

### Centered Text

```swift
Text("Centered")
    .frame(maxWidth: .infinity, alignment: .center)
```

### Full-Size Container

```swift
VStack {
    ContentView()
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

### Bordered Section

```swift
VStack(spacing: 1) {
    Text("Title").bold()
    ContentView()
}
.padding(1)
.border(.rounded)
```

### Button Row

```swift
HStack(spacing: 2) {
    Button("OK") { }
    Button("Cancel") { }
}
.frame(maxWidth: .infinity, alignment: .trailing)
```

## Related Topics

- ``View``
- ``ViewModifier``
- ``View/padding(_:)-19gu9``
- ``View/frame(width:height:alignment:)``
- ``View/border(_:style:)-4xzvw``
- ``View/background(_:)``
- ``View/foregroundColor(_:)``
- ``View/overlay(alignment:content:)``
- ``View/onKeyPress(_:)``
