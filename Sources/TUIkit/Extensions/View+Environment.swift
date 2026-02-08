//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+Environment.swift
//
//  Created by LAYERED.work
//  License: MIT

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

// MARK: - List Style

extension View {
    /// Sets the list style for List views in this view and its descendants.
    ///
    /// The list style controls how lists render, including borders, padding,
    /// and row backgrounds. Built-in styles match SwiftUI's behavior:
    /// - ``PlainListStyle``: Minimal appearance with no borders
    /// - ``InsetGroupedListStyle``: Bordered with inset padding and alternating rows
    ///
    /// # Example
    ///
    /// ```swift
    /// List {
    ///     ForEach(items) { item in
    ///         Text(item.name)
    ///     }
    /// }
    /// .listStyle(.plain)
    ///
    /// List {
    ///     ForEach(items) { item in
    ///         Text(item.name)
    ///     }
    /// }
    /// .listStyle(.insetGrouped)
    /// ```
    ///
    /// - Parameter style: The list style to apply.
    /// - Returns: A view with the list style applied.
    public func listStyle(_ style: any ListStyle) -> some View {
        environment(\.listStyle, style)
    }
}
