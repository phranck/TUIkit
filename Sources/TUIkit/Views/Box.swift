//
//  Box.swift
//  TUIkit
//
//  A simple bordered container view.
//

/// A simple bordered container view.
///
/// `Box` wraps content in a border without additional styling, padding, or background.
/// It's the most minimal container - just a border around content.
///
/// # Choosing the Right Container
///
/// - **Box**: Minimal - just a border, no padding or background
/// - **Card**: Padded and filled - includes padding and subtle background
/// - **Panel**: Titled box - includes optional title in the border
/// - **ContainerView**: Full-featured - header, body, footer sections
///
/// # Appearance Integration
///
/// `Box` respects the current ``Appearance`` style. By default, it uses the
/// theme's border color and the current appearance (rounded, doubleLine, etc.):
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
/// Box(.heavy, color: .theme.accent) {
///     Text("Heavy bold border in accent color")
/// }
/// ```
///
/// # Example - Basic Usage
///
/// ```swift
/// Box {
///     Text("Simple bordered content")
/// }
/// ```
///
/// # Example - Custom Styling
///
/// ```swift
/// VStack {
///     Box(.doubleLine, color: .brightCyan) {
///         Text("Double-line border")
///         Text("In cyan")
///     }
///
///     Box(.line, color: .yellow) {
///         Text("Thin ASCII border")
///     }
/// }
/// ```
///
/// # Example - With Multiple Children
///
/// ```swift
/// Box {
///     VStack(spacing: 1) {
///         Text("Item 1").bold()
///         Text("Item 2")
///         Text("Item 3")
///     }
/// }
/// ```
///
/// # Size Behavior
///
/// The `Box` size is determined by its content:
/// - If content has a fixed size, `Box` will be that size plus border
/// - If content is flexible, `Box` expands to fill available space
/// - Content inside `Box` respects its layout constraints
///
/// # Rendering
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
