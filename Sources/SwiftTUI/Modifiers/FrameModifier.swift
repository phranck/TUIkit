//
//  FrameModifier.swift
//  SwiftTUI
//
//  The .frame() modifier for setting explicit size constraints.
//

// MARK: - Frame Dimension

/// Represents a frame dimension that can be a fixed value or infinity.
public enum FrameDimension: Equatable, Sendable {
    /// A fixed size in characters/lines.
    case fixed(Int)

    /// Expand to fill all available space.
    case infinity

    /// The special infinity value for frame constraints.
    public static let max: FrameDimension = .infinity
}

// MARK: - Flexible Frame View

/// A view that applies flexible frame constraints to its content.
///
/// This view handles min/max constraints and renders content with
/// the appropriate available space.
public struct FlexibleFrameView<Content: View>: View {
    let content: Content
    let minWidth: Int?
    let idealWidth: Int?
    let maxWidth: FrameDimension?
    let minHeight: Int?
    let idealHeight: Int?
    let maxHeight: FrameDimension?
    let alignment: Alignment

    public var body: Never {
        fatalError("FlexibleFrameView renders via Renderable")
    }
}

extension FlexibleFrameView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Calculate the target width based on constraints
        let targetWidth: Int
        if let maxW = maxWidth {
            switch maxW {
            case .infinity:
                targetWidth = context.availableWidth
            case .fixed(let value):
                targetWidth = min(value, context.availableWidth)
            }
        } else if let ideal = idealWidth {
            targetWidth = min(ideal, context.availableWidth)
        } else {
            // No max constraint - render with available width, then size to content
            targetWidth = context.availableWidth
        }

        // Calculate the target height based on constraints
        let targetHeight: Int?
        if let maxH = maxHeight {
            switch maxH {
            case .infinity:
                targetHeight = context.availableHeight
            case .fixed(let value):
                targetHeight = min(value, context.availableHeight)
            }
        } else if let ideal = idealHeight {
            targetHeight = min(ideal, context.availableHeight)
        } else {
            targetHeight = nil  // Use intrinsic height
        }

        // Create context for content with constrained width
        var contentContext = context
        contentContext.availableWidth = targetWidth
        if let height = targetHeight {
            contentContext.availableHeight = height
        }

        // Render content
        let buffer = SwiftTUI.renderToBuffer(content, context: contentContext)

        // Apply minimum constraints
        var finalWidth = buffer.width
        var finalHeight = buffer.height

        if let minW = minWidth {
            finalWidth = max(finalWidth, minW)
        }
        if let minH = minHeight {
            finalHeight = max(finalHeight, minH)
        }

        // Apply maximum constraints (expand to fill if infinity)
        if let maxW = maxWidth, case .infinity = maxW {
            finalWidth = context.availableWidth
        }
        if let maxH = maxHeight, case .infinity = maxH {
            finalHeight = context.availableHeight
        }

        // If size matches buffer, return as-is
        if finalWidth == buffer.width && finalHeight == buffer.height {
            return buffer
        }

        // Otherwise, align content within the frame
        return alignBuffer(buffer, toWidth: finalWidth, height: finalHeight)
    }

    /// Aligns buffer content within the target frame size.
    private func alignBuffer(_ buffer: FrameBuffer, toWidth targetWidth: Int, height targetHeight: Int) -> FrameBuffer {
        var result: [String] = []

        // Calculate vertical offset for alignment
        let verticalOffset: Int
        switch alignment.vertical {
        case .top:
            verticalOffset = 0
        case .center:
            verticalOffset = max(0, (targetHeight - buffer.height) / 2)
        case .bottom:
            verticalOffset = max(0, targetHeight - buffer.height)
        }

        for row in 0..<targetHeight {
            let contentRow = row - verticalOffset
            let line: String
            if contentRow >= 0 && contentRow < buffer.lines.count {
                line = buffer.lines[contentRow]
            } else {
                line = ""
            }

            // Align horizontally within the frame
            let aligned = alignHorizontally(line, toWidth: targetWidth)
            result.append(aligned)
        }

        return FrameBuffer(lines: result)
    }

    /// Aligns a single line within the given width.
    private func alignHorizontally(_ line: String, toWidth targetWidth: Int) -> String {
        let visibleWidth = line.strippedLength

        if visibleWidth >= targetWidth {
            return line
        }

        let padding = targetWidth - visibleWidth

        switch alignment.horizontal {
        case .leading:
            return line + String(repeating: " ", count: padding)
        case .center:
            let left = padding / 2
            let right = padding - left
            return String(repeating: " ", count: left) + line + String(repeating: " ", count: right)
        case .trailing:
            return String(repeating: " ", count: padding) + line
        }
    }
}

// MARK: - Fixed Frame Modifier (Legacy)

/// A modifier that constrains a view to a specific width and/or height.
///
/// Content is aligned within the frame according to the specified alignment.
public struct FrameModifier: ViewModifier {
    /// The desired width (nil means intrinsic width).
    public let width: Int?

    /// The desired height (nil means intrinsic height).
    public let height: Int?

    /// The alignment of the content within the frame.
    public let alignment: Alignment

    public func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        let targetWidth = width ?? buffer.width
        let targetHeight = height ?? buffer.height

        var result: [String] = []

        // Calculate vertical offset for alignment
        let verticalOffset: Int
        switch alignment.vertical {
        case .top:
            verticalOffset = 0
        case .center:
            verticalOffset = max(0, (targetHeight - buffer.height) / 2)
        case .bottom:
            verticalOffset = max(0, targetHeight - buffer.height)
        }

        for row in 0..<targetHeight {
            let contentRow = row - verticalOffset
            let line: String
            if contentRow >= 0 && contentRow < buffer.lines.count {
                line = buffer.lines[contentRow]
            } else {
                line = ""
            }

            // Align horizontally within the frame
            let aligned = alignHorizontally(
                line,
                toWidth: targetWidth,
                alignment: alignment.horizontal
            )
            result.append(aligned)
        }

        return FrameBuffer(lines: result)
    }

    /// Aligns a single line within the given width.
    private func alignHorizontally(
        _ line: String,
        toWidth targetWidth: Int,
        alignment: HorizontalAlignment
    ) -> String {
        let visibleWidth = line.strippedLength

        if visibleWidth >= targetWidth {
            return line
        }

        let padding = targetWidth - visibleWidth

        switch alignment {
        case .leading:
            return line + String(repeating: " ", count: padding)
        case .center:
            let left = padding / 2
            let right = padding - left
            return String(repeating: " ", count: left) + line + String(repeating: " ", count: right)
        case .trailing:
            return String(repeating: " ", count: padding) + line
        }
    }
}

// MARK: - View Extension

extension View {
    /// Sets an explicit frame size for this view.
    ///
    /// The content is aligned within the frame according to the specified alignment.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Hello")
    ///     .frame(width: 20, alignment: .center)
    /// ```
    ///
    /// - Parameters:
    ///   - width: The desired width in characters (nil preserves intrinsic width).
    ///   - height: The desired height in lines (nil preserves intrinsic height).
    ///   - alignment: The alignment within the frame (default: .topLeading).
    /// - Returns: A view constrained to the specified frame.
    public func frame(
        width: Int? = nil,
        height: Int? = nil,
        alignment: Alignment = .topLeading
    ) -> ModifiedView<Self, FrameModifier> {
        modifier(FrameModifier(width: width, height: height, alignment: alignment))
    }

    /// Sets flexible frame constraints for this view.
    ///
    /// Use `.infinity` for maxWidth/maxHeight to expand to fill available space.
    ///
    /// # Examples
    ///
    /// ```swift
    /// // Expand to full width
    /// Text("Hello")
    ///     .frame(maxWidth: .infinity)
    ///
    /// // Expand to full size
    /// Color.blue
    ///     .frame(maxWidth: .infinity, maxHeight: .infinity)
    ///
    /// // Minimum size with expansion
    /// Text("Button")
    ///     .frame(minWidth: 10, maxWidth: .infinity)
    /// ```
    ///
    /// - Parameters:
    ///   - minWidth: Minimum width in characters.
    ///   - idealWidth: Preferred width (used when no max is set).
    ///   - maxWidth: Maximum width, or `.infinity` to fill available space.
    ///   - minHeight: Minimum height in lines.
    ///   - idealHeight: Preferred height (used when no max is set).
    ///   - maxHeight: Maximum height, or `.infinity` to fill available space.
    ///   - alignment: The alignment within the frame (default: .center).
    /// - Returns: A view with flexible frame constraints.
    public func frame(
        minWidth: Int? = nil,
        idealWidth: Int? = nil,
        maxWidth: FrameDimension? = nil,
        minHeight: Int? = nil,
        idealHeight: Int? = nil,
        maxHeight: FrameDimension? = nil,
        alignment: Alignment = .center
    ) -> some View {
        FlexibleFrameView(
            content: self,
            minWidth: minWidth,
            idealWidth: idealWidth,
            maxWidth: maxWidth,
            minHeight: minHeight,
            idealHeight: idealHeight,
            maxHeight: maxHeight,
            alignment: alignment
        )
    }
}
