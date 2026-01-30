//
//  View+Border.swift
//  TUIKit
//
//  The .border() view extension for adding borders around views.
//

extension View {
    /// Adds a border around this view.
    ///
    /// The border reserves 2 characters of width (left and right),
    /// so the content is rendered with reduced available width.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello")
    ///     .border()  // Uses appearance.borderStyle
    ///
    /// Text("Rounded")
    ///     .border(.rounded, color: .cyan)
    ///
    /// Text("Double")
    ///     .border(.doubleLine, color: .yellow)
    /// ```
    ///
    /// - Parameters:
    ///   - style: The border style (default: appearance borderStyle).
    ///   - color: The border color (default: theme border color).
    /// - Returns: A view with a border.
    public func border(
        _ style: BorderStyle? = nil,
        color: Color? = nil
    ) -> some View {
        BorderedView(content: self, style: style, color: color)
    }
}
