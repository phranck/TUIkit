//
//  View+Overlay.swift
//  TUIKit
//
//  The .overlay() view extension for layering views.
//

extension View {
    /// Layers the specified view on top of this view.
    ///
    /// The overlay is positioned according to the specified alignment
    /// within the bounds of the base view.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Background content here")
    ///     .overlay(alignment: .center) {
    ///         Text("Centered overlay")
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - alignment: The alignment of the overlay (default: .center).
    ///   - content: The overlay content.
    /// - Returns: A view with the overlay applied.
    public func overlay<Overlay: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Overlay
    ) -> some View {
        OverlayModifier(base: self, overlay: content(), alignment: alignment)
    }
}
