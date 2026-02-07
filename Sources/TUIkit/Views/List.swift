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
/// ```
///
/// ## Visual States
///
/// | State | Rendering |
/// |-------|-----------|
/// | Focused + Selected | Pulsing accent, bold |
/// | Focused only | Accent foreground (cursor) |
/// | Selected only | Dimmed accent |
/// | Neither | Default foreground |
///
/// ## Scroll Indicators
///
/// When content extends beyond the viewport, scroll indicators (arrows)
/// appear at the top and/or bottom edges inside the container.
public struct List<SelectionValue: Hashable, Content: View>: View {
    /// The optional title displayed in the border.
    let title: String?

    /// The content of the list (typically ForEach).
    let content: Content

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

    public var body: some View {
        _ListCore(
            title: title,
            content: content,
            singleSelection: singleSelection,
            multiSelection: multiSelection,
            selectionMode: selectionMode,
            focusID: focusID,
            isDisabled: isDisabled,
            maxVisibleRows: maxVisibleRows,
            emptyPlaceholder: emptyPlaceholder
        )
    }
}

// MARK: - Single Selection Initializers

extension List {
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
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
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
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
    }
}

// MARK: - Multi Selection Initializers

extension List {
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
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
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
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = focusID
        self.isDisabled = false
        self.maxVisibleRows = maxVisibleRows
        self.emptyPlaceholder = emptyPlaceholder
    }
}

// MARK: - Convenience Modifiers

extension List {
    /// Creates a disabled version of this list.
    ///
    /// - Parameter disabled: Whether the list is disabled.
    /// - Returns: A new list with the disabled state.
    public func disabled(_ disabled: Bool = true) -> List<SelectionValue, Content> {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }
}

// MARK: - List Core (Internal Rendering)

/// Internal core view that handles list rendering inside a ContainerView.
private struct _ListCore<SelectionValue: Hashable, Content: View>: View, Renderable {
    let title: String?
    let content: Content
    let singleSelection: Binding<SelectionValue?>?
    let multiSelection: Binding<Set<SelectionValue>>?
    let selectionMode: SelectionMode
    let focusID: String?
    let isDisabled: Bool
    let maxVisibleRows: Int?
    let emptyPlaceholder: String

    var body: Never {
        fatalError("_ListCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        let palette = context.environment.palette
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
            handler.itemIDs = rows.map { AnyHashable($0.id) }

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

            // Build content lines
            var lines: [String] = []

            // Top scroll indicator
            if handler.hasContentAbove {
                lines.append(renderScrollIndicator(direction: .up, width: context.availableWidth - 4, palette: palette))
            }

            // Render each visible row
            for (rowIndex, row) in visibleRows {
                let isFocused = handler.isFocused(at: rowIndex) && listHasFocus
                let isSelected = handler.isSelected(at: rowIndex)

                let styledLines = renderRow(
                    row: row,
                    isFocused: isFocused,
                    isSelected: isSelected,
                    context: context,
                    palette: palette
                )
                lines.append(contentsOf: styledLines)
            }

            // Bottom scroll indicator
            if handler.hasContentBelow {
                lines.append(renderScrollIndicator(direction: .down, width: context.availableWidth - 4, palette: palette))
            }

            contentLines = lines
        }

        // Create the list content as a simple view
        let listContent = _ListContentView(lines: contentLines)

        // Wrap in ContainerView with title
        let container = ContainerView(
            title: title,
            style: ContainerStyle(showHeaderSeparator: false, showFooterSeparator: false),
            padding: EdgeInsets(horizontal: 1, vertical: 0)
        ) {
            listContent
        }

        return TUIkit.renderToBuffer(container, context: context)
    }

    // MARK: - Row Extraction

    private func extractRows(from content: Content, context: RenderContext) -> [ListRow<SelectionValue>] {
        if let extractor = content as? ListRowExtractor {
            return extractor.extractListRows(context: context)
        }

        if let provider = content as? ChildInfoProvider {
            let infos = provider.childInfos(context: context)
            return infos.enumerated().compactMap { index, info -> ListRow<SelectionValue>? in
                guard let buffer = info.buffer else { return nil }
                if let indexID = index as? SelectionValue {
                    return ListRow(id: indexID, buffer: buffer)
                }
                return nil
            }
        }

        let buffer = TUIkit.renderToBuffer(content, context: context)
        if let zeroID = 0 as? SelectionValue {
            return [ListRow(id: zeroID, buffer: buffer)]
        }

        return []
    }

    // MARK: - Visible Row Calculation

    private func calculateVisibleRows(
        rows: [ListRow<SelectionValue>],
        handler: ItemListHandler,
        viewportHeight: Int
    ) -> [(index: Int, row: ListRow<SelectionValue>)] {
        var result: [(Int, ListRow<SelectionValue>)] = []
        var linesUsed = 0
        var currentIndex = handler.scrollOffset

        while currentIndex < rows.count && linesUsed < viewportHeight {
            let row = rows[currentIndex]
            let rowHeight = row.height

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
        row: ListRow<SelectionValue>,
        isFocused: Bool,
        isSelected: Bool,
        context: RenderContext,
        palette: any Palette
    ) -> [String] {
        let indicator: String
        let foregroundColor: Color

        if isFocused && isSelected {
            let dimAccent = palette.accent.opacity(0.35)
            foregroundColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
            indicator = "●"
        } else if isFocused {
            foregroundColor = palette.accent
            indicator = "›"
        } else if isSelected {
            foregroundColor = palette.accent.opacity(0.6)
            indicator = "●"
        } else {
            foregroundColor = palette.foreground
            indicator = " "
        }

        let styledIndicator = ANSIRenderer.colorize(
            indicator,
            foreground: foregroundColor,
            bold: isFocused
        )

        return row.buffer.lines.enumerated().map { lineIndex, line in
            if lineIndex == 0 {
                return styledIndicator + " " + line
            } else {
                return "  " + line
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
