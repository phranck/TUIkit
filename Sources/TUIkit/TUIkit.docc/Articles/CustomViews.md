# Custom Views

Build your own views by composing existing ones or rendering directly to a frame buffer.

## Overview

TUIkit offers three ways to create custom views, each at a different level of abstraction:

| Approach | When to Use | Complexity |
|----------|-------------|------------|
| **Composite View** (``View`` with `body`) | Combining existing views into reusable components | Low |
| **Primitive View** (``View`` + ``Renderable``) | Full control over buffer output, custom layout logic | High |
| **View Modifier** (``ViewModifier``) | Transforming any view's rendered buffer (padding, background) | Medium |

Most custom views should be **composite views**. Only drop down to `Renderable` when you need pixel-level control over the output buffer.

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

The `body` property is annotated with `@ViewBuilder` at the protocol level, so you can use all result builder features — conditionals, optionals, loops:

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

## Primitive Views

When you need full control over rendering — custom drawing, ANSI escape sequences, or layout algorithms — implement `Renderable` directly:

```swift
struct ProgressBar: View {
    let progress: Double
    let width: Int

    // Required: body must be Never for primitive views
    var body: Never {
        fatalError("ProgressBar renders via Renderable")
    }
}

extension ProgressBar: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let barWidth = min(width, context.availableWidth)
        let filled = Int(Double(barWidth) * progress.clamped(to: 0...1))
        let empty = barWidth - filled

        let bar = String(repeating: "█", count: filled)
            + String(repeating: "░", count: empty)
        let label = String(format: " %.0f%%", progress * 100)

        return FrameBuffer(text: bar + label)
    }
}
```

### The Rendering Contract

A `Renderable` view must:

1. Set `body` to `Never` with a `fatalError` — the framework never calls `body` on renderable views
2. Implement `renderToBuffer(context:)` returning a ``FrameBuffer``
3. Respect `context.availableWidth` and `context.availableHeight` to stay within bounds

The ``RenderContext`` provides:

| Property | Description |
|----------|-------------|
| `terminal` | Terminal capabilities and dimensions |
| `availableWidth` | Maximum width in columns for this view |
| `availableHeight` | Maximum height in rows for this view |
| `environment` | Current ``EnvironmentValues`` (palette, focus manager, etc.) |
| `tuiContext` | Access to ``TUIContext`` subsystems (preferences, lifecycle, key dispatch) |

### Rendering Child Content

Primitive views that contain children must use the free function `renderToBuffer(_:context:)` to render them:

```swift
struct Indented<Content: View>: View {
    let indent: Int
    let content: Content

    var body: Never { fatalError("Indented renders via Renderable") }
}

extension Indented: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Reduce available width for children
        var childContext = context
        childContext.availableWidth = max(0, context.availableWidth - indent)

        // Render child content
        let childBuffer = TUIkit.renderToBuffer(content, context: childContext)

        // Prepend indent to each line
        let prefix = String(repeating: " ", count: indent)
        var buffer = FrameBuffer()
        for line in childBuffer.lines {
            buffer.appendLine(prefix + line)
        }
        return buffer
    }
}
```

### The Dispatch Priority

When the framework encounters a view, it checks in this order:

1. **Renderable** — If the view conforms to `Renderable`, call `renderToBuffer(context:)`
2. **body** — If `Body != Never`, recursively render `view.body`
3. **Fallback** — Return an empty `FrameBuffer` (no crash, no output)

This means `Renderable` always wins over `body`. That's why primitive views set `body: Never` — it's unreachable by design.

## View Modifiers

A ``ViewModifier`` transforms an already-rendered ``FrameBuffer``. Use this when your transformation operates on the output of any view:

```swift
struct HighlightModifier: ViewModifier {
    let color: Color

    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        // Transform each line in the buffer
        var result = FrameBuffer()
        let resolvedColor = color.resolved(with: context.environment.palette)
        for line in buffer.lines {
            result.appendLine(resolvedColor.applyBackground(to: line))
        }
        return result
    }
}
```

Apply it using `.modifier(_:)`:

```swift
Text("Important!")
    .modifier(HighlightModifier(color: .red))
```

### Convenience Extensions

For a cleaner API, add a `View` extension:

```swift
extension View {
    func highlighted(_ color: Color = .red) -> some View {
        modifier(HighlightModifier(color: color))
    }
}

// Usage
Text("Important!").highlighted(.yellow)
```

### ViewModifier vs. Wrapper View

TUIkit has two patterns for modifiers in its codebase:

| Pattern | How It Works | Examples |
|---------|-------------|----------|
| **ViewModifier protocol** | `modify(buffer:context:)` on the rendered buffer via ``ModifiedView`` | `PaddingModifier`, `BackgroundModifier` |
| **Wrapper View** | A standalone `View + Renderable` type that renders its content internally | `BorderedView`, `DimmedModifier`, `OverlayModifier` |

Use `ViewModifier` when your transformation is a pure buffer-to-buffer operation (adding padding, changing background). Use a wrapper view when you need to control *how* the child renders (adjusting the context, registering handlers, interacting with subsystems like focus or preferences).

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
- ``Renderable``
- ``ViewModifier``

### Supporting Types

- ``ViewBuilder``
- ``ModifiedView``
- ``AnyView``
- ``RenderContext``
- ``FrameBuffer``
