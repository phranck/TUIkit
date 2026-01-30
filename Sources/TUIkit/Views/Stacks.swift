//
//  Stacks.swift
//  TUIkit
//
//  Layout containers for vertical and horizontal arrangement.
//

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
    ///   - alignment: The horizontal alignment of children (default: .leading).
    ///   - spacing: The spacing between children in lines (default: 0).
    ///   - content: A ViewBuilder that defines the children.
    public init(
        alignment: HorizontalAlignment = .leading,
        spacing: Int = 0,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never {
        fatalError("VStack is a primitive container and renders its children directly")
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

    public var body: Never {
        fatalError("HStack is a primitive container and renders its children directly")
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

    public var body: Never {
        fatalError("ZStack is a primitive container and renders its children directly")
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
public struct Alignment: Sendable {
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

// MARK: - VStack Rendering

extension VStack: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let infos = resolveChildInfos(from: content, context: context)

        // Spacer distribution: divide remaining vertical space equally
        // among all spacers after subtracting fixed children and inter-item spacing.
        let spacerCount = infos.filter(\.isSpacer).count
        let fixedHeight = infos.compactMap(\.buffer).reduce(0) { $0 + $1.height }
        let totalSpacing = max(0, infos.count - 1) * spacing

        let availableForSpacers = max(0, context.availableHeight - fixedHeight - totalSpacing)
        let spacerHeight = spacerCount > 0 ? availableForSpacers / spacerCount : 0

        // Max width across all children determines alignment reference
        let maxWidth = infos.compactMap(\.buffer).map(\.width).max() ?? 0

        var result = FrameBuffer()
        for (index, info) in infos.enumerated() {
            let spacingToApply = index > 0 ? spacing : 0
            if info.isSpacer {
                let height = max(info.spacerMinLength ?? 0, spacerHeight)
                result.appendVertically(FrameBuffer(emptyWithHeight: height), spacing: spacingToApply)
            } else if let buffer = info.buffer {
                let alignedBuffer = alignBuffer(buffer, toWidth: maxWidth, alignment: alignment)
                result.appendVertically(alignedBuffer, spacing: spacingToApply)
            }
        }
        return result
    }

    /// Aligns a buffer horizontally within the given width.
    private func alignBuffer(_ buffer: FrameBuffer, toWidth width: Int, alignment: HorizontalAlignment) -> FrameBuffer {
        guard buffer.width < width else { return buffer }

        var alignedLines: [String] = []

        for line in buffer.lines {
            let lineWidth = line.strippedLength
            let linePadding = width - lineWidth

            switch alignment {
            case .leading:
                // Pad on right
                alignedLines.append(line + String(repeating: " ", count: linePadding))
            case .center:
                // Pad on both sides
                let leftPad = linePadding / 2
                let rightPad = linePadding - leftPad
                alignedLines.append(String(repeating: " ", count: leftPad) + line + String(repeating: " ", count: rightPad))
            case .trailing:
                // Pad on left
                alignedLines.append(String(repeating: " ", count: linePadding) + line)
            }
        }

        return FrameBuffer(lines: alignedLines)
    }
}

// MARK: - HStack Rendering

extension HStack: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let infos = resolveChildInfos(from: content, context: context)

        // Spacer distribution: divide remaining horizontal space equally
        // among all spacers after subtracting fixed children and inter-item spacing.
        let spacerCount = infos.filter(\.isSpacer).count
        let fixedWidth = infos.compactMap(\.buffer).reduce(0) { $0 + $1.width }
        let totalSpacing = max(0, infos.count - 1) * spacing

        let availableForSpacers = max(0, context.availableWidth - fixedWidth - totalSpacing)
        let spacerWidth = spacerCount > 0 ? availableForSpacers / spacerCount : 0

        var result = FrameBuffer()
        for (index, info) in infos.enumerated() {
            let spacingToApply = index > 0 ? spacing : 0
            if info.isSpacer {
                let width = max(info.spacerMinLength ?? 0, spacerWidth)
                let maxHeight = infos.compactMap(\.buffer).map(\.height).max() ?? 1
                let spacerBuffer = FrameBuffer(
                    lines: Array(
                        repeating: String(repeating: " ", count: width),
                        count: maxHeight
                    )
                )
                result.appendHorizontally(spacerBuffer, spacing: spacingToApply)
            } else if let buffer = info.buffer {
                result.appendHorizontally(buffer, spacing: spacingToApply)
            }
        }
        return result
    }
}

// MARK: - ZStack Rendering

extension ZStack: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
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
