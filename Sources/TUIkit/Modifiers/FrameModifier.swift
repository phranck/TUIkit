//
//  FrameModifier.swift
//  TUIkit
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
        if let maximumWidth = maxWidth {
            switch maximumWidth {
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
        if let maximumHeight = maxHeight {
            switch maximumHeight {
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
        let buffer = TUIkit.renderToBuffer(content, context: contentContext)

        // Apply minimum constraints
        var finalWidth = buffer.width
        var finalHeight = buffer.height

        if let minimumWidth = minWidth {
            finalWidth = max(finalWidth, minimumWidth)
        }
        if let minimumHeight = minHeight {
            finalHeight = max(finalHeight, minimumHeight)
        }

        // Apply maximum constraints (expand to fill if infinity)
        if let maximumWidth = maxWidth, case .infinity = maximumWidth {
            finalWidth = context.availableWidth
        }
        if let maximumHeight = maxHeight, case .infinity = maximumHeight {
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
