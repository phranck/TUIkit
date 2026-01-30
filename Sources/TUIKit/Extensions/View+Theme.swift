//
//  View+Theme.swift
//  TUIKit
//
//  The .theme() view extension for setting the color theme.
//

extension View {
    /// Sets the theme for this view and its descendants.
    ///
    /// # Example
    ///
    /// ```swift
    /// ContentView()
    ///     .theme(GreenPhosphorTheme())
    /// ```
    ///
    /// - Parameter theme: The theme to apply.
    /// - Returns: A view with the theme applied.
    public func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
