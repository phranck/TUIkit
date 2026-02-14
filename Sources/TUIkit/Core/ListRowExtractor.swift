//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListRowExtractor.swift
//
//  Created by LAYERED.work
//  License: MIT


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

    /// The badge value for this row (from environment).
    let badge: BadgeValue?

    /// The height of this row in lines.
    var height: Int { buffer.height }
}

// MARK: - List Row Extractor Protocol

/// Protocol for views that can provide list rows with IDs.
@MainActor
protocol ListRowExtractor {
    /// Extracts list rows with their associated IDs.
    func extractListRows<ID: Hashable>(context: RenderContext) -> [ListRow<ID>]
}

// MARK: - ForEach Conformance

extension ForEach: ListRowExtractor {
    func extractListRows<RowID: Hashable>(context: RenderContext) -> [ListRow<RowID>] {
        data.compactMap { element -> ListRow<RowID>? in
            let elementID = element[keyPath: idKeyPath]
            let view = content(element)

            // Extract badge if the view is wrapped in a BadgeModifier
            let badge = extractBadgeValue(from: view)

            // Render the view
            let buffer = TUIkit.renderToBuffer(view, context: context)

            guard let rowID = elementID as? RowID else { return nil }
            return ListRow(id: rowID, buffer: buffer, badge: badge)
        }
    }
}
