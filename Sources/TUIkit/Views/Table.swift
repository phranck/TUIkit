//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Table.swift
//
//  Created by LAYERED.work
//  License: MIT


// MARK: - Table

/// A scrollable table with columns, keyboard navigation, and selection.
///
/// `Table` displays tabular data inside a bordered container with:
/// - Column headers in the container header section
/// - Optional footer section
/// - Keyboard navigation (Up/Down/Home/End/PageUp/PageDown)
/// - Single or multi-selection via bindings
/// - Configurable column widths (fixed, flexible, ratio)
/// - Column alignment (leading, center, trailing)
/// - ANSI-aware column layout
/// - Scrolling with automatic viewport management
///
/// ## Usage
///
/// ```swift
/// struct FileInfo: Identifiable {
///     let id: String
///     let name: String
///     let size: String
///     let modified: String
/// }
///
/// @State var selectedID: String?
///
/// Table(files, selection: $selectedID) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Size", value: \.size)
///         .width(.fixed(10))
///         .alignment(.trailing)
///     TableColumn("Modified", value: \.modified)
///         .width(.ratio(0.3))
/// }
/// ```
///
/// ## Column Spacing
///
/// Columns are separated by spaces (no vertical lines) for a clean look.
public struct Table<Value: Identifiable & Sendable>: View where Value.ID: Hashable {
    /// The data items to display.
    let data: [Value]

    /// The column definitions.
    let columns: [TableColumn<Value>]

    /// Binding for single selection (optional ID).
    let singleSelection: Binding<Value.ID?>?

    /// Binding for multi-selection (Set of IDs).
    let multiSelection: Binding<Set<Value.ID>>?

    /// The selection mode derived from which binding is set.
    var selectionMode: SelectionMode {
        multiSelection != nil ? .multi : .single
    }

    /// The unique focus identifier for this table.
    let focusID: String?

    /// Whether the table is disabled.
    var isDisabled: Bool

    /// The placeholder text shown when the table is empty.
    let emptyPlaceholder: String

    /// The spacing between columns in characters.
    let columnSpacing: Int

    public var body: some View {
        _TableCore(
            data: data,
            columns: columns,
            singleSelection: singleSelection,
            multiSelection: multiSelection,
            selectionMode: selectionMode,
            focusID: focusID,
            isDisabled: isDisabled,
            emptyPlaceholder: emptyPlaceholder,
            columnSpacing: columnSpacing
        )
    }
}

// MARK: - Single Selection Initializer

extension Table {
    /// Creates a table with single selection.
    ///
    /// - Parameters:
    ///   - data: The data items to display.
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - focusID: The unique focus identifier (default: auto-generated).

    ///   - columnSpacing: Spacing between columns (default: 2).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - columns: A builder that defines the table columns.
    public init(
        _ data: [Value],
        selection: Binding<Value.ID?>,
        focusID: String? = nil,

        columnSpacing: Int = 2,
        emptyPlaceholder: String = "No items",
        @TableColumnBuilder<Value> columns: () -> [TableColumn<Value>]
    ) {
        self.data = data
        self.columns = columns()
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = focusID
        self.isDisabled = false

        self.columnSpacing = columnSpacing
        self.emptyPlaceholder = emptyPlaceholder
    }
}

// MARK: - Multi Selection Initializer

extension Table {
    /// Creates a table with multi-selection.
    ///
    /// - Parameters:
    ///   - data: The data items to display.
    ///   - selection: A binding to the set of selected item IDs.
    ///   - focusID: The unique focus identifier (default: auto-generated).

    ///   - columnSpacing: Spacing between columns (default: 2).
    ///   - emptyPlaceholder: Placeholder text when empty (default: "No items").
    ///   - columns: A builder that defines the table columns.
    public init(
        _ data: [Value],
        selection: Binding<Set<Value.ID>>,
        focusID: String? = nil,

        columnSpacing: Int = 2,
        emptyPlaceholder: String = "No items",
        @TableColumnBuilder<Value> columns: () -> [TableColumn<Value>]
    ) {
        self.data = data
        self.columns = columns()
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = focusID
        self.isDisabled = false

        self.columnSpacing = columnSpacing
        self.emptyPlaceholder = emptyPlaceholder
    }
}

// MARK: - Convenience Modifiers

extension Table {
    /// Creates a disabled version of this table.
    ///
    /// - Parameter disabled: Whether the table is disabled.
    /// - Returns: A new table with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Table {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }
}

// MARK: - Table Core (Internal Rendering)

/// Internal core view that handles table rendering inside a ContainerView.
private struct _TableCore<Value: Identifiable & Sendable>: View, Renderable where Value.ID: Hashable {
    let data: [Value]
    let columns: [TableColumn<Value>]
    let singleSelection: Binding<Value.ID?>?
    let multiSelection: Binding<Set<Value.ID>>?
    let selectionMode: SelectionMode
    let focusID: String?
    let isDisabled: Bool
    let emptyPlaceholder: String
    let columnSpacing: Int

    var body: Never {
        fatalError("_TableCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let palette = context.environment.palette
        let stateStorage = context.tuiContext.stateStorage

        // Calculate available width inside container (subtract border + padding)
        let innerWidth = max(0, context.availableWidth - 4)

        // Calculate column widths
        let columnWidths = calculateColumnWidths(
            availableWidth: innerWidth,
            spacing: columnSpacing
        )

        // Build header line from column titles
        let headerLine = renderHeader(columnWidths: columnWidths, palette: palette)

        // Handle empty state
        let contentLines: [String]

        if data.isEmpty {
            contentLines = [emptyPlaceholder]
        } else {
            // Calculate viewport height
            let availableHeight = context.availableHeight
            let viewportHeight = max(1, availableHeight - 6) // Reserve for border + header + indicators

            // Focus registration via shared helper
            let persistedFocusID = FocusRegistration.persistFocusID(
                context: context,
                explicitFocusID: focusID,
                defaultPrefix: "table",
                propertyIndex: 1  // focusID
            )

            // Get or create persistent handler
            let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)  // handler
            let handlerBox: StateBox<ItemListHandler> = stateStorage.storage(
                for: handlerKey,
                default: ItemListHandler(
                    focusID: persistedFocusID,
                    itemCount: data.count,
                    viewportHeight: viewportHeight,
                    selectionMode: selectionMode,
                    canBeFocused: !isDisabled
                )
            )
            let handler = handlerBox.value

            // Update handler with current values
            handler.itemCount = data.count
            handler.viewportHeight = viewportHeight
            handler.canBeFocused = !isDisabled
            handler.itemIDs = data.map { AnyHashable($0.id) }

            // Set up selection bindings
            handler.configureSelectionBindings(single: singleSelection, multi: multiSelection)

            // Ensure focused item is visible
            handler.ensureFocusedItemVisible()

            FocusRegistration.register(context: context, handler: handler)
            let tableHasFocus = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)

            // Build content lines
            var lines: [String] = []

            // Top scroll indicator
            if handler.hasContentAbove {
                lines.append(renderScrollIndicator(direction: .up, width: innerWidth, palette: palette))
            }

            // Data rows
            let visibleRange = handler.visibleRange
            for rowIndex in visibleRange {
                let item = data[rowIndex]
                let isFocused = handler.isFocused(at: rowIndex) && tableHasFocus
                let isSelected = handler.isSelected(at: rowIndex)

                lines.append(renderRow(
                    item: item,
                    columnWidths: columnWidths,
                    isFocused: isFocused,
                    isSelected: isSelected,
                    rowWidth: innerWidth,
                    context: context,
                    palette: palette
                ))
            }

            // Bottom scroll indicator
            if handler.hasContentBelow {
                lines.append(renderScrollIndicator(direction: .down, width: innerWidth, palette: palette))
            }

            contentLines = lines
        }

        // Create the table content as a simple view
        let tableContent = _TableContentView(lines: contentLines)

        // Create header view
        let headerView = _TableHeaderView(line: headerLine)

        // Wrap in ContainerView with header separator (column titles are in header)
        let container = ContainerView(
            title: nil,
            style: ContainerStyle(showHeaderSeparator: true, showFooterSeparator: false),
            padding: EdgeInsets(horizontal: 1, vertical: 0)
        ) {
            VStack(spacing: 0) {
                headerView
                tableContent
            }
        }

        return TUIkit.renderToBuffer(container, context: context)
    }

    // MARK: - Column Width Calculation

    private func calculateColumnWidths(availableWidth: Int, spacing: Int) -> [Int] {
        guard !columns.isEmpty else { return [] }

        let totalSpacing = spacing * (columns.count - 1)
        let indicatorWidth = 2
        let contentWidth = max(0, availableWidth - totalSpacing - indicatorWidth)

        var widths = [Int](repeating: 0, count: columns.count)
        var usedWidth = 0
        var flexibleIndices: [Int] = []

        for (index, column) in columns.enumerated() {
            switch column.width {
            case .fixed(let fixedWidth):
                widths[index] = fixedWidth
                usedWidth += fixedWidth
            case .ratio(let ratio):
                let ratioWidth = Int(Double(contentWidth) * ratio)
                widths[index] = ratioWidth
                usedWidth += ratioWidth
            case .flexible:
                flexibleIndices.append(index)
            }
        }

        if !flexibleIndices.isEmpty {
            let remainingWidth = max(0, contentWidth - usedWidth)
            let perColumn = remainingWidth / flexibleIndices.count
            let remainder = remainingWidth % flexibleIndices.count

            for (offset, index) in flexibleIndices.enumerated() {
                widths[index] = perColumn + (offset < remainder ? 1 : 0)
            }
        }

        return widths.map { max(1, $0) }
    }

    // MARK: - Header Rendering

    private func renderHeader(columnWidths: [Int], palette: any Palette) -> String {
        let spacing = String(repeating: " ", count: columnSpacing)

        let cells = zip(columns, columnWidths).map { column, width -> String in
            let aligned = alignText(column.title, width: width, alignment: column.alignment)
            return ANSIRenderer.colorize(aligned, foreground: palette.foregroundSecondary, bold: true)
        }

        return "  " + cells.joined(separator: spacing)
    }

    // MARK: - Row Rendering

    private func renderRow(
        item: Value,
        columnWidths: [Int],
        isFocused: Bool,
        isSelected: Bool,
        rowWidth: Int,
        context: RenderContext,
        palette: any Palette
    ) -> String {
        let spacing = String(repeating: " ", count: columnSpacing)
        let visualState = rowVisualState(
            isFocused: isFocused, isSelected: isSelected,
            context: context, palette: palette
        )

        let styledIndicator = ANSIRenderer.colorize(
            visualState.indicator, foreground: visualState.indicatorColor
        )

        // Build cells using environment foreground color
        let foregroundColor = context.environment.foregroundStyle ?? palette.foreground
        let cells = zip(columns, columnWidths).map { column, width -> String in
            let value = column.value(for: item)
            let aligned = alignText(value, width: width, alignment: column.alignment)
            return ANSIRenderer.colorize(aligned, foreground: foregroundColor)
        }

        let content = styledIndicator + " " + cells.joined(separator: spacing)

        if let bgColor = visualState.backgroundColor {
            let visibleLength = content.strippedLength
            let padding = max(0, rowWidth - visibleLength)
            let paddedContent = content + String(repeating: " ", count: padding)
            return paddedContent.withPersistentBackground(bgColor)
        } else {
            return content
        }
    }

    /// Determines indicator symbol, indicator color, and background color for a table row.
    private func rowVisualState(
        isFocused: Bool,
        isSelected: Bool,
        context: RenderContext,
        palette: any Palette
    ) -> (indicator: String, indicatorColor: Color, backgroundColor: Color?) {
        if isFocused && isSelected {
            let dimAccent = palette.accent.opacity(ViewConstants.focusPulseMin)
            let bg = Color.lerp(dimAccent, palette.accent.opacity(ViewConstants.focusPulseMax), phase: context.pulsePhase)
            return ("●", palette.accent, bg)
        } else if isFocused {
            return (" ", palette.foregroundTertiary, palette.focusBackground)
        } else if isSelected {
            return ("●", palette.accent.opacity(ViewConstants.selectionIndicator), nil)
        } else {
            return (" ", palette.foregroundTertiary, nil)
        }
    }

    // MARK: - Text Alignment

    private func alignText(_ text: String, width: Int, alignment: HorizontalAlignment) -> String {
        let visibleLength = text.strippedLength
        let padding = max(0, width - visibleLength)

        switch alignment {
        case .leading:
            return text + String(repeating: " ", count: padding)
        case .center:
            let leftPad = padding / 2
            let rightPad = padding - leftPad
            return String(repeating: " ", count: leftPad) + text + String(repeating: " ", count: rightPad)
        case .trailing:
            return String(repeating: " ", count: padding) + text
        }
    }

}

// MARK: - Table Content View

/// Simple view that renders pre-computed lines.
private struct _TableContentView: View, Renderable {
    let lines: [String]

    var body: Never {
        fatalError("_TableContentView renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(lines: lines)
    }
}

// MARK: - Table Header View

/// Simple view that renders the header line.
private struct _TableHeaderView: View, Renderable {
    let line: String

    var body: Never {
        fatalError("_TableHeaderView renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(lines: [line])
    }
}
