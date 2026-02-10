//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Stacks.swift
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
                let spacerBuffer = FrameBuffer(
                    lines: Array(
                        repeating: String(repeating: " ", count: finalWidth),
                        count: maxHeight
                    )
                )
                result.appendHorizontally(spacerBuffer, spacing: spacingToApply)
            } else {
                let buffer = child.render(width: finalWidth, height: context.availableHeight, context: context)
                result.appendHorizontally(buffer, spacing: spacingToApply)
            }
        }

        return result
    }
}

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
        let infos = resolveChildInfos(from: content, context: context)
        var result = FrameBuffer()
        for info in infos {
            if let buffer = info.buffer {
                result.overlay(buffer)
            }
        }
        return result
    }
}

// MARK: - Alignment Types

/// Horizontal alignment for VStack and similar containers.
public enum HorizontalAlignment: Sendable {
    /// Align to the leading (left) edge.
    case leading

    /// Align to the center.
    case center

    /// Align to the trailing (right) edge.
    case trailing
}

/// Vertical alignment for HStack and similar containers.
public enum VerticalAlignment: Sendable {
    /// Align to the top edge.
    case top

    /// Align to the vertical center.
    case center

    /// Align to the bottom edge.
    case bottom
}

/// Combined alignment for both axes.
public struct Alignment: Sendable, Equatable {
    /// The horizontal component.
    public let horizontal: HorizontalAlignment

    /// The vertical component.
    public let vertical: VerticalAlignment

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

// MARK: - Equatable Conformances

extension VStack: Equatable where Content: Equatable {
    nonisolated public static func == (lhs: VStack<Content>, rhs: VStack<Content>) -> Bool {
        MainActor.assumeIsolated {
            lhs.alignment == rhs.alignment &&
            lhs.spacing == rhs.spacing &&
            lhs.content == rhs.content
        }
    }
}

extension HStack: Equatable where Content: Equatable {
    nonisolated public static func == (lhs: HStack<Content>, rhs: HStack<Content>) -> Bool {
        MainActor.assumeIsolated {
            lhs.alignment == rhs.alignment &&
            lhs.spacing == rhs.spacing &&
            lhs.content == rhs.content
        }
    }
}

extension ZStack: Equatable where Content: Equatable {
    nonisolated public static func == (lhs: ZStack<Content>, rhs: ZStack<Content>) -> Bool {
        MainActor.assumeIsolated {
            lhs.alignment == rhs.alignment &&
            lhs.content == rhs.content
        }
    }
}
