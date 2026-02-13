# Layout System

Understand the two-pass layout used by stacks and other layout containers.

## Overview

TUIkit uses a two-pass layout system inspired by SwiftUI's layout protocol. Layout containers like ``VStack`` and ``HStack`` first **measure** each child, then **render** them with allocated sizes. This approach enables features like flexible spacers, proportional sizing, and proper alignment.

## The Two Passes

### Pass 1: Measure

The parent proposes a size to each child via ``ProposedSize``. Each child responds with a ``ViewSize`` that describes how much space it needs and whether it can flex.

```
Parent (VStack)
  ├─ propose(width: 40, height: nil) → Text    → ViewSize(10, 1, flexible: false)
  ├─ propose(width: 40, height: nil) → Spacer  → ViewSize(0, 0, flexible: true)
  └─ propose(width: 40, height: nil) → Button  → ViewSize(12, 1, flexible: false)
```

### Pass 2: Render

After measuring all children, the parent distributes the remaining space among flexible children and renders each child with its final allocated size.

```
Parent allocates:
  Text   → render(width: 40, height: 1)   // Gets full width, fixed height
  Spacer → render(width: 40, height: 8)   // Gets remaining vertical space
  Button → render(width: 40, height: 1)   // Gets full width, fixed height
```

## ProposedSize

``ProposedSize`` represents the space a parent offers to a child. Either dimension can be `nil`, meaning "use your ideal size."

```swift
public struct ProposedSize {
    public var width: Int?
    public var height: Int?
}
```

| Value | Meaning |
|-------|---------|
| `nil` | Use ideal size (no constraint) |
| `0` | Minimum size |
| `> 0` | Available space in characters/lines |

## ViewSize

``ViewSize`` is the child's response: how much space it needs and whether it can expand.

```swift
public struct ViewSize {
    public var width: Int
    public var height: Int
    public var isWidthFlexible: Bool
    public var isHeightFlexible: Bool
}
```

Factory methods make common patterns concise:

```swift
ViewSize.fixed(20, 1)                    // Fixed 20x1, won't expand
ViewSize.flexible(minWidth: 0, minHeight: 0)  // Expands in both directions
ViewSize.flexibleWidth(minWidth: 5, height: 1) // Expands horizontally only
```

## The Layoutable Protocol

Views that participate in two-pass layout conform to `Layoutable` (which extends `Renderable`):

```swift
protocol Layoutable: Renderable {
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize
}
```

A default implementation renders the view and measures the resulting buffer. Custom implementations can calculate size without rendering for better performance.

## ChildView

Layout containers wrap their children in `ChildView`, which provides a uniform interface for measuring and rendering:

```swift
struct ChildView {
    func measure(proposal: ProposedSize, context: RenderContext) -> ViewSize
    func render(width: Int, height: Int, context: RenderContext) -> FrameBuffer
}
```

`ChildView` automatically detects spacers and propagates child identity for correct state management.

## How Stacks Lay Out Children

``VStack`` and ``HStack`` follow this algorithm:

1. **Measure** all children with the parent's proposed size
2. **Sum** the fixed sizes along the stack axis
3. **Distribute** remaining space among flexible children (spacers, flexible text fields, etc.)
4. **Render** each child with its allocated size
5. **Compose** the rendered buffers with the specified spacing and alignment

Flexible children share remaining space equally. If multiple spacers exist, they each get an equal portion of the leftover space.

## Which Views Are Layoutable?

| View | Layoutable? | Flexibility |
|------|------------|-------------|
| ``Text`` | Yes | Fixed (wraps at proposed width) |
| ``Spacer`` | Yes | Flexible in stack direction |
| ``Button`` | Yes | Width-flexible |
| ``TextField`` | Yes | Width-flexible |
| ``SecureField`` | Yes | Width-flexible |
| ``Slider`` | Yes | Width-flexible |
| ``Divider`` | Yes | Width-flexible |
| ``ProgressView`` | Yes | Width-flexible |

Views that are not `Layoutable` use the default implementation which renders first, then reports the buffer size as fixed.

## See Also

- ``ProposedSize``
- ``ViewSize``
- ``VStack``
- ``HStack``
- ``Spacer``
- <doc:RenderCycle>
