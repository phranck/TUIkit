//
//  StatusBar.swift
//  TUIkit
//
//  A status bar that displays keyboard shortcuts and context-sensitive actions.
//  Always rendered at the bottom of the terminal, never dimmed by overlays.
//

import Foundation

// MARK: - StatusBar View

/// A status bar that displays at the bottom of the terminal.
///
/// The status bar shows keyboard shortcuts and their descriptions.
/// It's rendered separately from the main view tree and is never
/// affected by overlays or dimming.
///
/// # Layout
///
/// The status bar consists of two containers:
/// - **User Container** (left): User-defined items, sorted by order
/// - **System Container** (right): System items (quit, help, theme), fixed order
///
/// ```
/// ┌────────────────────────────────────────┬───────────────────────────────┐
/// │ s save   x action   ↑↓ nav             │ q quit   ? help   t theme    │
/// └────────────────────────────────────────┴───────────────────────────────┘
/// ```
///
/// # Usage
///
/// To set status bar items, use the environment:
///
/// ```swift
/// // In renderToBuffer(context:):
/// let statusBar = context.environment.statusBar
/// statusBar.setItems([
///     StatusBarItem(shortcut: "s", label: "save"),
///     StatusBarItem(shortcut: "↑↓", label: "nav"),
/// ])
/// ```
public struct StatusBar: View {
    /// User items (left container).
    public let userItems: [any StatusBarItemProtocol]

    /// System items (right container).
    public let systemItems: [any StatusBarItemProtocol]

    /// The visual style.
    public let style: StatusBarStyle

    /// The horizontal alignment of user items within the left container.
    public let alignment: StatusBarAlignment

    /// The highlight color for shortcut keys.
    public let highlightColor: Color

    /// The label color.
    public let labelColor: Color?

    /// Creates a status bar with separate user and system items.
    ///
    /// - Parameters:
    ///   - userItems: User-defined items (left container).
    ///   - systemItems: System items (right container).
    ///   - style: The visual style (default: `.compact`).
    ///   - alignment: The alignment of user items (default: `.leading`).
    ///   - highlightColor: The color for shortcut keys (default: `.cyan`).
    ///   - labelColor: The color for labels (default: nil, terminal default).
    public init(
        userItems: [any StatusBarItemProtocol] = [],
        systemItems: [any StatusBarItemProtocol] = [],
        style: StatusBarStyle = .compact,
        alignment: StatusBarAlignment = .leading,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil
    ) {
        self.userItems = userItems
        self.systemItems = systemItems
        self.style = style
        self.alignment = alignment
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    /// Creates a status bar with all items combined (legacy compatibility).
    ///
    /// - Parameters:
    ///   - items: All items to display (will be treated as user items).
    ///   - style: The visual style (default: `.compact`).
    ///   - alignment: The horizontal alignment (default: `.justified`).
    ///   - highlightColor: The color for shortcut keys (default: `.cyan`).
    ///   - labelColor: The color for labels (default: nil, terminal default).
    public init(
        items: [any StatusBarItemProtocol],
        style: StatusBarStyle = .compact,
        alignment: StatusBarAlignment = .justified,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil
    ) {
        self.userItems = items
        self.systemItems = []
        self.style = style
        self.alignment = alignment
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    /// Creates a status bar using a builder.
    ///
    /// - Parameters:
    ///   - style: The visual style.
    ///   - alignment: The horizontal alignment.
    ///   - highlightColor: The color for shortcut keys.
    ///   - labelColor: The color for labels.
    ///   - builder: A closure that returns items.
    public init(
        style: StatusBarStyle = .compact,
        alignment: StatusBarAlignment = .justified,
        highlightColor: Color = .cyan,
        labelColor: Color? = nil,
        @StatusBarItemBuilder _ builder: () -> [any StatusBarItemProtocol]
    ) {
        self.userItems = builder()
        self.systemItems = []
        self.style = style
        self.alignment = alignment
        self.highlightColor = highlightColor
        self.labelColor = labelColor
    }

    /// All items combined (sorted user items, then filtered system items).
    ///
    /// User items are sorted by their `order` property.
    /// System items maintain their fixed order (quit, help, theme).
    /// User items override system items with the same shortcut.
    /// Use this for event handling to check all items.
    public var allItems: [any StatusBarItemProtocol] {
        let userShortcuts = Set(userItems.map { $0.shortcut })
        let filteredSystemItems = systemItems.filter { !userShortcuts.contains($0.shortcut) }
        return userItems.sorted { $0.order < $1.order } + filteredSystemItems
    }

    /// Whether the status bar has any items to display.
    public var hasItems: Bool {
        !userItems.isEmpty || !systemItems.isEmpty
    }

    public var body: Never {
        fatalError("StatusBar renders via Renderable")
    }
}

// MARK: - StatusBar Rendering

extension StatusBar: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Get shortcuts used by user items (for deduplication)
        let userShortcuts = Set(userItems.map { $0.shortcut })

        // Filter out system items that are overridden by user items
        let filteredSystemItems = systemItems.filter { !userShortcuts.contains($0.shortcut) }

        // Combine: sorted user items + filtered system items (fixed order)
        let sortedUserItems = userItems.sorted { $0.order < $1.order }
        let combinedItems = sortedUserItems + filteredSystemItems

        guard !combinedItems.isEmpty else {
            return FrameBuffer()
        }

        // Build item strings
        let itemStrings = combinedItems.map { item -> String in
            let shortcutStyled = ANSIRenderer.render(
                item.shortcut,
                with: {
                    var style = TextStyle()
                    style.foregroundColor = highlightColor
                    style.isBold = true
                    return style
                }()
            )

            let labelStyled: String
            if let color = labelColor {
                labelStyled = ANSIRenderer.render(
                    " " + item.label,
                    with: {
                        var style = TextStyle()
                        style.foregroundColor = color
                        return style
                    }()
                )
            } else {
                labelStyled = " " + item.label
            }

            return shortcutStyled + labelStyled
        }

        switch style {
        case .compact:
            return renderCompact(itemStrings: itemStrings, width: context.availableWidth)

        case .bordered:
            return renderBordered(itemStrings: itemStrings, width: context.availableWidth, context: context)
        }
    }

    /// Aligns content within the given width based on alignment setting.
    ///
    /// - Parameters:
    ///   - itemStrings: The styled item strings to align.
    ///   - width: The total available width.
    /// - Returns: The aligned content string.
    private func alignContent(itemStrings: [String], width: Int) -> String {
        let separator = "  "  // Two spaces between items for non-justified

        switch alignment {
        case .leading:
            let content = " " + itemStrings.joined(separator: separator)
            return content.padToVisibleWidth(width)

        case .trailing:
            let content = itemStrings.joined(separator: separator) + " "
            let contentWidth = content.strippedLength
            let padding = max(0, width - contentWidth)
            return String(repeating: " ", count: padding) + content

        case .center:
            let content = itemStrings.joined(separator: separator)
            let contentWidth = content.strippedLength
            let totalPadding = max(0, width - contentWidth)
            let leftPadding = totalPadding / 2
            let rightPadding = totalPadding - leftPadding
            return String(repeating: " ", count: leftPadding) + content + String(repeating: " ", count: rightPadding)

        case .justified:
            return justifyContent(itemStrings: itemStrings, width: width)
        }
    }

    /// Distributes items evenly across the width (justified alignment).
    ///
    /// Items are distributed so that the space on the left edge, between items,
    /// and on the right edge are all equal.
    ///
    /// - Parameters:
    ///   - itemStrings: The styled item strings to distribute.
    ///   - width: The total available width.
    /// - Returns: The justified content string.
    private func justifyContent(itemStrings: [String], width: Int) -> String {
        guard !itemStrings.isEmpty else {
            return String(repeating: " ", count: width)
        }

        guard itemStrings.count > 1 else {
            // Single item: center it
            let content = itemStrings.first ?? ""
            let contentWidth = content.strippedLength
            let totalPadding = max(0, width - contentWidth)
            let leftPadding = totalPadding / 2
            let rightPadding = totalPadding - leftPadding
            return String(repeating: " ", count: leftPadding) + content + String(repeating: " ", count: rightPadding)
        }

        // Calculate total content width (without gaps)
        let totalContentWidth = itemStrings.reduce(0) { sum, item in
            sum + item.strippedLength
        }

        // For n items, we have n+1 gaps (left edge, between each item, right edge)
        let gapCount = itemStrings.count + 1
        let availableForGaps = max(0, width - totalContentWidth)
        let gapWidth = availableForGaps / gapCount
        let extraSpace = availableForGaps % gapCount

        // Build justified string with equal gaps
        var result = ""

        // Left edge gap (gets extra space if available)
        let leftGapExtra = extraSpace > 0 ? 1 : 0
        result += String(repeating: " ", count: gapWidth + leftGapExtra)

        for (index, item) in itemStrings.enumerated() {
            result += item

            if index < itemStrings.count - 1 {
                // Gap between items
                // Distribute extra space to middle gaps (after left edge took one if available)
                let gapIndex = index + 1  // 0 = left edge, 1..n-1 = between items, n = right edge
                let extra = gapIndex < extraSpace ? 1 : 0
                result += String(repeating: " ", count: gapWidth + extra)
            }
        }

        // Right edge gap
        let rightGapIndex = itemStrings.count
        let rightGapExtra = rightGapIndex < extraSpace ? 1 : 0
        result += String(repeating: " ", count: gapWidth + rightGapExtra)

        // Ensure the result fills the width exactly
        return result.padToVisibleWidth(width)
    }

    /// Renders the compact style (single line with alignment).
    private func renderCompact(itemStrings: [String], width: Int) -> FrameBuffer {
        let line = alignContent(itemStrings: itemStrings, width: width)
        return FrameBuffer(lines: [line])
    }

    /// Renders the bordered style using the current appearance's border style.
    private func renderBordered(itemStrings: [String], width: Int, context: RenderContext) -> FrameBuffer {
        let innerWidth = width - BorderRenderer.borderWidthOverhead
        let content = alignContent(itemStrings: itemStrings, width: innerWidth)

        // Check if we're using block appearance for special rendering
        let isBlockAppearance = context.environment.appearance.rawId == .block
        if isBlockAppearance {
            return renderBlockBordered(content: content, innerWidth: innerWidth, context: context)
        }

        // Standard bordered rendering with regular box-drawing characters
        let border = context.environment.appearance.borderStyle
        let borderColor = context.environment.palette.border

        return FrameBuffer(lines: [
            BorderRenderer.standardTopBorder(style: border, innerWidth: innerWidth, color: borderColor),
            BorderRenderer.standardContentLine(content: content, innerWidth: innerWidth, style: border, color: borderColor),
            BorderRenderer.standardBottomBorder(style: border, innerWidth: innerWidth, color: borderColor),
        ])
    }

    /// Renders block-style status bar with half-block characters.
    private func renderBlockBordered(content: String, innerWidth: Int, context: RenderContext) -> FrameBuffer {
        let statusBarBg = context.environment.palette.statusBarBackground

        return FrameBuffer(lines: [
            BorderRenderer.blockTopBorder(innerWidth: innerWidth, color: statusBarBg),
            BorderRenderer.blockContentLine(content: content, innerWidth: innerWidth, sectionColor: statusBarBg),
            BorderRenderer.blockBottomBorder(innerWidth: innerWidth, color: statusBarBg),
        ])
    }
}

// MARK: - Status Bar Height Helper

extension StatusBar {
    /// The height of the status bar in lines.
    public var height: Int {
        switch style {
        case .compact:
            return 1
        case .bordered:
            return 3
        }
    }
}
