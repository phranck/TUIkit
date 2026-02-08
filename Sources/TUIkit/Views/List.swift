//  🖥️ TUIKit — Terminal UI Kit for Swift
//  List.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - List Row

/// A single row in a list, containing an ID and rendered content.
///
/// `ListRow` wraps user-provided content and associates it with an identifier
/// for selection tracking. Rows can span multiple lines (multi-line content).
struct ListRow<ID: Hashable> {
    /// The unique identifier for this row.
    let id: ID

    /// The rendered content buffer for this row.
    let buffer: FrameBuffer

    /// The height of this row in lines.
    var height: Int { buffer.height }
}

// MARK: - List (Single Selection)

/// A scrollable list with keyboard navigation and single selection.
///
/// `List` displays a vertical collection of items inside a bordered container
/// with support for:
/// - Optional title in the border
/// - Optional footer (typically buttons or status text)
/// - Keyboard navigation (Up/Down/Home/End/PageUp/PageDown)
/// - Single selection via optional binding
/// - Multi-selection via Set binding
/// - Scrolling with automatic viewport management
/// - Visual states for focused and selected items
///
/// ## Usage
///
/// ```swift
/// @State var selectedID: String?
///
/// List("My Items", selection: $selectedID) {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
///
/// // With footer
/// List("My Items", selection: $selectedID) {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// } footer: {
///     ButtonRow {
///         Button("Add") { }
///         Button("Remove") { }
///     }
/// }
/// ```
///
/// ## Visual States
///
/// | State | Rendering |
/// |-------|-----------|
/// | Focused + Selected | Pulsing accent background, bold |
/// | Focused only | Highlight background bar |
/// | Selected only | Dimmed accent indicator |
/// | Neither | Default foreground |
///
/// ## Scroll Indicators
///
/// When content extends beyond the viewport, scroll indicators (arrows)
/// appear at the top and/or bottom edges inside the container.
public struct List<SelectionValue: Hashable & Sendable, Content: View, Footer: View>: View {
    /// The optional title displayed in the border.
    let title: String?

    /// The content of the list (typically ForEach).
    let content: Content

    /// The footer content (optional).
    let footer: Footer?

    /// Binding for single selection (optional ID).
    let singleSelection: Binding<SelectionValue?>?

    /// Binding for multi-selection (Set of IDs).
    let multiSelection: Binding<Set<SelectionValue>>?

    /// The selection mode derived from which binding is set.
    var selectionMode: SelectionMode {
        multiSelection != nil ? .multi : .single
    }

    /// The unique focus identifier for this list.
    let focusID: String?

    /// Whether the list is disabled.
    var isDisabled: Bool

    /// The maximum number of visible rows (nil = use available height).
    let maxVisibleRows: Int?

    /// The placeholder text shown when the list is empty.
    let emptyPlaceholder: String

    /// Whether to show separator before footer.
    let showFooterSeparator: Bool

    public var body: some View {
        _ListCore(
            title: title,
            content: content,
            footer: footer,
            singleSelection: singleSelection,
            multiSelection: multiSelection,
            selectionMode: selectionMode,
            focusID: focusID,
            isDisabled: isDisabled,
            maxVisibleRows: maxVisibleRows,
            emptyPlaceholder: emptyPlaceholder,
            showFooterSeparator: showFooterSeparator
        )
    }
}

// MARK: - Single Selection Initializers (with Footer)

extension List {
    /// Creates a list with single selection, title, and footer.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - showFooterSeparator: Whether to show separator before footer (default: true).
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        _ title: String,
        selection: Binding<SelectionValue?>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        showFooterSeparator: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = showFooterSeparator
    }

    /// Creates a list with single selection and footer, without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - showFooterSeparator: Whether to show separator before footer (default: true).
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        selection: Binding<SelectionValue?>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        showFooterSeparator: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = nil
        self.content = content()
        self.footer = footer()
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = showFooterSeparator
    }
}

// MARK: - Single Selection Initializers (without Footer)

extension List where Footer == EmptyView {
    /// Creates a list with single selection and a title.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        _ title: String,
        selection: Binding<SelectionValue?>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.footer = nil
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = false
    }

    /// Creates a list with single selection without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        selection: Binding<SelectionValue?>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.content = content()
        self.footer = nil
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = false
    }
}

// MARK: - Multi Selection Initializers (with Footer)

extension List {
    /// Creates a list with multi-selection, title, and footer.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the set of selected item IDs.
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - showFooterSeparator: Whether to show separator before footer (default: true).
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        _ title: String,
        selection: Binding<Set<SelectionValue>>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        showFooterSeparator: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = showFooterSeparator
    }

    /// Creates a list with multi-selection and footer, without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the set of selected item IDs.
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - showFooterSeparator: Whether to show separator before footer (default: true).
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        selection: Binding<Set<SelectionValue>>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        showFooterSeparator: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = nil
        self.content = content()
        self.footer = footer()
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = showFooterSeparator
    }
}

// MARK: - Multi Selection Initializers (without Footer)

extension List where Footer == EmptyView {
    /// Creates a list with multi-selection and a title.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the set of selected item IDs.
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        _ title: String,
        selection: Binding<Set<SelectionValue>>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.footer = nil
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = false
    }

    /// Creates a list with multi-selection without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the set of selected item IDs.
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - maxVisibleRows: Maximum visible rows (default: nil = available height).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        selection: Binding<Set<SelectionValue>>,
        focusID: String? = nil,
        maxVisibleRows: Int? = nil,
        emptyPlaceholder: String = "No items",
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.content = content()
        self.footer = nil
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
        self.showFooterSeparator = false
    }
}

// MARK: - Convenience Modifiers

extension List {
    /// Creates a disabled version of this list.
    ///
    /// - Parameter disabled: Whether the list is disabled.
    /// - Returns: A new list with the disabled state.
    public func disabled(_ disabled: Bool = true) -> List<SelectionValue, Content, Footer> {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }
}

// MARK: - List Core (Internal Rendering)

/// Internal core view that handles list rendering inside a ContainerView.
private struct _ListCore<SelectionValue: Hashable & Sendable, Content: View, Footer: View>: View, Renderable {
    let title: String?
    let content: Content
    let footer: Footer?
    let singleSelection: Binding<SelectionValue?>?
    let multiSelection: Binding<Set<SelectionValue>>?
    let selectionMode: SelectionMode
    let focusID: String?
    let isDisabled: Bool
    let maxVisibleRows: Int?
    let emptyPlaceholder: String
    let showFooterSeparator: Bool

    var body: Never {
        fatalError("_ListCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        let palette = context.environment.palette
        let style = context.environment.listStyle
        let stateStorage = context.tuiContext.stateStorage

        // Extract rows from content
        let rows = extractRows(from: content, context: context)

        // Handle empty state
        let contentLines: [String]
        let listHasFocus: Bool

        if rows.isEmpty {
            contentLines = [emptyPlaceholder]
            listHasFocus = false
        } else {
            // Calculate viewport height (reserve space for scroll indicators if needed)
            let availableHeight = context.availableHeight
            let viewportHeight = maxVisibleRows ?? max(1, availableHeight - 4) // Reserve for border + indicators

            // Get or create persistent focusID
            let focusIDKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 1)
            let focusIDBox: StateBox<String> = stateStorage.storage(
                for: focusIDKey,
                default: focusID ?? "list-\(context.identity.path)"
            )
            let persistedFocusID = focusIDBox.value

            // Get or create persistent handler
            let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
            let handlerBox: StateBox<ItemListHandler> = stateStorage.storage(
                for: handlerKey,
                default: ItemListHandler(
                    focusID: persistedFocusID,
                    itemCount: rows.count,
                    viewportHeight: viewportHeight,
                    selectionMode: selectionMode,
                    canBeFocused: !isDisabled
                )
            )
            let handler = handlerBox.value

            // Update handler with current values
            handler.itemCount = rows.count
            handler.viewportHeight = viewportHeight
            handler.canBeFocused = !isDisabled

            // Build selectableIndices set and itemIDs from typed rows
            var selectableIndices = Set<Int>()
            var itemIDs: [AnyHashable] = []
            for (index, row) in rows.enumerated() {
                if let id = row.id {
                    // Content row: use actual ID
                    itemIDs.append(AnyHashable(id))
                    selectableIndices.insert(index)
                } else {
                    // Header/footer: use index as placeholder (never selected)
                    itemIDs.append(AnyHashable(index))
                }
            }
            handler.itemIDs = itemIDs
            handler.selectableIndices = selectableIndices

            // Set up selection bindings
            if let binding = singleSelection {
                handler.singleSelection = Binding<AnyHashable?>(
                    get: { binding.wrappedValue.map { AnyHashable($0) } },
                    set: { newValue in
                        binding.wrappedValue = newValue?.base as? SelectionValue
                    }
                )
            }
            if let binding = multiSelection {
                handler.multiSelection = Binding<Set<AnyHashable>>(
                    get: { Set(binding.wrappedValue.map { AnyHashable($0) }) },
                    set: { newValue in
                        binding.wrappedValue = Set(newValue.compactMap { $0.base as? SelectionValue })
                    }
                )
            }

            // Ensure focused item is visible
            handler.ensureFocusedItemVisible()

            // Register with focus manager
            focusManager.register(handler, inSection: context.activeFocusSectionID)
            stateStorage.markActive(context.identity)

            // Check if this list has focus
            listHasFocus = focusManager.isFocused(id: persistedFocusID)

            // Calculate visible rows
            let visibleRows = calculateVisibleRows(
                rows: rows,
                handler: handler,
                viewportHeight: viewportHeight
            )

            // Calculate row width based on the widest row content
            let maxRowWidth = visibleRows.map { $0.row.buffer.width }.max() ?? 0
            let rowWidth = maxRowWidth

            // Build content lines
            var lines: [String] = []

            // Top scroll indicator
            if handler.hasContentAbove {
                lines.append(renderScrollIndicator(direction: .up, width: rowWidth, palette: palette))
            }

            // Render each visible row with alternating colors based on list style
            // Track section-relative content index for alternating colors
            var sectionContentIndex = 0
            for (rowIndex, row) in visibleRows {
                // Reset section content index on header
                if case .header = row.type {
                    sectionContentIndex = 0
                }

                let isFocused = handler.isFocused(at: rowIndex) && listHasFocus
                let isSelected = handler.isSelected(at: rowIndex)

                let styledLines = renderRow(
                    row: row,
                    isFocused: isFocused,
                    isSelected: isSelected,
                    rowWidth: rowWidth,
                    sectionContentIndex: sectionContentIndex,
                    style: style,
                    context: context,
                    palette: palette
                )
                lines.append(contentsOf: styledLines)

                // Increment section content index only for content rows
                if case .content = row.type {
                    sectionContentIndex += 1
                }
            }

            // Bottom scroll indicator
            if handler.hasContentBelow {
                lines.append(renderScrollIndicator(direction: .down, width: rowWidth, palette: palette))
            }

            contentLines = lines
        }

        // Create the list content as a simple view
        let listContent = _ListContentView(lines: contentLines)

        // Render using the shared container helper with footer support
        // Apply list style: border from showsBorder, padding from style
        let config = ContainerConfig(
            borderStyle: style.showsBorder ? context.environment.appearance.borderStyle : nil,
            borderColor: style.showsBorder ? palette.border : nil,
            titleColor: nil,
            padding: style.rowPadding,
            showFooterSeparator: showFooterSeparator
        )

        return renderContainer(
            title: title,
            config: config,
            content: listContent,
            footer: footer,
            context: context
        )
    }

    // MARK: - Row Extraction

    private func extractRows(from content: Content, context: RenderContext) -> [SelectableListRow<SelectionValue>] {
        // Check for SectionRowExtractor first (Section view)
        // This must come before ChildInfoProvider because Section conforms to both
        if let section = content as? SectionRowExtractor {
            return extractSectionRows(from: section, context: context)
        }

        // Check for ListRowExtractor (ForEach)
        if let extractor = content as? ListRowExtractor {
            let rows: [ListRow<SelectionValue>] = extractor.extractListRows(context: context)
            return rows.map { SelectableListRow(type: .content(id: $0.id), buffer: $0.buffer) }
        }

        // Check for ChildInfoProvider (handles TupleView with multiple children)
        if let provider = content as? ChildInfoProvider {
            return extractFromChildren(provider: provider, context: context)
        }

        // Fallback: render as single content row
        let buffer = TUIkit.renderToBuffer(content, context: context)
        if let zeroID = 0 as? SelectionValue {
            return [SelectableListRow(type: .content(id: zeroID), buffer: buffer)]
        }

        return []
    }

    /// Extracts rows from a ChildInfoProvider, handling Sections specially.
    private func extractFromChildren(
        provider: ChildInfoProvider,
        context: RenderContext
    ) -> [SelectableListRow<SelectionValue>] {
        var result: [SelectableListRow<SelectionValue>] = []
        let infos = provider.childInfos(context: context)

        for (index, info) in infos.enumerated() {
            guard let buffer = info.buffer else { continue }

            // Try to extract original view for Section detection
            // ChildInfo only has buffer, so we check the provider type
            if let indexID = index as? SelectionValue {
                result.append(SelectableListRow(type: .content(id: indexID), buffer: buffer))
            }
        }

        return result
    }

    /// Extracts typed rows from a Section (header + content + footer).
    private func extractSectionRows(
        from section: SectionRowExtractor,
        context: RenderContext
    ) -> [SelectableListRow<SelectionValue>] {
        var rows: [SelectableListRow<SelectionValue>] = []
        let info = section.extractSectionInfo(context: context)

        // Header (non-selectable)
        if let headerBuffer = info.headerBuffer {
            rows.append(SelectableListRow(type: .header, buffer: headerBuffer))
        }

        // Content rows (selectable)
        if let extractor = section as? ListRowExtractor {
            let contentRows: [ListRow<SelectionValue>] = extractor.extractListRows(context: context)
            for row in contentRows {
                rows.append(SelectableListRow(type: .content(id: row.id), buffer: row.buffer))
            }
        } else {
            // Fallback: render content as single row (if Section content is not ForEach)
            // Use the content buffer from SectionInfo
            // Note: This row is still selectable but uses index-based ID
            if !info.contentBuffer.lines.isEmpty, let indexID = 0 as? SelectionValue {
                rows.append(SelectableListRow(type: .content(id: indexID), buffer: info.contentBuffer))
            }
        }

        // Footer (non-selectable)
        if let footerBuffer = info.footerBuffer {
            rows.append(SelectableListRow(type: .footer, buffer: footerBuffer))
        }

        return rows
    }

    // MARK: - Visible Row Calculation

    private func calculateVisibleRows(
        rows: [SelectableListRow<SelectionValue>],
        handler: ItemListHandler,
        viewportHeight: Int
    ) -> [(index: Int, row: SelectableListRow<SelectionValue>)] {
        var result: [(Int, SelectableListRow<SelectionValue>)] = []
        var linesUsed = 0
        var currentIndex = handler.scrollOffset

        while currentIndex < rows.count && linesUsed < viewportHeight {
            let row = rows[currentIndex]
            let rowHeight = row.buffer.height

            if linesUsed + rowHeight <= viewportHeight {
                result.append((currentIndex, row))
                linesUsed += rowHeight
                currentIndex += 1
            } else {
                result.append((currentIndex, row))
                break
            }
        }

        return result
    }

    // MARK: - Row Rendering

    private func renderRow(
        row: SelectableListRow<SelectionValue>,
        isFocused: Bool,
        isSelected: Bool,
        rowWidth: Int,
        sectionContentIndex: Int,
        style: any ListStyle,
        context: RenderContext,
        palette: any Palette
    ) -> [String] {
        // Determine visual state based on row type
        // Headers and footers never show focus/selection background
        var backgroundColor: Color?

        switch row.type {
        case .header, .footer:
            // Headers/footers: no focus/selection/alternating background
            // They are already styled with dim via SectionInfo extraction
            backgroundColor = nil

        case .content:
            // Content rows: apply focus/selection/alternating logic
            if isFocused && isSelected {
                // Focused + Selected: pulsing accent background (highest priority)
                let dimAccent = palette.accent.opacity(0.35)
                backgroundColor = Color.lerp(dimAccent, palette.accent.opacity(0.5), phase: context.pulsePhase)
            } else if isFocused {
                // Focused only: highlight background bar
                backgroundColor = palette.focusBackground
            } else if isSelected {
                // Selected only: subtle background (darker than focus)
                backgroundColor = palette.accent.opacity(0.25)
            } else if style.alternatingRowColors {
                // Apply alternating row colors using section-relative index
                if sectionContentIndex.isMultiple(of: 2) {
                    // Even rows within section: subtle accent background
                    backgroundColor = palette.accent.opacity(0.15)
                } else {
                    // Odd rows within section: no background
                    backgroundColor = nil
                }
            } else {
                // No background
                backgroundColor = nil
            }
        }

        // Check for badge in environment (only for content rows, on first line only)
        let badge = context.environment.badgeValue
        let shouldRenderBadge = badge != nil && !badge!.isHidden && row.isSelectable

        // Render each line - row content keeps its own styling
        // All rows have padding from style, padded to same total width
        // Background bar covers the full width including padding
        return row.buffer.lines.enumerated().map { lineIndex, line in
            let lineLength = line.strippedLength

            // First line: make room for badge if present
            let badgeWidth = shouldRenderBadge && lineIndex == 0 ? badge!.displayText.count + 2 : 0
            let rightPadding = max(1, rowWidth - lineLength - badgeWidth + 1)
            var paddedLine = " " + line + String(repeating: " ", count: rightPadding)

            // Add badge to first line if needed
            if shouldRenderBadge && lineIndex == 0 {
                let badgeText = badge!.displayText
                let dimmedForeground = palette.foregroundTertiary
                let styledBadge = ANSIRenderer.colorize(badgeText, foreground: dimmedForeground)
                paddedLine = paddedLine + " " + styledBadge
            }

            if let bgColor = backgroundColor {
                return ANSIRenderer.applyPersistentBackground(paddedLine, color: bgColor)
            } else {
                return paddedLine
            }
        }
    }

    // MARK: - Scroll Indicators

    private enum ScrollDirection {
        case up, down
    }

    private func renderScrollIndicator(direction: ScrollDirection, width: Int, palette: any Palette) -> String {
        let arrow = direction == .up ? "▲" : "▼"
        let label = direction == .up ? " more above " : " more below "

        let styledArrow = ANSIRenderer.colorize(arrow, foreground: palette.foregroundTertiary)
        let styledLabel = ANSIRenderer.colorize(label, foreground: palette.foregroundTertiary)

        let indicatorWidth = 1 + label.count
        let padding = max(0, (width - indicatorWidth) / 2)

        return String(repeating: " ", count: padding) + styledArrow + styledLabel
    }
}

// MARK: - List Content View

/// Simple view that renders pre-computed lines.
private struct _ListContentView: View, Renderable {
    let lines: [String]

    var body: Never {
        fatalError("_ListContentView renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(lines: lines)
    }
}

// MARK: - List Row Extractor Protocol

/// Protocol for views that can provide list rows with IDs.
@MainActor
protocol ListRowExtractor {
    /// Extracts list rows with their associated IDs.
    func extractListRows<ID: Hashable>(context: RenderContext) -> [ListRow<ID>]
}

extension ForEach: ListRowExtractor {
    func extractListRows<RowID: Hashable>(context: RenderContext) -> [ListRow<RowID>] {
        data.compactMap { element -> ListRow<RowID>? in
            let elementID = element[keyPath: idKeyPath]
            let view = content(element)
            let buffer = TUIkit.renderToBuffer(view, context: context)

            guard let rowID = elementID as? RowID else { return nil }
            return ListRow(id: rowID, buffer: buffer)
        }
    }
}
