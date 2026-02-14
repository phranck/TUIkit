//  🖥️ TUIKit — Terminal UI Kit for Swift
//  VStack.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - VStack

/// A view that arranges its children vertically.
///
/// `VStack` stacks its child views on top of each other, from top to bottom.
/// This corresponds to the default behavior in a terminal.
///
/// # Example
///
/// ```swift
/// VStack {
///     Text("Line 1")
///     Text("Line 2")
///     Text("Line 3")
/// }
/// ```
///
/// # Alignment
///
/// ```swift
/// VStack(alignment: .center) {
///     Text("Short")
///     Text("Longer text")
/// }
/// ```
public struct VStack<Content: View>: View {
    /// The horizontal alignment of the children.
    public let alignment: HorizontalAlignment

    /// The vertical spacing between children.
    public let spacing: Int

    /// The content of the stack.
    public let content: Content

    /// Creates a vertical stack with the specified options.
    ///
    /// - Parameters:
    ///   - alignment: The horizontal alignment of children (default: .center, like SwiftUI).
    ///   - spacing: The spacing between children in lines (default: 0).
    ///   - content: A ViewBuilder that defines the children.
    public init(
        alignment: HorizontalAlignment = .center,
        spacing: Int = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        _VStackCore(alignment: alignment, spacing: spacing, content: content)
    }
}

// MARK: - Internal VStack Core

/// Internal view that handles the actual rendering of VStack.
private struct _VStackCore<Content: View>: View, Renderable, Layoutable {
    let alignment: HorizontalAlignment
    let spacing: Int
    let content: Content

    var body: Never {
        fatalError("_VStackCore renders via Renderable")
    }

    /// Measures the VStack without rendering.
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        let children = resolveChildViews(from: content, context: context)
        guard !children.isEmpty else { return ViewSize.fixed(0, 0) }

        var totalHeight = 0
        var maxWidth = 0
        var hasFlexibleHeight = false

        for child in children {
            let size = child.measure(proposal: proposal, context: context)
            totalHeight += size.height
            maxWidth = max(maxWidth, size.width)
            if child.isSpacer || size.isHeightFlexible {
                hasFlexibleHeight = true
            }
        }

        let totalSpacing = max(0, children.count - 1) * spacing
        totalHeight += totalSpacing

        return ViewSize(
            width: maxWidth,
            height: totalHeight,
            isWidthFlexible: false,
            isHeightFlexible: hasFlexibleHeight
        )
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let children = resolveChildViews(from: content, context: context)
        guard !children.isEmpty else { return FrameBuffer() }

        // === PASS 1: Measure all children ===
        var childSizes: [ViewSize] = []
        var totalMinHeight = 0
        var flexibleCount = 0
        var maxWidth = 0

        for child in children {
            let size = child.measure(proposal: .unspecified, context: context)
            childSizes.append(size)

            if child.isSpacer || size.isHeightFlexible {
                flexibleCount += 1
                totalMinHeight += size.height  // minimum height for flexible views
            } else {
                totalMinHeight += size.height
            }
            maxWidth = max(maxWidth, size.width)
        }

        // Calculate spacing
        let totalSpacing = max(0, children.count - 1) * spacing

        // Calculate remaining space for flexible views
        let remainingHeight = max(0, context.availableHeight - totalMinHeight - totalSpacing)
        let flexibleHeight = flexibleCount > 0 ? remainingHeight / flexibleCount : 0
        let flexibleRemainder = flexibleCount > 0 ? remainingHeight % flexibleCount : 0

        // Use available width for alignment when spacers are present
        let alignmentWidth = flexibleCount > 0 ? context.availableWidth : maxWidth

        // === PASS 2: Render with final sizes ===
        var result = FrameBuffer()
        var flexibleIndex = 0

        for (index, child) in children.enumerated() {
            let childSize = childSizes[index]
            let spacingToApply = index > 0 ? spacing : 0

            // Determine final height for this child
            let finalHeight: Int
            if child.isSpacer || childSize.isHeightFlexible {
                let extraHeight = flexibleIndex < flexibleRemainder ? 1 : 0
                finalHeight = max(child.spacerMinLength ?? childSize.height, childSize.height + flexibleHeight + extraHeight)
                flexibleIndex += 1
            } else {
                finalHeight = childSize.height
            }

            // Handle spacers specially (just empty space)
            if child.isSpacer {
                result.appendVertically(FrameBuffer(emptyWithHeight: finalHeight), spacing: spacingToApply)
            } else {
                let buffer = child.render(width: context.availableWidth, height: finalHeight, context: context)
                let alignedBuffer = alignBuffer(buffer, toWidth: alignmentWidth, alignment: alignment)
                result.appendVertically(alignedBuffer, spacing: spacingToApply)
            }
        }

        return result
    }

    /// Aligns a buffer horizontally within the given width.
    private func alignBuffer(_ buffer: FrameBuffer, toWidth width: Int, alignment: HorizontalAlignment) -> FrameBuffer {
        guard buffer.width < width else { return buffer }

        var alignedLines: [String] = []

        let bufferOffset: Int
        switch alignment {
        case .leading:
            bufferOffset = 0
        case .center:
            bufferOffset = (width - buffer.width) / 2
        case .trailing:
            bufferOffset = width - buffer.width
        }

        let leftPadding = String(repeating: " ", count: bufferOffset)
        let rightPaddingCount = width - bufferOffset - buffer.width

        for line in buffer.lines {
            let lineWidth = line.strippedLength
            let paddedLine = line + String(repeating: " ", count: max(0, buffer.width - lineWidth))
            alignedLines.append(leftPadding + paddedLine + String(repeating: " ", count: max(0, rightPaddingCount)))
        }

        return FrameBuffer(lines: alignedLines)
    }
}

// MARK: - Equatable

extension VStack: @preconcurrency Equatable where Content: Equatable {
    public static func == (lhs: VStack<Content>, rhs: VStack<Content>) -> Bool {
        lhs.alignment == rhs.alignment &&
        lhs.spacing == rhs.spacing &&
        lhs.content == rhs.content
    }
}
