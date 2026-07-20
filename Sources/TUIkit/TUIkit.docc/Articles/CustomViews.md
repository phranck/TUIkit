# Custom Views

Build your own views by composing existing ones or creating custom view modifiers.

## Overview

TUIkit offers two ways to create custom views:

| Approach | When to Use | Complexity |
|----------|-------------|------------|
| **Composite View** (``View`` with `body`) | Combining existing views into reusable components | Low |
| **View Modifier** (``ViewModifier``) | Transforming any view's rendered buffer (padding, background) | Medium |

Most custom views should be **composite views**. For buffer-level transformations, implement a custom ``ViewModifier``.

## Composite Views

A composite view implements the `body` property to compose existing views. This is the same pattern as SwiftUI:

```swift
struct StatusHeader: View {
    let title: String
    let version: String

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .bold()
                    .foregroundColor(.palette.accent)
                Spacer()
                Text("v\(version)")
                    .foregroundColor(.palette.foregroundTertiary)
            }
            Divider()
        }
    }
}
```

The `body` property is annotated with `@ViewBuilder` at the protocol level, so you can use all result builder features: conditionals, optionals, loops:

```swift
struct UserCard: View {
    let name: String
    let role: String?

    var body: some View {
        Panel(title: name) {
            Text(name).bold()
            if let role {
                Text(role)
                    .foregroundColor(.palette.foregroundSecondary)
                    .italic()
            }
        }
    }
}
```

### Accepting Child Content

To create container-style views that accept child content, use a `@ViewBuilder` closure parameter:

```swift
struct Section<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .bold()
                .underline()
            content
        }
    }
}

// Usage
Section(title: "Settings") {
    Text("Option A")
    Text("Option B")
}
```

### Building Custom Containers

For richer containers, compose existing container views like ``Panel``, ``Card``, or ``Dialog``:

```swift
struct SettingsGroup<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Panel(title, borderStyle: .rounded, titleColor: .palette.accent) {
            content
        }
    }
}

// Usage
SettingsGroup("Network") {
    Text("Proxy: none")
    Text("DNS: auto")
}
```

## View Modifiers

A ``ViewModifier`` transforms an already-rendered ``FrameBuffer``. Use this when your transformation operates on the output of any view:

```swift
struct IndentModifier: ViewModifier {
    let columns: Int

    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        var result = FrameBuffer(
            emptyWithWidth: max(0, columns),
            height: buffer.height
        )
        if !buffer.isEmpty {
            result.appendHorizontally(buffer)
        }
        return result
    }
}
```

Apply it using `.modifier(_:)`:

```swift
Text("Indented")
    .modifier(IndentModifier(columns: 2))
```

### Convenience Extensions

For a cleaner API, add a `View` extension:

```swift
extension View {
    func indented(_ columns: Int = 2) -> some View {
        modifier(IndentModifier(columns: columns))
    }
}

// Usage
Text("Indented").indented(4)
```

### When to Use ViewModifier

Use ``ViewModifier`` when your transformation is a pure buffer-to-buffer operation: adding visual effects, changing backgrounds, or adjusting layout after rendering. The ``RenderContext`` gives you access to:

| Property | Description |
|----------|-------------|
| `availableWidth` | Maximum width in columns for this view |
| `availableHeight` | Maximum height in rows for this view |
| `environment` | Current ``EnvironmentValues`` (palette, focus manager, etc.) |

## Type Erasure with AnyView

When you need to store views of different types in a single variable or return different view types conditionally, use ``AnyView``:

```swift
func makeView(isCompact: Bool) -> AnyView {
    if isCompact {
        return AnyView(Text("Compact"))
    } else {
        return AnyView(
            VStack {
                Text("Full")
                Text("Layout")
            }
        )
    }
}
```

Or use the convenience method:

```swift
let view = Text("Hello").asAnyView()
```

`AnyView` captures the concrete view type in a closure, erasing it at the type level while preserving the rendering behavior.

> Tip: Prefer concrete types and `some View` return types over `AnyView`. Type erasure should be a last resort when the type system can't express what you need.

## Topics

### Protocols

- ``View``
- ``ViewModifier``

### Supporting Types

- ``ViewBuilder``
- ``ModifiedView``
- ``AnyView``
- ``RenderContext``
- ``FrameBuffer``
