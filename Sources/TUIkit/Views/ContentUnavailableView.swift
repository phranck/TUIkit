//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ContentUnavailableView.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Content Unavailable View

/// A view that displays a placeholder when content is unavailable.
///
/// Use `ContentUnavailableView` to communicate that the current view has
/// no content to display. Common use cases include empty search results,
/// empty lists, and error states.
///
/// The view arranges a label, an optional description, and optional actions
/// vertically, centered in the available space.
///
/// ## Examples
///
/// ```swift
/// // Simple text label
/// ContentUnavailableView("No Items")
///
/// // With description
/// ContentUnavailableView("No Items", description: "Add items to get started.")
///
/// // Full ViewBuilder API
/// ContentUnavailableView {
///     Text("No Results")
/// } description: {
///     Text("Try a different search term.")
/// } actions: {
///     Button("Clear Search") { }
/// }
///
/// // Search preset
/// ContentUnavailableView.search
/// ContentUnavailableView.search(text: "query")
/// ```
public struct ContentUnavailableView<Label: View, Description: View, Actions: View>: View {
    /// The label view (typically a title or icon).
    let label: Label

    /// The description view (typically explanatory text).
    let description: Description

    /// The action views (typically buttons).
    let actions: Actions

    /// Creates a content unavailable view with label, description, and actions.
    ///
    /// - Parameters:
    ///   - label: The primary label view.
    ///   - description: The description view below the label.
    ///   - actions: The action views below the description.
    public init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder description: () -> Description,
        @ViewBuilder actions: () -> Actions
    ) {
        self.label = label()
        self.description = description()
        self.actions = actions()
    }

    public var body: some View {
        _ContentUnavailableViewCore(
            label: label,
            description: description,
            actions: actions
        )
    }
}

// MARK: - Convenience Initializers

extension ContentUnavailableView where Description == EmptyView, Actions == EmptyView {
    /// Creates a content unavailable view with only a label.
    ///
    /// - Parameter label: The primary label view.
    public init(@ViewBuilder label: () -> Label) {
        self.init(label: label, description: { EmptyView() }, actions: { EmptyView() })
    }
}

extension ContentUnavailableView where Actions == EmptyView {
    /// Creates a content unavailable view with a label and description.
    ///
    /// - Parameters:
    ///   - label: The primary label view.
    ///   - description: The description view below the label.
    public init(
        @ViewBuilder label: () -> Label,
        @ViewBuilder description: () -> Description
    ) {
        self.init(label: label, description: description, actions: { EmptyView() })
    }
}

extension ContentUnavailableView where Label == Text, Description == EmptyView, Actions == EmptyView {
    /// Creates a content unavailable view with a title string.
    ///
    /// - Parameter title: The title text.
    public init(_ title: String) {
        self.init(label: { Text(title) }, description: { EmptyView() }, actions: { EmptyView() })
    }
}

extension ContentUnavailableView where Label == Text, Description == Text, Actions == EmptyView {
    /// Creates a content unavailable view with a title and description string.
    ///
    /// - Parameters:
    ///   - title: The title text.
    ///   - description: The description text.
    public init(_ title: String, description: String) {
        self.init(label: { Text(title) }, description: { Text(description) }, actions: { EmptyView() })
    }
}

// MARK: - Search Preset

extension ContentUnavailableView where Label == Text, Description == Text, Actions == EmptyView {
    /// A content unavailable view for empty search results.
    ///
    /// Displays "No Results" with a generic description.
    public static var search: ContentUnavailableView<Text, Text, EmptyView> {
        ContentUnavailableView<Text, Text, EmptyView>(
            label: { Text("No Results") },
            description: { Text("Check the spelling or try a new search.") },
            actions: { EmptyView() }
        )
    }

    /// Creates a content unavailable view for empty search results with a query.
    ///
    /// Displays "No Results for '\(text)'" with a generic description.
    ///
    /// - Parameter text: The search query that produced no results.
    /// - Returns: A configured content unavailable view.
    public static func search(text: String) -> ContentUnavailableView<Text, Text, EmptyView> {
        ContentUnavailableView<Text, Text, EmptyView>(
            label: { Text("No Results for '\(text)'") },
            description: { Text("Check the spelling or try a new search.") },
            actions: { EmptyView() }
        )
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of ContentUnavailableView.
///
/// Renders label, description, and actions as a vertically stacked layout,
/// centered horizontally in the available width.
private struct _ContentUnavailableViewCore<Label: View, Description: View, Actions: View>: View, Renderable {
    let label: Label
    let description: Description
    let actions: Actions

    var body: Never {
        fatalError("_ContentUnavailableViewCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let palette = context.environment.palette

        // Render label
        let labelBuffer = TUIkit.renderToBuffer(label, context: context)

        // Render description with secondary foreground color
        var descContext = context
        if descContext.environment.foregroundStyle == nil {
            descContext.environment.foregroundStyle = palette.foregroundSecondary
        }
        let descBuffer = TUIkit.renderToBuffer(description, context: descContext)

        // Render actions
        let actionsBuffer = TUIkit.renderToBuffer(actions, context: context)

        // Combine vertically with spacing
        var result = FrameBuffer()

        if !labelBuffer.isEmpty {
            result.appendVertically(labelBuffer)
        }

        if !descBuffer.isEmpty {
            result.appendVertically(descBuffer, spacing: 1)
        }

        if !actionsBuffer.isEmpty {
            result.appendVertically(actionsBuffer, spacing: 1)
        }

        // Center each line horizontally
        guard !result.isEmpty else { return result }

        let targetWidth = context.availableWidth
        var centeredLines: [String] = []
        centeredLines.reserveCapacity(result.lines.count)

        for line in result.lines {
            let visibleWidth = line.strippedLength
            let leftPad = max(0, (targetWidth - visibleWidth) / 2)
            centeredLines.append(String(repeating: " ", count: leftPad) + line)
        }

        return FrameBuffer(lines: centeredLines)
    }
}
