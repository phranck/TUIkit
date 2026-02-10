//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NavigationSplitViewColumnWidthModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Column Width Preference

/// A preference key for column width values.
///
/// Used by ``NavigationSplitView`` to read column width preferences
/// set by the `.navigationSplitViewColumnWidth(_:)` modifier.
struct NavigationSplitViewColumnWidthKey: PreferenceKey {
    static let defaultValue: NavigationSplitViewColumnWidth? = nil

    static func reduce(value: inout NavigationSplitViewColumnWidth?, nextValue: () -> NavigationSplitViewColumnWidth?) {
        // Later values override earlier values
        if let next = nextValue() {
            value = next
        }
    }
}

/// Column width configuration for NavigationSplitView.
///
/// Stores the fixed width or min/ideal/max constraints for a column.
struct NavigationSplitViewColumnWidth: Equatable, Sendable {
    /// A fixed column width in characters.
    let fixed: Int?

    /// The minimum column width in characters.
    let min: Int?

    /// The ideal column width in characters.
    let ideal: Int?

    /// The maximum column width in characters.
    let max: Int?

    /// Creates a fixed-width column configuration.
    init(fixed: Int) {
        self.fixed = fixed
        self.min = nil
        self.ideal = nil
        self.max = nil
    }

    /// Creates a flexible column width configuration.
    init(min: Int?, ideal: Int?, max: Int?) {
        self.fixed = nil
        self.min = min
        self.ideal = ideal
        self.max = max
    }
}

// MARK: - Column Width Modifier

/// A view that sets the preferred width of a navigation split view column.
///
/// This view sets a preference that ``NavigationSplitView`` can read to
/// determine column widths.
struct NavigationSplitViewColumnWidthView<Content: View>: View {
    /// The content view.
    let content: Content

    /// The column width configuration.
    let columnWidth: NavigationSplitViewColumnWidth

    var body: Never {
        fatalError("NavigationSplitViewColumnWidthView renders via Renderable")
    }
}

extension NavigationSplitViewColumnWidthView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Set the preference for NavigationSplitView to read
        context.tuiContext.preferences.setValue(columnWidth, forKey: NavigationSplitViewColumnWidthKey.self)

        // Render content
        return TUIkit.renderToBuffer(content, context: context)
    }
}

// MARK: - View Extension

extension View {
    /// Sets the preferred width for a navigation split view column.
    ///
    /// Use this modifier on a column's content to specify an exact width
    /// in characters.
    ///
    /// ```swift
    /// NavigationSplitView {
    ///     List { ... }
    ///         .navigationSplitViewColumnWidth(30)
    /// } detail: {
    ///     DetailView()
    /// }
    /// ```
    ///
    /// - Parameter width: The preferred column width in characters.
    /// - Returns: A view with the column width preference set.
    public func navigationSplitViewColumnWidth(_ width: Int) -> some View {
        NavigationSplitViewColumnWidthView(
            content: self,
            columnWidth: NavigationSplitViewColumnWidth(fixed: width)
        )
    }

    /// Sets flexible width constraints for a navigation split view column.
    ///
    /// Use this modifier on a column's content to specify minimum, ideal,
    /// and maximum width constraints in characters.
    ///
    /// ```swift
    /// NavigationSplitView {
    ///     List { ... }
    ///         .navigationSplitViewColumnWidth(min: 20, ideal: 30, max: 50)
    /// } detail: {
    ///     DetailView()
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - min: The minimum column width in characters (optional).
    ///   - ideal: The ideal column width in characters (optional).
    ///   - max: The maximum column width in characters (optional).
    /// - Returns: A view with the column width preference set.
    public func navigationSplitViewColumnWidth(
        min: Int? = nil,
        ideal: Int? = nil,
        max: Int? = nil
    ) -> some View {
        NavigationSplitViewColumnWidthView(
            content: self,
            columnWidth: NavigationSplitViewColumnWidth(min: min, ideal: ideal, max: max)
        )
    }
}
