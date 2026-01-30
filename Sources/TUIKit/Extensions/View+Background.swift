//
//  View+Background.swift
//  TUIKit
//
//  The .background() view extension for adding background colors.
//

extension View {
    /// Adds a background color to this view.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Warning!")
    ///     .foregroundColor(.black)
    ///     .background(.yellow)
    ///
    /// VStack {
    ///     Text("Header")
    /// }
    /// .background(.blue)
    /// ```
    ///
    /// - Parameter color: The background color.
    /// - Returns: A view with the background color applied.
    public func background(_ color: Color) -> ModifiedView<Self, BackgroundModifier> {
        modifier(BackgroundModifier(color: color))
    }
}
