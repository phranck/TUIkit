//
//  Box.swift
//  TUIKit
//
//  A simple bordered container view.
//

/// A simple bordered container view.
///
/// `Box` wraps content in a border without additional styling.
/// Use `Card` if you need padding and background as well.
///
/// # Example
///
/// ```swift
/// Box {
///     Text("Boxed content")
/// }
///
/// Box(.doubleLine, color: .yellow) {
///     VStack {
///         Text("Line 1")
///         Text("Line 2")
///     }
/// }
/// ```
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
