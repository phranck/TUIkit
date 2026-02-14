//  🖥️ TUIKit — Terminal UI Kit for Swift
//  HStack.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - HStack

/// A view that arranges its children horizontally.
///
/// `HStack` arranges its child views side by side, from left to right.
///
/// # Example
///
/// ```swift
/// HStack {
///     Text("[OK]")
///     Text("[Cancel]")
/// }
/// ```
///
/// # Alignment
///
/// ```swift
/// HStack(alignment: .top) {
///     Text("Left")
///     Text("Right")
/// }
/// ```
public struct HStack<Content: View>: View {
    /// The vertical alignment of the children.
    public let alignment: VerticalAlignment

    /// The horizontal spacing between children.
    public let spacing: Int

    /// The content of the stack.
    public let content: Content

    /// Creates a horizontal stack with the specified options.
    ///
    /// - Parameters:
    ///   - alignment: The vertical alignment of children (default: .center).
    ///   - spacing: The spacing between children in characters (default: 1).
    ///   - content: A ViewBuilder that defines the children.
    public init(
        alignment: VerticalAlignment = .center,
        spacing: Int = 1,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        _HStackCore(alignment: alignment, spacing: spacing, content: content)
    }
}

// MARK: - Internal HStack Core

/// Internal view that handles the actual rendering of HStack.
private struct _HStackCore<Content: View>: View, Renderable, Layoutable {
    let alignment: VerticalAlignment
    let spacing: Int
    let content: Content

    var body: Never {
        fatalError("_HStackCore renders via Renderable")
    }

    /// Measures the HStack without rendering.
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        let children = resolveChildViews(from: content, context: context)
        guard !children.isEmpty else { return ViewSize.fixed(0, 0) }

        var totalWidth = 0
        var maxHeight = 0
        var hasFlexibleWidth = false

        for child in children {
            let size = child.measure(proposal: proposal, context: context)
            totalWidth += size.width
            maxHeight = max(maxHeight, size.height)
            if child.isSpacer || size.isWidthFlexible {
                hasFlexibleWidth = true
            }
        }

        let totalSpacing = max(0, children.count - 1) * spacing
        totalWidth += totalSpacing

        return ViewSize(
            width: totalWidth,
            height: maxHeight,
            isWidthFlexible: hasFlexibleWidth,
            isHeightFlexible: false
        )
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let children = resolveChildViews(from: content, context: context)
        guard !children.isEmpty else { return FrameBuffer() }

        // === PASS 1: Measure all children ===
        var childSizes: [ViewSize] = []
        var totalMinWidth = 0
        var flexibleCount = 0
        var maxHeight = 1

        for child in children {
            let size = child.measure(proposal: .unspecified, context: context)
            childSizes.append(size)

            if child.isSpacer || size.isWidthFlexible {
                flexibleCount += 1
                totalMinWidth += size.width  // minimum width for flexible views
            } else {
                totalMinWidth += size.width
            }
            maxHeight = max(maxHeight, size.height)
        }

        // Calculate spacing
        let totalSpacing = max(0, children.count - 1) * spacing

        // Calculate remaining space for flexible views
        let remainingWidth = max(0, context.availableWidth - totalMinWidth - totalSpacing)
        let flexibleWidth = flexibleCount > 0 ? remainingWidth / flexibleCount : 0
        let flexibleRemainder = flexibleCount > 0 ? remainingWidth % flexibleCount : 0

        // === PASS 2: Render with final sizes ===
        var result = FrameBuffer()
        var flexibleIndex = 0

        for (index, child) in children.enumerated() {
            let childSize = childSizes[index]
            let spacingToApply = index > 0 ? spacing : 0

            // Determine final width for this child
            let finalWidth: Int
            if child.isSpacer || childSize.isWidthFlexible {
                let extraWidth = flexibleIndex < flexibleRemainder ? 1 : 0
                finalWidth = max(child.spacerMinLength ?? childSize.width, childSize.width + flexibleWidth + extraWidth)
                flexibleIndex += 1
            } else {
                finalWidth = childSize.width
            }

            // Handle spacers specially (just empty space)
            if child.isSpacer {
                let spacerBuffer = FrameBuffer(emptyWithWidth: finalWidth, height: maxHeight)
                result.appendHorizontally(spacerBuffer, spacing: spacingToApply)
            } else {
                let buffer = child.render(width: finalWidth, height: context.availableHeight, context: context)
                result.appendHorizontally(buffer, spacing: spacingToApply)
            }
        }

        return result
    }
}

// MARK: - Equatable

extension HStack: @preconcurrency Equatable where Content: Equatable {
    public static func == (lhs: HStack<Content>, rhs: HStack<Content>) -> Bool {
        lhs.alignment == rhs.alignment &&
        lhs.spacing == rhs.spacing &&
        lhs.content == rhs.content
    }
}
