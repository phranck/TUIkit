//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Box.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A minimal bordered container with 1-character inner padding.
///
/// `Box` wraps content in a border with 1 character of horizontal padding
/// on each side. It has no title, footer, or background color.
///
/// ## How Box Differs from Card and Panel
///
/// | Feature | Box | Card | Panel |
/// |---------|-----|------|-------|
/// | Border | Yes | Yes | Yes |
/// | Padding | Horizontal 1 | Yes (default: 1 all sides) | Yes (default: horizontal 1) |
/// | Background color | **No** | Optional | No |
/// | Title | **No** | Optional | **Required** |
/// | Footer | **No** | Optional | Optional |
/// | Rendering | Composite (`body`) | Primitive (`Renderable`) | Primitive (`Renderable`) |
///
/// Use `Box` when you need a **visual boundary** without any structural
/// overhead — for example to visually separate a block of text, highlight a
/// code snippet, or frame a single value. If you need inner spacing, a
/// heading, or action buttons, reach for ``Card`` or ``Panel`` instead.
///
/// ## Typical Use Cases
///
/// - Framing a single value or status indicator
/// - Visually grouping a few lines of output
/// - Quick debug borders during layout development
///
/// ## Appearance Integration
///
/// `Box` respects the current ``Appearance`` style. By default it uses the
/// theme's border color and the active appearance (rounded, doubleLine, etc.):
///
/// ```swift
/// Box {
///     Text("Uses current appearance")
/// }
/// .environment(\.appearance, .doubleLine)  // Now renders with double-line borders
/// ```
///
/// You can override both style and color:
///
/// ```swift
/// Box(.heavy, color: .palette.accent) {
///     Text("Heavy bold border in accent color")
/// }
/// ```
///
/// ## Examples
///
/// ```swift
/// // Minimal border around content
/// Box {
///     Text("Simple bordered content")
/// }
///
/// // Custom border style and color
/// Box(.doubleLine, color: .brightCyan) {
///     Text("Double-line border in cyan")
/// }
///
/// // Multiple children
/// Box {
///     VStack(spacing: 1) {
///         Text("Item 1").bold()
///         Text("Item 2")
///         Text("Item 3")
///     }
/// }
/// ```
///
/// ## Size Behavior
///
/// The `Box` size is determined by its content:
/// - If content has a fixed size, `Box` will be that size plus border + padding
/// - If content is flexible, `Box` expands to fill available space
/// - Content inside `Box` respects its layout constraints
///
/// ## Rendering
///
/// `Box` is a **composite view** — it does not conform to `Renderable`.
/// Instead, it uses `body` to delegate to `content.border(...)`, which
/// creates a ``ContainerView`` without title or footer. This is intentional:
/// `Box` is purely compositional sugar and carries no rendering logic.
///
/// - Note: This is an internal type. Use `.border()` modifier directly instead.
struct Box<Content: View>: View {
    /// The content of the box.
    let content: Content

    /// The border style (nil uses appearance default).
    let borderStyle: BorderStyle?

    /// The border color.
    let borderColor: Color?

    /// Creates a box with the specified border.
    ///
    /// - Parameters:
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - color: The border color (default: theme border).
    ///   - content: The content of the box.
    init(
        _ borderStyle: BorderStyle? = nil,
        color: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.borderStyle = borderStyle
        self.borderColor = color
    }

    var body: some View {
        content.border(borderStyle, color: borderColor)
    }
}

// MARK: - Internal Lines Convenience

extension Box where Content == BufferView {
    /// Creates a box from pre-styled content lines.
    ///
    /// SDK-internal convenience for cases where the box content is built
    /// as an array of pre-styled strings (e.g. notifications with word-wrap
    /// and ANSI coloring applied). Avoids the need for wrapper views when
    /// the content is already rendered.
    ///
    /// - Parameters:
    ///   - lines: Pre-styled content lines (may contain ANSI escape sequences).
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - color: The border color (default: theme border).
    init(
        lines: [String],
        _ borderStyle: BorderStyle? = nil,
        color: Color? = nil
    ) {
        self.content = BufferView(buffer: FrameBuffer(lines: lines))
        self.borderStyle = borderStyle
        self.borderColor = color
    }
}

/// A view that returns a pre-built ``FrameBuffer`` as-is.
///
/// Used internally by ``Box/init(lines:_:color:)`` to pass already-styled
/// content into the `Box` rendering pipeline. This lets `Box` handle border
/// rendering (border style from the current appearance) while the content is controlled
/// externally.
struct BufferView: View, Renderable {
    /// The pre-built buffer to return during rendering.
    let buffer: FrameBuffer

    var body: Never {
        fatalError("BufferView renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        buffer
    }
}

// MARK: - Equatable Conformance

extension Box: Equatable where Content: Equatable {
    nonisolated static func == (lhs: Box<Content>, rhs: Box<Content>) -> Bool {
        MainActor.assumeIsolated {
            lhs.content == rhs.content &&
            lhs.borderStyle == rhs.borderStyle &&
            lhs.borderColor == rhs.borderColor
        }
    }
}
