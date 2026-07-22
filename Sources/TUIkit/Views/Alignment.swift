//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Alignment.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Alignment ID

/// A type that you use to create custom alignment guides.
///
/// Matches SwiftUI's extensible alignment model: conform a type to
/// `AlignmentID` and use it to construct ``HorizontalAlignment`` or
/// ``VerticalAlignment`` values. The default value is expressed in
/// SwiftUI's continuous geometry; the renderer quantizes resolved
/// offsets to whole terminal cells deterministically.
public protocol AlignmentID {
    /// Returns the value of the corresponding guide when not otherwise set.
    ///
    /// - Parameter context: The dimensions of the view to align.
    /// - Returns: The guide's default position along its axis.
    static func defaultValue(in context: ViewDimensions) -> CGFloat
}

// MARK: - View Dimensions

/// A view's size in the container's coordinate space.
///
/// Terminal adaptation of SwiftUI's `ViewDimensions`: widths and heights
/// are whole cells surfaced as `CGFloat` so alignment math matches
/// SwiftUI's continuous geometry.
public struct ViewDimensions: Equatable, Sendable {
    /// The view's width.
    public let width: CGFloat

    /// The view's height.
    public let height: CGFloat

    /// Creates dimensions from whole terminal cells.
    init(cellWidth: Int, cellHeight: Int) {
        self.width = CGFloat(cellWidth)
        self.height = CGFloat(cellHeight)
    }

    /// Returns the value of the given horizontal guide.
    public subscript(guide: HorizontalAlignment) -> CGFloat {
        guide.id.defaultValue(in: self)
    }

    /// Returns the value of the given vertical guide.
    public subscript(guide: VerticalAlignment) -> CGFloat {
        guide.id.defaultValue(in: self)
    }
}

// MARK: - Horizontal Alignment

/// An alignment position along the horizontal axis.
///
/// Extensible like SwiftUI's `HorizontalAlignment`: construct custom
/// guides from an ``AlignmentID`` conforming type.
public struct HorizontalAlignment: Equatable, Sendable {
    /// The alignment guide's defining type.
    let id: any AlignmentID.Type

    /// Creates a custom horizontal alignment of the given identity.
    ///
    /// - Parameter id: The type defining the guide's default value.
    public init(_ id: any AlignmentID.Type) {
        self.id = id
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    /// Aligns to the leading (left) edge.
    public static let leading = Self(LeadingID.self)

    /// Aligns to the horizontal center.
    public static let center = Self(HorizontalCenterID.self)

    /// Aligns to the trailing (right) edge.
    public static let trailing = Self(TrailingID.self)

    private enum LeadingID: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { 0 }
    }

    private enum HorizontalCenterID: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context.width / 2 }
    }

    private enum TrailingID: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context.width }
    }
}

// MARK: - Vertical Alignment

/// An alignment position along the vertical axis.
///
/// Extensible like SwiftUI's `VerticalAlignment`: construct custom
/// guides from an ``AlignmentID`` conforming type.
public struct VerticalAlignment: Equatable, Sendable {
    /// The alignment guide's defining type.
    let id: any AlignmentID.Type

    /// Creates a custom vertical alignment of the given identity.
    ///
    /// - Parameter id: The type defining the guide's default value.
    public init(_ id: any AlignmentID.Type) {
        self.id = id
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    /// Aligns to the top edge.
    public static let top = Self(TopID.self)

    /// Aligns to the vertical center.
    public static let center = Self(VerticalCenterID.self)

    /// Aligns to the bottom edge.
    public static let bottom = Self(BottomID.self)

    private enum TopID: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { 0 }
    }

    private enum VerticalCenterID: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context.height / 2 }
    }

    private enum BottomID: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context.height }
    }
}

// MARK: - Cell Resolution

extension HorizontalAlignment {
    /// Returns the child's leading cell offset inside a container.
    ///
    /// Aligns the child's guide with the container's guide and quantizes
    /// with ``TerminalGeometry`` so macOS and Linux produce identical
    /// layouts. The result is clamped to keep the child inside the
    /// container.
    ///
    /// - Parameters:
    ///   - childWidth: The child's width in cells.
    ///   - containerWidth: The container's width in cells.
    /// - Returns: The leading offset in whole cells.
    package func cellOffset(childWidth: Int, containerWidth: Int) -> Int {
        let containerGuide = id.defaultValue(
            in: ViewDimensions(cellWidth: containerWidth, cellHeight: 0)
        )
        let childGuide = id.defaultValue(
            in: ViewDimensions(cellWidth: childWidth, cellHeight: 0)
        )
        let offset = TerminalGeometry.alignmentOffset(containerGuide - childGuide)
        return max(0, min(offset, containerWidth - childWidth))
    }
}

extension VerticalAlignment {
    /// Returns the child's top cell offset inside a container.
    ///
    /// See ``HorizontalAlignment/cellOffset(childWidth:containerWidth:)``
    /// for the resolution and quantization rules.
    ///
    /// - Parameters:
    ///   - childHeight: The child's height in cells.
    ///   - containerHeight: The container's height in cells.
    /// - Returns: The top offset in whole cells.
    package func cellOffset(childHeight: Int, containerHeight: Int) -> Int {
        let containerGuide = id.defaultValue(
            in: ViewDimensions(cellWidth: 0, cellHeight: containerHeight)
        )
        let childGuide = id.defaultValue(
            in: ViewDimensions(cellWidth: 0, cellHeight: childHeight)
        )
        let offset = TerminalGeometry.alignmentOffset(containerGuide - childGuide)
        return max(0, min(offset, containerHeight - childHeight))
    }
}

// MARK: - Combined Alignment

/// An alignment in both dimensions.
public struct Alignment: Sendable, Equatable {
    /// The horizontal component.
    public var horizontal: HorizontalAlignment

    /// The vertical component.
    public var vertical: VerticalAlignment

    /// Creates a combined alignment.
    ///
    /// - Parameters:
    ///   - horizontal: The horizontal alignment.
    ///   - vertical: The vertical alignment.
    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    // MARK: - Preset Alignments

    /// Top leading.
    public static let topLeading = Self(horizontal: .leading, vertical: .top)

    /// Top center.
    public static let top = Self(horizontal: .center, vertical: .top)

    /// Top trailing.
    public static let topTrailing = Self(horizontal: .trailing, vertical: .top)

    /// Center leading.
    public static let leading = Self(horizontal: .leading, vertical: .center)

    /// Center.
    public static let center = Self(horizontal: .center, vertical: .center)

    /// Center trailing.
    public static let trailing = Self(horizontal: .trailing, vertical: .center)

    /// Bottom leading.
    public static let bottomLeading = Self(horizontal: .leading, vertical: .bottom)

    /// Bottom center.
    public static let bottom = Self(horizontal: .center, vertical: .bottom)

    /// Bottom trailing.
    public static let bottomTrailing = Self(horizontal: .trailing, vertical: .bottom)
}
