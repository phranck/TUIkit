//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

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
    /// The content view to constrain.
    let content: Content

    /// The minimum width in characters, or nil for no minimum.
    let minWidth: Int?

    /// The ideal width in characters, or nil to use intrinsic size.
    let idealWidth: Int?

    /// The maximum width constraint, or nil for no maximum.
    let maxWidth: FrameDimension?

    /// The minimum height in lines, or nil for no minimum.
    let minHeight: Int?

    /// The ideal height in lines, or nil to use intrinsic size.
    let idealHeight: Int?

    /// The maximum height constraint, or nil for no maximum.
    let maxHeight: FrameDimension?

    /// The alignment of the content within the frame.
    let alignment: Alignment

    public var body: Never {
        fatalError("FlexibleFrameView renders via Renderable")
    }
}

// MARK: - Equatable Conformance

extension FlexibleFrameView: @preconcurrency Equatable where Content: Equatable {
    public static func == (lhs: FlexibleFrameView<Content>, rhs: FlexibleFrameView<Content>) -> Bool {
        lhs.content == rhs.content &&
        lhs.minWidth == rhs.minWidth &&
        lhs.idealWidth == rhs.idealWidth &&
        lhs.maxWidth == rhs.maxWidth &&
        lhs.minHeight == rhs.minHeight &&
        lhs.idealHeight == rhs.idealHeight &&
        lhs.maxHeight == rhs.maxHeight &&
        lhs.alignment == rhs.alignment
    }
}

// MARK: - Renderable

extension FlexibleFrameView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
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
        
        // Mark that an explicit width constraint was set
        if minWidth != nil || idealWidth != nil || maxWidth != nil {
            contentContext.hasExplicitWidth = true
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
            if contentRow >= 0 && contentRow < buffer.height {
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
