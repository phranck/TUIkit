//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NavigationSplitView.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - NavigationSplitView

/// A view that presents views in two or three columns, where selections in
/// leading columns control presentations in subsequent columns.
///
/// You create a navigation split view with two or three columns, and typically
/// use it as the root view in a ``Scene``. People choose one or more items in
/// a leading column to display details about those items in subsequent columns.
///
/// ## Two-Column Layout
///
/// To create a two-column navigation split view, use the
/// ``init(sidebar:detail:)`` initializer:
///
/// ```swift
/// @State private var selectedID: String?
///
/// var body: some View {
///     NavigationSplitView {
///         List("Items", selection: $selectedID) {
///             ForEach(items) { item in
///                 Text(item.name)
///             }
///         }
///     } detail: {
///         if let id = selectedID {
///             DetailView(itemID: id)
///         } else {
///             Text("Select an item")
///         }
///     }
/// }
/// ```
///
/// ## Three-Column Layout
///
/// To create a three-column view, use the ``init(sidebar:content:detail:)``
/// initializer:
///
/// ```swift
/// @State private var categoryID: String?
/// @State private var itemID: String?
///
/// var body: some View {
///     NavigationSplitView {
///         List("Categories", selection: $categoryID) { ... }
///     } content: {
///         List("Items", selection: $itemID) { ... }
///     } detail: {
///         DetailView(itemID: itemID)
///     }
/// }
/// ```
///
/// ## Column Visibility
///
/// You can programmatically control column visibility using a
/// ``NavigationSplitViewVisibility`` binding:
///
/// ```swift
/// @State private var visibility = NavigationSplitViewVisibility.all
///
/// NavigationSplitView(columnVisibility: $visibility) {
///     SidebarView()
/// } detail: {
///     DetailView()
/// }
/// ```
///
/// ## Focus Navigation
///
/// Each column registers as a separate focus section. Use Tab/Shift+Tab to
/// move between columns, and Up/Down arrows to navigate within each column.
///
/// ## TUI-Specific Behavior
///
/// - Columns are separated by a vertical line character (`│`).
/// - The split view renders within the content area between AppHeader and StatusBar.
/// - Column widths are determined by the ``NavigationSplitViewStyle``.
/// - No automatic collapsing to stack (terminal width is typically sufficient).
public struct NavigationSplitView<Sidebar: View, Content: View, Detail: View>: View {
    /// The sidebar column content.
    let sidebar: Sidebar

    /// The content column (only used in three-column layouts).
    let content: Content

    /// The detail column content.
    let detail: Detail

    /// Whether this is a three-column layout.
    let isThreeColumn: Bool

    /// Binding to column visibility (optional).
    let columnVisibility: Binding<NavigationSplitViewVisibility>?

    public var body: some View {
        _NavigationSplitViewCore(
            sidebar: sidebar,
            content: content,
            detail: detail,
            isThreeColumn: isThreeColumn,
            columnVisibility: columnVisibility
        )
    }
}

// MARK: - Two-Column Initializers

extension NavigationSplitView where Content == EmptyView {
    /// Creates a two-column navigation split view.
    ///
    /// - Parameters:
    ///   - sidebar: The view to show in the leading column.
    ///   - detail: The view to show in the detail area.
    public init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.content = EmptyView()
        self.detail = detail()
        self.isThreeColumn = false
        self.columnVisibility = nil
    }

    /// Creates a two-column navigation split view with programmatic visibility control.
    ///
    /// - Parameters:
    ///   - columnVisibility: A binding to state that controls the visibility of the sidebar.
    ///   - sidebar: The view to show in the leading column.
    ///   - detail: The view to show in the detail area.
    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.content = EmptyView()
        self.detail = detail()
        self.isThreeColumn = false
        self.columnVisibility = columnVisibility
    }
}

// MARK: - Three-Column Initializers

extension NavigationSplitView {
    /// Creates a three-column navigation split view.
    ///
    /// - Parameters:
    ///   - sidebar: The view to show in the leading column.
    ///   - content: The view to show in the middle column.
    ///   - detail: The view to show in the detail area.
    public init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
        self.isThreeColumn = true
        self.columnVisibility = nil
    }

    /// Creates a three-column navigation split view with programmatic visibility control.
    ///
    /// - Parameters:
    ///   - columnVisibility: A binding to state that controls the visibility of leading columns.
    ///   - sidebar: The view to show in the leading column.
    ///   - content: The view to show in the middle column.
    ///   - detail: The view to show in the detail area.
    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility>,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder content: () -> Content,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.content = content()
        self.detail = detail()
        self.isThreeColumn = true
        self.columnVisibility = columnVisibility
    }
}

// MARK: - Internal Core

/// Internal view that handles the actual rendering of NavigationSplitView.
private struct _NavigationSplitViewCore<Sidebar: View, Content: View, Detail: View>: View, Renderable {
    let sidebar: Sidebar
    let content: Content
    let detail: Detail
    let isThreeColumn: Bool
    let columnVisibility: Binding<NavigationSplitViewVisibility>?

    /// The minimum width for any column in characters.
    private let minimumColumnWidth = 10

    /// The separator character between columns.
    private let separator = "│"

    var body: Never {
        fatalError("_NavigationSplitViewCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let style = context.environment.navigationSplitViewStyle
        let visibility = resolveVisibility()
        let palette = context.environment.palette

        // Calculate visible columns based on visibility
        let visibleColumns = calculateVisibleColumns(visibility: visibility)
        guard !visibleColumns.isEmpty else {
            return FrameBuffer()
        }

        // Calculate column widths
        let columnWidths = calculateColumnWidths(
            visibleColumns: visibleColumns,
            style: style,
            availableWidth: context.availableWidth
        )

        // Render each visible column
        var buffers: [FrameBuffer] = []
        for (index, column) in visibleColumns.enumerated() {
            let columnWidth = columnWidths[index]
            let columnContext = context.withAvailableWidth(columnWidth)

            // Register focus section for this column
            let sectionID = focusSectionID(for: column)
            context.environment.focusManager.registerSection(id: sectionID)

            // Create a context with the active focus section
            var sectionContext = columnContext
            sectionContext.activeFocusSectionID = sectionID

            let buffer = renderColumn(column, context: sectionContext)
            buffers.append(buffer)
        }

        // Combine buffers horizontally with separators
        return combineColumns(
            buffers: buffers,
            separator: separator,
            separatorColor: palette.border,
            availableHeight: context.availableHeight
        )
    }
}

// MARK: - Private Helpers

private extension _NavigationSplitViewCore {
    /// Resolves the effective visibility from the binding or defaults to `.all`.
    func resolveVisibility() -> NavigationSplitViewVisibility {
        if let binding = columnVisibility {
            let value = binding.wrappedValue
            // Resolve .automatic to .all
            if value == .automatic {
                return .all
            }
            return value
        }
        return .all
    }

    /// Calculates which columns should be visible based on visibility setting.
    func calculateVisibleColumns(visibility: NavigationSplitViewVisibility) -> [NavigationSplitViewColumn] {
        if isThreeColumn {
            switch visibility {
            case .all, .automatic:
                return [.sidebar, .content, .detail]
            case .doubleColumn:
                return [.content, .detail]
            case .detailOnly:
                return [.detail]
            default:
                return [.sidebar, .content, .detail]
            }
        } else {
            // Two-column layout
            switch visibility {
            case .all, .automatic, .doubleColumn:
                return [.sidebar, .detail]
            case .detailOnly:
                return [.detail]
            default:
                return [.sidebar, .detail]
            }
        }
    }

    /// Calculates the width for each visible column.
    func calculateColumnWidths(
        visibleColumns: [NavigationSplitViewColumn],
        style: any NavigationSplitViewStyle,
        availableWidth: Int
    ) -> [Int] {
        let separatorCount = max(0, visibleColumns.count - 1)
        let usableWidth = availableWidth - separatorCount

        guard usableWidth > 0 else {
            return Array(repeating: 0, count: visibleColumns.count)
        }

        // Calculate proportions based on style and column count
        let proportions: [Double]
        if isThreeColumn && visibleColumns.count == 3 {
            let props = style.threeColumnProportions
            proportions = [props.sidebar, props.content, props.detail]
        } else if visibleColumns.count == 2 {
            if visibleColumns.contains(.sidebar) {
                proportions = [style.sidebarProportion, 1.0 - style.sidebarProportion]
            } else {
                // content + detail (sidebar hidden in 3-column)
                proportions = [0.4, 0.6]
            }
        } else {
            // Single column (detail only)
            proportions = [1.0]
        }

        // Convert proportions to integer widths
        var widths: [Int] = []
        var remainingWidth = usableWidth

        for (index, proportion) in proportions.enumerated() {
            if index == proportions.count - 1 {
                // Last column gets remaining width
                widths.append(max(minimumColumnWidth, remainingWidth))
            } else {
                let width = max(minimumColumnWidth, Int(Double(usableWidth) * proportion))
                widths.append(width)
                remainingWidth -= width
            }
        }

        return widths
    }

    /// Returns the focus section ID for a column.
    func focusSectionID(for column: NavigationSplitViewColumn) -> String {
        switch column {
        case .sidebar:
            return "nav-split-sidebar"
        case .content:
            return "nav-split-content"
        case .detail:
            return "nav-split-detail"
        default:
            return "nav-split-unknown"
        }
    }

    /// Renders a single column.
    func renderColumn(_ column: NavigationSplitViewColumn, context: RenderContext) -> FrameBuffer {
        switch column {
        case .sidebar:
            return TUIkit.renderToBuffer(sidebar, context: context.withChildIdentity(type: type(of: sidebar)))
        case .content:
            return TUIkit.renderToBuffer(content, context: context.withChildIdentity(type: type(of: content)))
        case .detail:
            return TUIkit.renderToBuffer(detail, context: context.withChildIdentity(type: type(of: detail)))
        default:
            return FrameBuffer()
        }
    }

    /// Combines column buffers horizontally with separators.
    func combineColumns(
        buffers: [FrameBuffer],
        separator: String,
        separatorColor: Color,
        availableHeight: Int
    ) -> FrameBuffer {
        guard !buffers.isEmpty else { return FrameBuffer() }

        // Normalize all buffers to the same height
        let maxHeight = max(availableHeight, buffers.map(\.height).max() ?? 1)
        let styledSeparator = ANSIRenderer.colorize(separator, foreground: separatorColor)

        var result = FrameBuffer()

        for (index, buffer) in buffers.enumerated() {
            // Pad buffer to full height
            let paddedBuffer = padToHeight(buffer, height: maxHeight)

            if index == 0 {
                result = paddedBuffer
            } else {
                // Add separator column
                let separatorBuffer = FrameBuffer(
                    lines: Array(repeating: styledSeparator, count: maxHeight)
                )
                result.appendHorizontally(separatorBuffer, spacing: 0)
                result.appendHorizontally(paddedBuffer, spacing: 0)
            }
        }

        return result
    }

    /// Pads a buffer to the specified height.
    func padToHeight(_ buffer: FrameBuffer, height: Int) -> FrameBuffer {
        guard buffer.height < height else { return buffer }

        var lines = buffer.lines
        let emptyLine = String(repeating: " ", count: buffer.width)
        while lines.count < height {
            lines.append(emptyLine)
        }
        return FrameBuffer(lines: lines, width: buffer.width)
    }
}

// MARK: - Equatable Conformance

extension NavigationSplitView: Equatable where Sidebar: Equatable, Content: Equatable, Detail: Equatable {
    nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
        MainActor.assumeIsolated {
            lhs.sidebar == rhs.sidebar &&
            lhs.content == rhs.content &&
            lhs.detail == rhs.detail &&
            lhs.isThreeColumn == rhs.isThreeColumn
        }
    }
}
