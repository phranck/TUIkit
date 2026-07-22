//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ZStack.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - ZStack

/// A view that stacks its children on top of each other (z-axis).
///
/// `ZStack` layers views on top of each other, with later views
/// appearing above earlier ones.
///
/// # Example
///
/// ```swift
/// ZStack {
///     Text("████████████████")
///     Text("    Overlay     ")
/// }
/// ```
public struct ZStack<Content: View>: View {
    /// The alignment of the children.
    public let alignment: Alignment

    /// The content of the stack.
    public let content: Content

    /// Creates a z-stack with the specified options.
    ///
    /// - Parameters:
    ///   - alignment: The alignment of children (default: .center).
    ///   - content: A ViewBuilder that defines the children.
    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    public var body: some View {
        _ZStackCore(alignment: alignment, content: content)
    }
}

// MARK: - Internal ZStack Core

/// Internal view that handles the actual rendering of ZStack.
private struct _ZStackCore<Content: View>: View, Renderable {
    let alignment: Alignment
    let content: Content

    var body: Never {
        fatalError("_ZStackCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let buffers = resolveChildInfos(from: content, context: context).compactMap(\.buffer)
        guard !buffers.isEmpty else { return FrameBuffer() }

        let width = buffers.map(\.width).max() ?? 0
        let height = buffers.map(\.height).max() ?? 0
        var result = FrameBuffer(lines: Array(repeating: "", count: height), width: width)

        for buffer in buffers where !buffer.isEmpty {
            let horizontalOffset = offset(
                available: width,
                content: buffer.width,
                alignment: alignment.horizontal
            )
            let verticalOffset = offset(
                available: height,
                content: buffer.height,
                alignment: alignment.vertical
            )
            result = result.composited(
                with: buffer,
                at: (x: horizontalOffset, y: verticalOffset)
            )
        }
        return result
    }

    private func offset(
        available: Int,
        content: Int,
        alignment: HorizontalAlignment
    ) -> Int {
        alignment.cellOffset(childWidth: content, containerWidth: available)
    }

    private func offset(
        available: Int,
        content: Int,
        alignment: VerticalAlignment
    ) -> Int {
        alignment.cellOffset(childHeight: content, containerHeight: available)
    }
}

// MARK: - Equatable

extension ZStack: @preconcurrency Equatable where Content: Equatable {
    public static func == (lhs: ZStack<Content>, rhs: ZStack<Content>) -> Bool {
        lhs.alignment == rhs.alignment &&
        lhs.content == rhs.content
    }
}
