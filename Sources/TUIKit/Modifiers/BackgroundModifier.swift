//
//  BackgroundModifier.swift
//  TUIKit
//
//  The .background() modifier for adding background colors to views.
//

/// A modifier that fills the background of a view with a color.
public struct BackgroundModifier: ViewModifier {
    /// The background color.
    public let color: Color

    public func modify(buffer: FrameBuffer, context: RenderContext) -> FrameBuffer {
        guard !buffer.isEmpty else { return buffer }

        let width = buffer.width
        var lines: [String] = []

        for line in buffer.lines {
            // Pad the line to full width so background covers everything
            let paddedLine = line.padToVisibleWidth(width)

            // Apply background color to the entire line
            var style = TextStyle()
            style.backgroundColor = color

            // We need to handle existing ANSI codes in the line
            // For simplicity, we wrap the whole line with background
            let colored = applyBackground(to: paddedLine, color: color)
            lines.append(colored)
        }

        return FrameBuffer(lines: lines)
    }

    /// Applies background color to a string, preserving existing formatting.
    private func applyBackground(to string: String, color: Color) -> String {
        ANSIRenderer.backgroundCode(for: color) + string + ANSIRenderer.reset
    }
}
