# Focus Management

Understand how keyboard navigation and focus works in TUIKit.

## Overview

TUIKit provides a sophisticated focus management system that enables Tab/Shift+Tab navigation, keyboard shortcuts, and custom focus logic.

## The Focus Manager

``FocusManager`` manages which component currently has keyboard focus:

```swift
@Environment(\.focusManager) var focusManager

Button("Click me") {
    // Handle click
}
.focused(focusID: "myButton")
```

## Tab Navigation

By default, all focusable elements can be navigated with Tab and Shift+Tab:

- **Tab**: Move focus to the next element
- **Shift+Tab**: Move focus to the previous element
- **Enter/Space**: Activate focused button

```swift
VStack(spacing: 1) {
    Text("Navigation")

    Button("First") { }
    Button("Second") { }
    Button("Third") { }
}
```

Users can Tab between the buttons in order.

## Focus Indicators

Focusable elements show a focus indicator when active:

```swift
Button("Focusable") {
    print("Activated")
}
```

The button displays:
- A border around the element
- Visual highlight (usually arrow prefix: `▸`)
- Theme accent color

## Programmatic Focus

Set focus programmatically:

```swift
struct Settings: View {
    @State private var focusedField: String?

    var body: some View {
        VStack(spacing: 1) {
            Button("First") { focusedField = "first" }
                .focused(focusID: "first", focused: focusedField == "first")

            Button("Second") { focusedField = "second" }
                .focused(focusID: "second", focused: focusedField == "second")

            Button("Reset") { focusedField = nil }
        }
    }
}
```

## Keyboard Events

Handle keyboard events with `onKeyPress`:

```swift
struct App: View {
    var body: some View {
        VStack {
            ContentView()
                .onKeyPress { event in
                    if event.key == .character("h") && event.modifiers.contains(.ctrl) {
                        print("Help requested")
                        return true
                    }
                    return false
                }
        }
    }
}
```

### Key Event Structure

``KeyEvent`` contains:

- **key**: The key pressed (character, arrow, enter, etc.)
- **modifiers**: Ctrl, Shift, Alt flags
- **raw**: Raw terminal escape sequence

### Special Keys

Handle special keys like arrows and function keys:

```swift
.onKeyPress { event in
    switch event.key {
    case .up:
        print("Arrow up")
    case .down:
        print("Arrow down")
    case .left:
        print("Arrow left")
    case .right:
        print("Arrow right")
    case .enter:
        print("Enter pressed")
    case .escape:
        print("Escape pressed")
    case .tab:
        print("Tab pressed")
    case .character(let char):
        print("Character: \(char)")
    default:
        break
    }
    return true
}
```

## Focusable Protocol

Components conform to ``Focusable`` to support focus:

```swift
public protocol Focusable {
    var focusID: String? { get }
    var isFocused: Bool { get }
}
```

Button, Menu, and other interactive components automatically implement this.

## Custom Focus Logic

Create custom focus behavior:

```swift
struct CustomMenu: View {
    @State private var selectedIndex: Int = 0
    let items: [String]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Text(item)
                    .padding(1)
                    .background(selectedIndex == index ? .theme.accent : .clear)
            }
        }
        .onKeyPress { event in
            switch event.key {
            case .up:
                selectedIndex = max(0, selectedIndex - 1)
                return true
            case .down:
                selectedIndex = min(items.count - 1, selectedIndex + 1)
                return true
            default:
                return false
            }
        }
    }
}
```

## Focus in Modals

Focus works correctly with modals and overlays:

```swift
@State var showDialog: Bool = false

var body: some View {
    VStack {
        if showDialog {
            Alert(
                title: "Confirm",
                message: "Continue?"
            ) {
                VStack(spacing: 1) {
                    Button("Yes") { showDialog = false }
                    Button("No") { showDialog = false }
                }
            }
            .modal()
        }

        Button("Show Dialog") { showDialog = true }
    }
}
```

When a modal appears, focus automatically moves to the first focusable element in the modal.

## Best Practices

1. **Tab order**: Arrange elements logically for Tab navigation
2. **Feedback**: Always provide visual feedback for focused elements
3. **Shortcuts**: Implement keyboard shortcuts for common actions
4. **Testing**: Test focus behavior with keyboard navigation
5. **Accessibility**: Consider users with motor impairments who rely on keyboard

## Status Bar Integration

Status bar items show keyboard shortcuts:

```swift
.statusBarItems {
    StatusBarItem(
        label: "Help",
        shortcut: Shortcut.letter("?"),
        action: {
            print("Show help")
        }
    )

    StatusBarItem(
        label: "Quit",
        shortcut: Shortcut.letter("q"),
        action: {
            print("Exit app")
        }
    )
}
```

## Related Topics

- ``FocusManager``
- ``KeyEvent``
- ``Focusable``
- ``View/onKeyPress(_:)``
- ``StatusBar``
- ``StatusBarItem``
