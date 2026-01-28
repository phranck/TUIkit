//
//  DimmedModifier.swift
//  SwiftTUI
//
//  A modifier that applies a dimming effect to the entire view content.
//

/// A modifier that applies the ANSI dim effect to the entire content.
///
/// This is useful for de-emphasizing background content when showing
/// overlays, alerts, or dialogs.
public struct DimmedModifier<Content: TView>: TView {
    /// The content to dim.
    let content: Content

    public var body: Never {
        fatalError("DimmedModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension DimmedModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let contentBuffer = SwiftTUI.renderToBuffer(content, context: context)

        guard !contentBuffer.isEmpty else {
            return contentBuffer
        }

        // Apply dim effect to each line
        let dimmedLines = contentBuffer.lines.map { line -> String in
            applyDim(to: line)
        }

        return FrameBuffer(lines: dimmedLines)
    }

    /// Applies the ANSI dim effect to a string.
    ///
    /// If the string already contains ANSI codes, this wraps the entire line.
    /// The dim code (ESC[2m) reduces the intensity of the text.
    ///
    /// - Parameter text: The text to dim.
    /// - Returns: The dimmed text with ANSI codes.
    private func applyDim(to text: String) -> String {
        guard !text.isEmpty else { return text }

        // ANSI dim code
        let dimCode = "\u{1B}[2m"
        let resetCode = "\u{1B}[0m"

        // If the line is empty (just spaces), keep it as is
        if text.stripped.trimmingCharacters(in: .whitespaces).isEmpty {
            return text
        }

        // Wrap the entire line in dim codes
        // Note: This adds dim at the start and reset at the end
        // Any existing styles will still work, but will be dimmed
        return dimCode + text + resetCode
    }
}

// MARK: - TView Extension

extension TView {
    /// Applies a dimming effect to the view content.
    ///
    /// This reduces the visual intensity of the content using the ANSI dim
    /// escape code. Useful for background content when displaying overlays.
    ///
    /// # Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("This content will be dimmed")
    ///     Text("All text is affected")
    /// }
    /// .dimmed()
    /// ```
    ///
    /// - Returns: A view with the dimming effect applied.
    public func dimmed() -> some TView {
        DimmedModifier(content: self)
    }
}
