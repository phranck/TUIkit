//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TableColumn.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Column Width

/// Defines the width behavior for a table column.
public enum ColumnWidth: Sendable, Equatable {
    /// Fixed width in characters.
    case fixed(Int)

    /// Flexible width that expands to fill available space.
    /// Multiple flexible columns share space equally.
    case flexible

    /// Proportional width as a ratio of total available space.
    /// For example, `.ratio(0.5)` takes 50% of available width.
    case ratio(Double)
}

// MARK: - Table Column

/// Defines a column in a Table view.
///
/// `TableColumn` specifies how to display a property of the data items,
/// including the column header, alignment, width, and value extraction.
///
/// ## Usage
///
/// ```swift
/// Table(files, selection: $selectedID) {
///     TableColumn("Name", value: \.name)
///     TableColumn("Size", value: \.formattedSize)
///         .width(.fixed(10))
///         .alignment(.trailing)
///     TableColumn("Modified", value: \.modifiedDate)
///         .width(.ratio(0.3))
/// }
/// ```
///
/// ## Width Modes
///
/// | Mode | Behavior |
/// |------|----------|
/// | `.fixed(n)` | Exactly n characters wide |
/// | `.flexible` | Expands to fill remaining space (shared equally) |
/// | `.ratio(r)` | Takes r proportion of available width (0.0-1.0) |
public struct TableColumn<Value>: Sendable {
    /// The column header title.
    public let title: String

    /// The horizontal alignment for column content.
    public var alignment: HorizontalAlignment

    /// The width mode for this column.
    public var width: ColumnWidth

    /// Extracts the display value from a data item.
    let valueExtractor: @Sendable (Value) -> String

    /// Creates a table column with a key path to a String property.
    ///
    /// - Parameters:
    ///   - title: The column header title.
    ///   - value: A key path to the String property to display.
    public init(_ title: String, value: KeyPath<Value, String> & Sendable) where Value: Sendable {
        self.title = title
        self.alignment = .leading
        self.width = .flexible
        self.valueExtractor = { item in item[keyPath: value] }
    }

    /// Creates a table column with a custom value extractor.
    ///
    /// - Parameters:
    ///   - title: The column header title.
    ///   - value: A closure that extracts the display string from a data item.
    public init(_ title: String, value: @escaping @Sendable (Value) -> String) {
        self.title = title
        self.alignment = .leading
        self.width = .flexible
        self.valueExtractor = value
    }
}

// MARK: - Modifiers

extension TableColumn {
    /// Sets the alignment for this column.
    ///
    /// - Parameter alignment: The horizontal alignment.
    /// - Returns: A modified column with the specified alignment.
    public func alignment(_ alignment: HorizontalAlignment) -> TableColumn {
        var copy = self
        copy.alignment = alignment
        return copy
    }

    /// Sets the width mode for this column.
    ///
    /// - Parameter width: The column width mode.
    /// - Returns: A modified column with the specified width.
    public func width(_ width: ColumnWidth) -> TableColumn {
        var copy = self
        copy.width = width
        return copy
    }
}

// MARK: - Column Content Extraction

extension TableColumn {
    /// Extracts the display value from an item.
    ///
    /// - Parameter item: The data item.
    /// - Returns: The string to display in this column.
    func value(for item: Value) -> String {
        valueExtractor(item)
    }
}

// MARK: - Table Column Builder

/// A result builder for composing table columns.
@resultBuilder
public struct TableColumnBuilder<Value> {
    /// Builds an array of columns from a single column.
    public static func buildBlock(_ columns: TableColumn<Value>...) -> [TableColumn<Value>] {
        columns
    }

    /// Builds an array of columns from an array.
    public static func buildArray(_ components: [[TableColumn<Value>]]) -> [TableColumn<Value>] {
        components.flatMap { $0 }
    }

    /// Builds an optional column.
    public static func buildOptional(_ component: [TableColumn<Value>]?) -> [TableColumn<Value>] {
        component ?? []
    }

    /// Builds the first branch of an if-else.
    public static func buildEither(first component: [TableColumn<Value>]) -> [TableColumn<Value>] {
        component
    }

    /// Builds the second branch of an if-else.
    public static func buildEither(second component: [TableColumn<Value>]) -> [TableColumn<Value>] {
        component
    }
}
