//  🖥️ TUIKit — Terminal UI Kit for Swift
//  GeometryReader.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Axis

/// The horizontal or vertical dimension in a 2D coordinate system.
public enum Axis: Int8, CaseIterable, Sendable {
    /// The horizontal dimension.
    case horizontal

    /// The vertical dimension.
    case vertical

    /// An efficient set of axes.
    public struct Set: OptionSet, Sendable {
        /// The raw bitmask value for this axis set.
        public let rawValue: Int8

        /// Creates an axis set from a raw bitmask value.
        ///
        /// - Parameter rawValue: The bitmask value.
        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }

        /// The horizontal axis.
        public static let horizontal = Self(rawValue: 1 << 0)

        /// The vertical axis.
        public static let vertical = Self(rawValue: 1 << 1)
    }
}

// MARK: - Geometry Proxy

/// A proxy for access to the size of the container view.
///
/// Terminal adaptation of SwiftUI's `GeometryProxy`: the size reports
/// whole cells as `CGFloat`. Coordinate-space anchors and safe-area
/// insets have no terminal meaning and are omitted per the
/// compatibility manifest.
public struct GeometryProxy: Sendable {
    /// The size of the container view in cells.
    public let size: CGSize

    /// Creates a proxy for the given cell dimensions.
    init(cellWidth: Int, cellHeight: Int) {
        self.size = CGSize(width: CGFloat(cellWidth), height: CGFloat(cellHeight))
    }
}

// MARK: - Geometry Reader

/// A container view that defines its content as a function of its own
/// size.
///
/// Like SwiftUI, the reader expands to fill all of its proposed space
/// and aligns content to the top-leading corner:
///
/// ```swift
/// GeometryReader { proxy in
///     Text("width: \(Int(proxy.size.width))")
/// }
/// ```
public struct GeometryReader<Content: View>: View {
    /// Produces the content for the resolved size.
    public var content: (GeometryProxy) -> Content

    /// Creates a geometry reader with the given view builder.
    ///
    /// - Parameter content: A builder receiving the container's geometry.
    public init(@ViewBuilder content: @escaping (GeometryProxy) -> Content) {
        self.content = content
    }

    /// Never called — rendering is handled by `Renderable` conformance.
    public var body: Never {
        fatalError("GeometryReader renders via Renderable")
    }
}

// MARK: - Rendering

extension GeometryReader: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let proxy = GeometryProxy(
            cellWidth: context.availableWidth,
            cellHeight: context.availableHeight
        )
        let resolved = content(proxy)
        let buffer = TUIkit.renderToBuffer(
            resolved,
            context: context.withChildIdentity(type: Content.self)
        )

        // Expand to the full proposed space with top-leading content,
        // matching SwiftUI's geometry reader behavior.
        var lines = buffer.lines
        let width = max(buffer.width, context.availableWidth)
        while lines.count < context.availableHeight {
            lines.append("")
        }
        return FrameBuffer(lines: lines, width: width)
    }
}
