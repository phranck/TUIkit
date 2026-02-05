//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+Environment.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

// MARK: - Environment

extension View {
    /// Sets an environment value for this view and its children.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the environment value.
    ///   - value: The value to set.
    /// - Returns: A view with the modified environment.
    public func environment<V>(
        _ keyPath: WritableKeyPath<EnvironmentValues, V>,
        _ value: V
    ) -> some View {
        EnvironmentModifier(content: self, keyPath: keyPath, value: value)
    }
}

// MARK: - Appearance

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
    /// Panel("Bold Style") {
    ///     content()
    /// }
    /// .appearance(.heavy)
    /// ```
    ///
    /// - Parameter appearance: The appearance to apply.
    /// - Returns: A view with the appearance applied.
    public func appearance(_ appearance: Appearance) -> some View {
        environment(\.appearance, appearance)
    }
}

// MARK: - Palette

extension View {
    /// Sets the color palette for this view and its descendants.
    ///
    /// # Example
    ///
    /// ```swift
    /// ContentView()
    ///     .palette(SystemPalette(.green))
    /// ```
    ///
    /// - Parameter palette: The palette to apply.
    /// - Returns: A view with the palette applied.
    public func palette(_ palette: any Palette) -> some View {
        environment(\.palette, palette)
    }
}
