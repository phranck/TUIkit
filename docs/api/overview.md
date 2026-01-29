# API Overview

TUIKit provides a comprehensive set of views, modifiers, and utilities for building terminal UIs.

## Core Concepts

### View Protocol

The foundation of TUIKit. All UI components conform to `View`.

```swift
protocol View {
    associatedtype Body: View
    var body: Body { get }
}
```

### Scene & App

Manage your application lifecycle:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MyContent()
        }
    }
}
```

## Primitive Views

- **Text** - Display text content
- **Spacer** - Flexible spacing
- **Divider** - Visual separator
- **EmptyView** - No visual output

## Layout Containers

- **VStack** - Arrange vertically
- **HStack** - Arrange horizontally
- **ZStack** - Overlay views

## Interactive Components

- **Button** - Clickable button
- **Menu** - Dropdown menu with keyboard navigation
- **TextField** - Single-line text input

## Containers

- **Alert** - Modal alert dialog
- **Panel** - Bordered panel
- **Card** - Styled card
- **Box** - Simple box

## Advanced Features

- **@State** - Reactive state management
- **@Environment** - Dependency injection
- **@AppStorage** - Persistent storage
- **StatusBar** - Context-sensitive shortcuts
- **ForEach** - List iteration

See the [Components](./components.md) page for detailed API documentation.
