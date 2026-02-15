//  🖥️ TUIKit — Terminal UI Kit for Swift
//  _ListCore.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - List Core (Internal Rendering)

/// Internal core view that handles list rendering inside a ContainerView.
struct _ListCore<SelectionValue: Hashable & Sendable, Content: View, Footer: View>: View, Renderable {
    let title: String?
    let content: Content
    let footer: Footer?
    let singleSelection: Binding<SelectionValue?>?
    let multiSelection: Binding<Set<SelectionValue>>?
    let selectionMode: SelectionMode
    let focusID: String?
    let isDisabled: Bool
    let emptyPlaceholder: String
    let showFooterSeparator: Bool

    var body: Never {
        fatalError("_ListCore renders via Renderable")
    }

    // swiftlint:disable:next function_body_length
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let palette = context.environment.palette
        let style = context.environment.listStyle
        let stateStorage = context.environment.stateStorage!

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
            let viewportHeight = max(1, availableHeight - 4) // Reserve for border + indicators

            let persistedFocusID = FocusRegistration.persistFocusID(
                context: context,
                explicitFocusID: focusID,
                defaultPrefix: "list",
                propertyIndex: 1  // focusID
            )

            // Get or create persistent handler
            let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)  // handler
            let handlerBox: StateBox<ItemListHandler<SelectionValue>> = stateStorage.storage(
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
            var itemIDs: [SelectionValue?] = []
            for (index, row) in rows.enumerated() {
                if let id = row.id {
                    // Content row: use actual ID
                    itemIDs.append(id)
                    selectableIndices.insert(index)
                } else {
                    // Header/footer: nil (non-selectable)
                    itemIDs.append(nil)
                }
            }
            handler.itemIDs = itemIDs
            handler.selectableIndices = selectableIndices

            // Assign selection bindings directly (type-safe, no AnyHashable conversion)
            handler.singleSelection = singleSelection
            handler.multiSelection = multiSelection

            // Ensure focused item is visible
            handler.ensureFocusedItemVisible()

            FocusRegistration.register(context: context, handler: handler)
            listHasFocus = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)

            // Calculate visible rows
            let visibleRows = calculateVisibleRows(
                rows: rows,
                handler: handler,
                viewportHeight: viewportHeight
            )

            // Calculate row width based on the widest row content
            // If an explicit frame width is set, use the available width minus border padding
            let maxRowWidth = visibleRows.map { $0.row.buffer.width }.max() ?? 0
            let rowWidth: Int
            if context.hasExplicitWidth {
                // Use available width minus 2 for borders only (content padding is 0)
                rowWidth = max(maxRowWidth, context.availableWidth - 2)
            } else {
                rowWidth = maxRowWidth
            }

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

        // Pad content to fill available height (SwiftUI behavior: List is greedy)
        // Reserve space for: title line (1) + top border (1) + bottom border (1) + footer if present
        let footerHeight = footer != nil ? 2 : 0  // footer line + separator
        let borderOverhead = style.showsBorder ? 2 : 0  // top + bottom border
        let titleOverhead = title != nil ? 1 : 0
        let targetContentHeight = max(1, context.availableHeight - borderOverhead - titleOverhead - footerHeight)

        var paddedContentLines = contentLines
        if paddedContentLines.count < targetContentHeight {
            let emptyLinesToAdd = targetContentHeight - paddedContentLines.count
            paddedContentLines.append(contentsOf: Array(repeating: "", count: emptyLinesToAdd))
        }

        // Create the list content as a simple view
        let listContent = _ListContentView(lines: paddedContentLines)

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
            return rows.map { SelectableListRow(type: .content(id: $0.id), buffer: $0.buffer, badge: $0.badge) }
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
                rows.append(SelectableListRow(type: .content(id: row.id), buffer: row.buffer, badge: row.badge))
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
        handler: ItemListHandler<SelectionValue>,
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
        let backgroundColor = rowBackgroundColor(
            rowType: row.type,
            isFocused: isFocused,
            isSelected: isSelected,
            sectionContentIndex: sectionContentIndex,
            style: style,
            context: context,
            palette: palette
        )

        // Check for badge on the row (only for content rows, on first line only)
        let badge = row.badge
        let shouldRenderBadge = badge != nil && !badge!.isHidden && row.isSelectable

        // Render each line with padding and optional badge
        return row.buffer.lines.enumerated().map { lineIndex, line in
            if shouldRenderBadge && lineIndex == 0 {
                return renderLineWithBadge(
                    line: line, badge: badge!, rowWidth: rowWidth,
                    backgroundColor: backgroundColor, palette: palette
                )
            } else {
                return renderPlainLine(
                    line: line, rowWidth: rowWidth, backgroundColor: backgroundColor
                )
            }
        }
    }

    /// Determines the background color for a row based on its type and visual state.
    private func rowBackgroundColor(
        rowType: ListRowType<SelectionValue>,
        isFocused: Bool,
        isSelected: Bool,
        sectionContentIndex: Int,
        style: any ListStyle,
        context: RenderContext,
        palette: any Palette
    ) -> Color? {
        switch rowType {
        case .header, .footer:
            return nil

        case .content:
            if isFocused && isSelected {
                let dimAccent = palette.accent.opacity(ViewConstants.focusPulseMin)
                return Color.lerp(dimAccent, palette.accent.opacity(ViewConstants.focusPulseMax), phase: context.environment.pulsePhase)
            } else if isFocused {
                return palette.focusBackground
            } else if isSelected {
                return palette.accent.opacity(ViewConstants.selectedBackground)
            } else if style.alternatingRowColors && sectionContentIndex.isMultiple(of: 2) {
                return palette.accent.opacity(ViewConstants.alternatingRowBackground)
            } else {
                return nil
            }
        }
    }

    /// Renders a line with a right-aligned badge.
    /// Layout: [1 pad][content][fill padding][badge][1 pad]
    private func renderLineWithBadge(
        line: String,
        badge: BadgeValue,
        rowWidth: Int,
        backgroundColor: Color?,
        palette: any Palette
    ) -> String {
        let lineLength = line.strippedLength
        let badgeText = badge.displayText
        let styledBadge = ANSIRenderer.colorize(badgeText, foreground: palette.foregroundTertiary)

        let badgeWidth = badgeText.count
        let usedWidth = 1 + lineLength + badgeWidth + 1
        let fillPadding = max(1, rowWidth - usedWidth)
        let paddedLine = " " + line + String(repeating: " ", count: fillPadding) + styledBadge + " "

        return paddedLine.withPersistentBackground(backgroundColor)
    }

    /// Renders a plain line without badge.
    /// Layout: [1 pad][content][right padding]
    private func renderPlainLine(
        line: String,
        rowWidth: Int,
        backgroundColor: Color?
    ) -> String {
        let lineLength = line.strippedLength
        let usedWidth = 1 + lineLength
        let rightPadding = max(1, rowWidth - usedWidth)
        let paddedLine = " " + line + String(repeating: " ", count: rightPadding)

        return paddedLine.withPersistentBackground(backgroundColor)
    }
}

// MARK: - List Content View

/// Simple view that renders pre-computed lines.
struct _ListContentView: View, Renderable {
    let lines: [String]

    var body: Never {
        fatalError("_ListContentView renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(lines: lines)
    }
}
