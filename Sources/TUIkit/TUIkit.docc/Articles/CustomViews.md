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

A ``ViewModifier`` composes a replacement view around the content it is
applied to — exactly like SwiftUI. Implement `body(content:)` and place the
received `content` placeholder wherever the modified view should appear:

```swift
struct SectionCard: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        VStack {
            Text(title).bold()
            content
        }
        .padding()
        .border()
    }
}
```

Apply it using `.modifier(_:)`, which produces a ``ModifiedContent`` value:

```swift
Text("Details")
    .modifier(SectionCard(title: "Info"))
```

### Convenience Extensions

For a cleaner API, add a `View` extension:

```swift
extension View {
    func sectionCard(_ title: String) -> some View {
        modifier(SectionCard(title: title))
    }
}

// Usage
Text("Details").sectionCard("Info")
```

### When to Use ViewModifier

Use ``ViewModifier`` whenever a reusable decoration or wrapping applies to
arbitrary content: cards, frames, badges, spacing conventions, environment
tweaks. Everything the modifier body sets (environment values, padding,
borders) flows into the wrapped content exactly as if it were written
inline. Procedural buffer transformations remain framework-internal; custom
modifiers compose existing views and modifiers instead.

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
- ``ModifiedContent``
- ``AnyView``
- ``RenderContext``
- ``FrameBuffer``
