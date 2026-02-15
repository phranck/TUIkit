//  🖥️ TUIKit — Terminal UI Kit for Swift
//  SelectableListRow.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - List Row Type

/// Defines the type of a row in a List, controlling selectability and focus behavior.
///
/// Section headers and footers are non-selectable visual separators, while content rows
/// are individually selectable and focusable. This enum provides type-safe classification.
public enum ListRowType<SelectionValue: Hashable & Sendable>: Sendable, Equatable {
    /// A section header (non-selectable, non-focusable).
    ///
    /// Headers render with dimmed styling and never participate in selection or focus.
    case header

    /// A content row with a selectable ID.
    ///
    /// Content rows are individually selectable and focusable. The associated ID
    /// is used for selection binding and focus navigation.
    case content(id: SelectionValue)

    /// A section footer (non-selectable, non-focusable).
    ///
    /// Footers render with dimmed styling and never participate in selection or focus.
    case footer
}

// MARK: - Selectable List Row

/// A List row with type information for selection and focus handling.
///
/// This structure replaces the generic ListRow to provide type-safe classification
/// of rows as headers, content, or footers. The type determines:
/// - Whether the row is selectable/focusable
/// - How the row renders (dimmed for headers/footers, normal for content)
/// - Whether the row ID participates in selection binding
public struct SelectableListRow<SelectionValue: Hashable & Sendable>: Sendable, Equatable {
    /// The row type (header, content with ID, or footer).
    public let type: ListRowType<SelectionValue>

    /// The rendered content buffer.
    public let buffer: FrameBuffer

    /// The badge value for this row (from environment).
    public let badge: BadgeValue?

    /// Creates a selectable list row with type, buffer, and optional badge.
    ///
    /// - Parameters:
    ///   - type: The row type (header, content, or footer).
    ///   - buffer: The rendered row content.
    ///   - badge: The badge value for this row (default: nil).
    public init(type: ListRowType<SelectionValue>, buffer: FrameBuffer, badge: BadgeValue? = nil) {
        self.type = type
        self.buffer = buffer
        self.badge = badge
    }

    /// Indicates whether this row can be selected and focused.
    ///
    /// Only content rows are selectable. Headers and footers are always false.
    public var isSelectable: Bool {
        if case .content = type {
            return true
        }
        return false
    }

    /// The row ID if this is a content row, otherwise nil.
    ///
    /// Only content rows have an ID. Headers and footers always return nil.
    public var id: SelectionValue? {
        if case .content(let id) = type {
            return id
        }
        return nil
    }
}
