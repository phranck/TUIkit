//
//  View+Dimmed.swift
//  TUIKit
//
//  The .dimmed() view extension for applying dim effects.
//

extension View {
    /// Applies a dimming effect to the view content.
    ///
    /// This reduces the visual intensity of the content using the ANSI dim
    /// escape code. Useful for background content when displaying overlays.
    ///
    /// # Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("This content will be dimmed")
    ///     Text("All text is affected")
    /// }
    /// .dimmed()
    /// ```
    ///
    /// - Returns: A view with the dimming effect applied.
    public func dimmed() -> some View {
        DimmedModifier(content: self)
    }
}
