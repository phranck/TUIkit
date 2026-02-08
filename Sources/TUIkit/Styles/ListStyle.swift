//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ListStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A style that customizes the appearance of lists.
///
/// List styles control how lists render, including borders, padding, row separators,
/// and background colors. TUIkit provides two built-in styles that match SwiftUI's behavior:
/// - ``PlainListStyle``: Minimal appearance with no borders or background
/// - ``InsetGroupedListStyle``: Bordered container with inset padding and alternating row colors
///
/// # Usage
///
/// ```swift
/// List {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
/// .listStyle(.plain)
///
/// List {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
/// .listStyle(.insetGrouped)
/// ```
public protocol ListStyle: Sendable {
    /// Whether the list should display borders around the container.
    var showsBorder: Bool { get }

    /// The padding applied to list rows.
    var rowPadding: EdgeInsets { get }

    /// The style of list grouping (plain, inset, or insetGrouped).
    var groupingStyle: ListGroupingStyle { get }

    /// Whether rows should alternate between two background colors.
    var alternatingRowColors: Bool { get }

    /// The color pair for alternating rows (even, odd).
    /// If nil, uses the palette's semantic colors.
    var alternatingColorPair: (evenColor: Color, oddColor: Color)? { get }
}

// MARK: - List Grouping Style

/// Defines how a list groups its content visually.
public enum ListGroupingStyle: Sendable {
    /// Minimal grouping with no visual container.
    case plain

    /// Inset grouping with borders and padding.
    case inset

    /// Grouped style with borders, padding, and section separations.
    case insetGrouped
}

// MARK: - Plain List Style

/// A list style that uses minimal visual styling with no borders or backgrounds.
///
/// PlainListStyle renders lists with no border, no padding insets,
/// and no row background colors. This matches SwiftUI's `.listStyle(.plain)`.
///
/// # Rendering
/// - Rows display full width without padding
/// - No border around the list
/// - No row separators or backgrounds
/// - Content takes full available space
public struct PlainListStyle: ListStyle {
    /// Creates a plain list style.
    public init() {}

    public var showsBorder: Bool {
        false
    }

    public var rowPadding: EdgeInsets {
        EdgeInsets(all: 0)
    }

    public var groupingStyle: ListGroupingStyle {
        .plain
    }

    public var alternatingRowColors: Bool {
        false
    }

    public var alternatingColorPair: (evenColor: Color, oddColor: Color)? {
        nil
    }
}

// MARK: - Inset Grouped List Style

/// A list style that uses borders, inset padding, and section grouping with alternating row colors.
///
/// InsetGroupedListStyle renders lists with a border, inset padding, and optionally
/// alternating row background colors. This matches SwiftUI's `.listStyle(.insetGrouped)`.
///
/// # Rendering
/// - Rows have inset padding (1 character on each side)
/// - Border surrounds the entire list
/// - Rows alternate between two subtle background colors
/// - Even-indexed rows: accent color at low opacity
/// - Odd-indexed rows: no background (or default)
public struct InsetGroupedListStyle: ListStyle {
    /// Creates an inset grouped list style.
    public init() {}

    public var showsBorder: Bool {
        true
    }

    public var rowPadding: EdgeInsets {
        EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 1)
    }

    public var groupingStyle: ListGroupingStyle {
        .insetGrouped
    }

    public var alternatingRowColors: Bool {
        true
    }

    public var alternatingColorPair: (evenColor: Color, oddColor: Color)? {
        // Uses palette semantic colors during rendering (nil = use default)
        nil
    }
}

// MARK: - List Style Convenience

extension ListStyle {
    /// The plain list style with no borders or backgrounds.
    public static var plain: some ListStyle {
        PlainListStyle()
    }

    /// The inset grouped list style with borders and alternating rows.
    public static var insetGrouped: some ListStyle {
        InsetGroupedListStyle()
    }
}
