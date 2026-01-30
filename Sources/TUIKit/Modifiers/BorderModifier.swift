//
//  BorderModifier.swift
//  TUIKit
//
//  The .border() modifier for adding borders around views.
//

/// A view that wraps content with a border.
///
/// This modifier reduces the available width for content by 2 characters
/// (for the left and right border) to ensure the total width stays within bounds.
public struct BorderedView<Content: View>: View {
    /// The content to wrap with a border.
    let content: Content

    /// The border style to use (nil uses appearance default).
    let style: BorderStyle?

    /// The color of the border (nil uses theme border color).
    let color: Color?

    public var body: Never {
        fatalError("BorderedView renders via Renderable")
    }
}

// MARK: - Renderable

extension BorderedView: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Resolve border style - use explicit or fall back to appearance default
        let effectiveStyle = style ?? context.environment.appearance.borderStyle
        let isBlockAppearance = context.environment.appearance.id == .block
        
        // Reduce available width for content by 2 (left + right border)
        var contentContext = context
        contentContext.availableWidth = max(1, context.availableWidth - 2)

        // Render content with reduced width
        let buffer = TUIKit.renderToBuffer(content, context: contentContext)

        guard !buffer.isEmpty else { return buffer }

        let contentWidth = buffer.width
        let innerWidth = max(contentWidth, 1)
        
        if isBlockAppearance {
            return renderBlockStyle(buffer: buffer, innerWidth: innerWidth)
        } else {
            return renderStandardStyle(buffer: buffer, innerWidth: innerWidth, style: effectiveStyle)
        }
    }
    
    /// Renders with standard box-drawing characters.
    private func renderStandardStyle(buffer: FrameBuffer, innerWidth: Int, style: BorderStyle) -> FrameBuffer {
        let borderColor = color ?? Color.theme.border
        var lines: [String] = []

        lines.append(BorderRenderer.standardTopBorder(style: style, innerWidth: innerWidth, color: borderColor))
        for line in buffer.lines {
            lines.append(BorderRenderer.standardContentLine(
                content: line, innerWidth: innerWidth, style: style, color: borderColor
            ))
        }
        lines.append(BorderRenderer.standardBottomBorder(style: style, innerWidth: innerWidth, color: borderColor))

        return FrameBuffer(lines: lines)
    }
    
    /// Renders with half-block characters for block appearance.
    private func renderBlockStyle(buffer: FrameBuffer, innerWidth: Int) -> FrameBuffer {
        let containerBg = Color.theme.containerBackground
        var lines: [String] = []

        lines.append(BorderRenderer.blockTopBorder(innerWidth: innerWidth, color: containerBg))
        for line in buffer.lines {
            lines.append(BorderRenderer.blockContentLine(content: line, innerWidth: innerWidth, sectionColor: containerBg))
        }
        lines.append(BorderRenderer.blockBottomBorder(innerWidth: innerWidth, color: containerBg))

        return FrameBuffer(lines: lines)
    }
}

