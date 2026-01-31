//
//  Box.swift
//  TUIkit
//
//  A simple bordered container view.
//

/// A minimal bordered container — just a border, nothing else.
///
/// `Box` wraps content in a border without adding padding, background color,
/// title, or footer. It is the thinnest container in TUIkit: content sits
/// directly against the border characters.
///
/// ## How Box Differs from Card and Panel
///
/// | Feature | Box | Card | Panel |
/// |---------|-----|------|-------|
/// | Border | Yes | Yes | Yes |
/// | Padding | **No** | Yes (default: 1 all sides) | Yes (default: horizontal 1) |
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
/// - Wrapping content that already manages its own padding
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
/// .environment(\.appearance, .block)  // Now renders with block characters
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
/// - If content has a fixed size, `Box` will be that size plus border
/// - If content is flexible, `Box` expands to fill available space
/// - Content inside `Box` respects its layout constraints
///
/// ## Rendering
///
/// `Box` is a **composite view** — it does not conform to ``Renderable``.
/// Instead, it uses `body` to delegate to `content.border(...)`, which
/// produces a `BorderedView` that *is* `Renderable`. This is intentional:
/// `Box` is purely compositional sugar and carries no rendering logic.
public struct Box<Content: View>: View {
    /// The content of the box.
    public let content: Content

    /// The border style (nil uses appearance default).
    public let borderStyle: BorderStyle?

    /// The border color.
    public let borderColor: Color?

    /// Creates a box with the specified border.
    ///
    /// - Parameters:
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - color: The border color (default: theme border).
    ///   - content: The content of the box.
    public init(
        _ borderStyle: BorderStyle? = nil,
        color: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.borderStyle = borderStyle
        self.borderColor = color
    }

    public var body: some View {
        content.border(borderStyle, color: borderColor)
    }
}
