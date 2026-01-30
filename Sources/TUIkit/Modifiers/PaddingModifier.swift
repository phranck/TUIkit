//
//  PaddingModifier.swift
//  TUIkit
//
//  The .padding() modifier for adding space around a view.
//

/// Edge insets defining padding on each side.
public struct EdgeInsets: Sendable, Equatable {
    /// Padding above the content.
    public var top: Int

    /// Padding to the left of the content.
    public var leading: Int

    /// Padding below the content.
    public var bottom: Int

    /// Padding to the right of the content.
    public var trailing: Int

    /// Creates edge insets with individual values.
    public init(top: Int = 0, leading: Int = 0, bottom: Int = 0, trailing: Int = 0) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }

    /// Creates uniform edge insets.
    ///
    /// - Parameter value: The padding on all four sides.
    public init(all value: Int) {
        self.top = value
        self.leading = value
        self.bottom = value
        self.trailing = value
    }

    /// Creates horizontal and vertical edge insets.
    ///
    /// - Parameters:
    ///   - horizontal: The padding on leading and trailing sides.
    ///   - vertical: The padding on top and bottom sides.
    public init(horizontal: Int = 0, vertical: Int = 0) {
        self.top = vertical
        self.leading = horizontal
        self.bottom = vertical
        self.trailing = horizontal
    }
}

/// The edges of a view.
public struct Edge: OptionSet, Sendable {
    /// The raw bitmask value for this edge set.
    public let rawValue: UInt8

    /// Creates an edge set from a raw bitmask value.
    ///
    /// - Parameter rawValue: The bitmask value.
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    /// The top edge.
    public static let top = Self(rawValue: 1 << 0)

    /// The leading (left) edge.
    public static let leading = Self(rawValue: 1 << 1)

    /// The bottom edge.
    public static let bottom = Self(rawValue: 1 << 2)

    /// The trailing (right) edge.
    public static let trailing = Self(rawValue: 1 << 3)

    /// All edges.
    public static let all: Edge = [.top, .leading, .bottom, .trailing]

    /// Horizontal edges (leading and trailing).
    public static let horizontal: Edge = [.leading, .trailing]

    /// Vertical edges (top and bottom).
    public static let vertical: Edge = [.top, .bottom]
}

/// A modifier that adds padding around a view.
public struct PaddingModifier: ViewModifier {
    /// The padding insets.
    public let insets: EdgeInsets

    /// Creates a padding modifier.
    ///
    /// - Parameter insets: The padding insets.
    public init(insets: EdgeInsets) {
        self.insets = insets
    }

    public func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        var result: [String] = []

        let leadingPad = String(repeating: " ", count: insets.leading)
        let trailingPad = String(repeating: " ", count: insets.trailing)

        // Calculate line width
        let lineWidth = buffer.width + insets.leading + insets.trailing
        let emptyLine = String(repeating: " ", count: lineWidth)

        // Top padding (full lines)
        for _ in 0..<insets.top {
            result.append(emptyLine)
        }

        // Content lines with horizontal padding
        for line in buffer.lines {
            result.append(leadingPad + line + trailingPad)
        }

        // Bottom padding (full lines)
        for _ in 0..<insets.bottom {
            result.append(emptyLine)
        }

        return FrameBuffer(lines: result)
    }
}
