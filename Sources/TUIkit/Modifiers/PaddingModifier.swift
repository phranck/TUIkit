//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PaddingModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

/// The inset distances for the sides of a rectangle.
///
/// Matches SwiftUI's `CGFloat`-based shape; the renderer quantizes each
/// side to whole cells through ``TerminalGeometry`` (negative values
/// degrade to zero).
public struct EdgeInsets: Sendable, Equatable {
    /// Padding above the content.
    public var top: CGFloat

    /// Padding to the left of the content.
    public var leading: CGFloat

    /// Padding below the content.
    public var bottom: CGFloat

    /// Padding to the right of the content.
    public var trailing: CGFloat

    /// Creates edge insets with individual values.
    public init(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    /// Creates uniform edge insets.
    ///
    /// Additive terminal convenience.
    ///
    /// - Parameter value: The padding on all four sides.
    public init(all value: CGFloat) {
        self.init(top: value, leading: value, bottom: value, trailing: value)
    }

    /// Creates horizontal and vertical edge insets.
    ///
    /// Additive terminal convenience.
    ///
    /// - Parameters:
    ///   - horizontal: The padding on leading and trailing sides.
    ///   - vertical: The padding on top and bottom sides.
    public init(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
        self.init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    /// The insets quantized to whole, non-negative cells.
    package var cellInsets: (top: Int, leading: Int, bottom: Int, trailing: Int) {
        (
            top: max(0, TerminalGeometry.cells(top)),
            leading: max(0, TerminalGeometry.cells(leading)),
            bottom: max(0, TerminalGeometry.cells(bottom)),
            trailing: max(0, TerminalGeometry.cells(trailing))
        )
    }
}

/// An enumeration to indicate one edge of a rectangle.
public enum Edge: Int8, CaseIterable, Sendable {
    /// The top edge.
    case top

    /// The leading (left) edge.
    case leading

    /// The bottom edge.
    case bottom

    /// The trailing (right) edge.
    case trailing

    /// An efficient set of edges.
    public struct Set: OptionSet, Sendable {
        /// The raw bitmask value for this edge set.
        public let rawValue: Int8

        /// Creates an edge set from a raw bitmask value.
        ///
        /// - Parameter rawValue: The bitmask value.
        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }

        /// Creates a set containing only the given edge.
        ///
        // swiftlint:disable identifier_name
        /// The parameter name matches SwiftUI's exact signature.
        ///
        /// - Parameter e: The edge to contain.
        public init(_ e: Edge) {
            self.init(rawValue: 1 << e.rawValue)
        }
        // swiftlint:enable identifier_name

        /// The top edge.
        public static let top = Self(.top)

        /// The leading (left) edge.
        public static let leading = Self(.leading)

        /// The bottom edge.
        public static let bottom = Self(.bottom)

        /// The trailing (right) edge.
        public static let trailing = Self(.trailing)

        /// All edges.
        public static let all: Self = [.top, .leading, .bottom, .trailing]

        /// Horizontal edges (leading and trailing).
        public static let horizontal: Self = [.leading, .trailing]

        /// Vertical edges (top and bottom).
        public static let vertical: Self = [.top, .bottom]

        /// Whether the set contains the given edge.
        ///
        /// - Parameter edge: The edge to test.
        public func contains(_ edge: Edge) -> Bool {
            contains(Self(edge))
        }
    }
}

/// A modifier that adds padding around a view.
///
/// Framework infrastructure behind `.padding()`; operates on rendered
/// buffers through the internal buffer-modifier layer.
struct PaddingModifier: BufferViewModifier {
    /// The padding insets.
    let insets: EdgeInsets

    func adjustContext(_ context: RenderContext) -> RenderContext {
        let cells = insets.cellInsets
        var adjusted = context
        adjusted.availableWidth = max(0, context.availableWidth - cells.leading - cells.trailing)
        adjusted.availableHeight = max(0, context.availableHeight - cells.top - cells.bottom)
        return adjusted
    }

    func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        let cells = insets.cellInsets
        var result: [String] = []

        let leadingPad = String(repeating: " ", count: cells.leading)
        let trailingPad = String(repeating: " ", count: cells.trailing)

        // Calculate line width
        let lineWidth = buffer.width + cells.leading + cells.trailing
        let emptyLine = String(repeating: " ", count: lineWidth)

        // Top padding (full lines)
        for _ in 0..<cells.top {
            result.append(emptyLine)
        }

        // Content lines with horizontal padding
        for line in buffer.lines {
            result.append(leadingPad + line + trailingPad)
        }

        // Bottom padding (full lines)
        for _ in 0..<cells.bottom {
            result.append(emptyLine)
        }

        return FrameBuffer(lines: result)
    }
}
