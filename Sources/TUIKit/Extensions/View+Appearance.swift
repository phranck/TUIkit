//
//  View+Appearance.swift
//  TUIKit
//
//  The .appearance() view extension for setting the UI appearance.
//

extension View {
    /// Sets the appearance for this view and its descendants.
    ///
    /// # Example
    ///
    /// ```swift
    /// ContentView()
    ///     .appearance(.rounded)
    ///
    /// // Local override
    /// Panel("ASCII Style") {
    ///     content()
    /// }
    /// .appearance(.ascii)
    /// ```
    ///
    /// - Parameter appearance: The appearance to apply.
    /// - Returns: A view with the appearance applied.
    public func appearance(_ appearance: Appearance) -> some View {
        environment(\.appearance, appearance)
    }
}
