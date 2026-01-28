//
//  BackgroundModifier.swift
//  SwiftTUI
//
//  The .background() modifier for adding background colors to views.
//

/// A modifier that fills the background of a view with a color.
public struct BackgroundModifier: TViewModifier {
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
        // Build the background escape sequence
        let bgCodes: [String]
        switch color.value {
        case .standard(let ansi):
            bgCodes = ["\(ansi.backgroundCode)"]
        case .bright(let ansi):
            bgCodes = ["\(ansi.brightBackgroundCode)"]
        case .palette256(let index):
            bgCodes = ["48", "5", "\(index)"]
        case .rgb(let red, let green, let blue):
            bgCodes = ["48", "2", "\(red)", "\(green)", "\(blue)"]
        }

        let bgStart = "\u{1B}[\(bgCodes.joined(separator: ";"))m"
        let reset = ANSIRenderer.reset

        return bgStart + string + reset
    }
}

// MARK: - TView Extension

extension TView {
    /// Adds a background color to this view.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Warning!")
    ///     .foregroundColor(.black)
    ///     .background(.yellow)
    ///
    /// VStack {
    ///     Text("Header")
    /// }
    /// .background(.blue)
    /// ```
    ///
    /// - Parameter color: The background color.
    /// - Returns: A view with the background color applied.
    public func background(_ color: Color) -> ModifiedView<Self, BackgroundModifier> {
        modifier(BackgroundModifier(color: color))
    }
}
