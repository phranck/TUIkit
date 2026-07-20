//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Text.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A view that displays text in the terminal.
///
/// `Text` is one of the most fundamental views in TUIkit. It displays
/// a string in the terminal and supports various formatting options.
///
/// # Example
///
/// ```swift
/// Text("Hello, World!")
///
/// Text("Bold")
///     .bold()
///
/// Text("Colored")
///     .foregroundStyle(.red)
/// ```
public struct Text: View, Equatable {
    /// The text to display.
    let content: String

    /// The style of the text (color, formatting, etc.).
    var style: TextStyle

    /// Creates a text view with the specified string.
    ///
    /// - Parameter content: The text to display.
    public init(_ content: String) {
        self.content = content
        self.style = TextStyle()
    }

    /// Creates a text view with a verbatim string.
    ///
    /// - Parameter verbatim: The text to display verbatim.
    public init(verbatim: String) {
        self.content = verbatim
        self.style = TextStyle()
    }

    public var body: Never {
        fatalError("Text is a primitive view and renders directly")
    }
}

// MARK: - Text Modifiers

extension Text {
    /// Sets the text foreground style.
    ///
    /// - Parameter style: The desired foreground color.
    /// - Returns: A new text with the applied style.
    public func foregroundStyle(_ style: Color) -> Text {
        var copy = self
        copy.style.foregroundColor = style
        return copy
    }

    /// Sets the background color.
    ///
    /// - Parameter color: The desired background color.
    /// - Returns: A new text with the applied background color.
    public func backgroundColor(_ color: Color) -> Text {
        var copy = self
        copy.style.backgroundColor = color
        return copy
    }

    /// Makes the text bold.
    ///
    /// - Returns: A new text with bold formatting.
    public func bold() -> Text {
        var copy = self
        copy.style.isBold = true
        return copy
    }

    /// Makes the text italic.
    ///
    /// - Returns: A new text with italic formatting.
    public func italic() -> Text {
        var copy = self
        copy.style.isItalic = true
        return copy
    }

    /// Underlines the text.
    ///
    /// - Returns: A new text with underline formatting.
    public func underline() -> Text {
        var copy = self
        copy.style.isUnderlined = true
        return copy
    }

    /// Strikes through the text.
    ///
    /// - Returns: A new text with strikethrough formatting.
    public func strikethrough() -> Text {
        var copy = self
        copy.style.isStrikethrough = true
        return copy
    }

    /// Dims the text (reduced intensity).
    ///
    /// - Returns: A new text with dimmed appearance.
    public func dim() -> Text {
        var copy = self
        copy.style.isDim = true
        return copy
    }

    /// Makes the text blink (if supported by the terminal).
    ///
    /// - Returns: A new text with blink effect.
    public func blink() -> Text {
        var copy = self
        copy.style.isBlink = true
        return copy
    }

    /// Inverts foreground and background colors.
    ///
    /// - Returns: A new text with inverted colors.
    public func inverted() -> Text {
        var copy = self
        copy.style.isInverted = true
        return copy
    }
}

// MARK: - TextStyle

/// The style of a text view.
///
/// Contains all formatting options like color, bold, etc.
public struct TextStyle: Sendable, Equatable {
    /// The foreground color of the text.
    public var foregroundColor: Color?

    /// The background color of the text.
    public var backgroundColor: Color?

    /// Whether the text is bold.
    public var isBold: Bool = false

    /// Whether the text is italic.
    public var isItalic: Bool = false

    /// Whether the text is underlined.
    public var isUnderlined: Bool = false

    /// Whether the text is strikethrough.
    public var isStrikethrough: Bool = false

    /// Whether the text is dimmed.
    public var isDim: Bool = false

    /// Whether the text blinks.
    public var isBlink: Bool = false

    /// Whether foreground and background colors are inverted.
    public var isInverted: Bool = false

    /// Creates a default TextStyle with no formatting.
    public init() {}
}

// MARK: - Public API

extension TextStyle {
    /// Resolves any semantic colors in this style against the given palette.
    ///
    /// Non-semantic colors are left unchanged. Call this before passing
    /// the style to `ANSIRenderer`.
    ///
    /// - Parameter palette: The palette to resolve semantic colors against.
    /// - Returns: A copy with all colors resolved to concrete values.
    public func resolved(with palette: any Palette) -> TextStyle {
        var copy = self
        copy.foregroundColor = foregroundColor?.resolve(with: palette)
        copy.backgroundColor = backgroundColor?.resolve(with: palette)
        return copy
    }
}

// MARK: - Text Rendering

extension Text: Renderable, Layoutable {
    public func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        // Text has a fixed size based on its content.
        // If a width is proposed, we may word-wrap.
        let maxWidth = proposal.width ?? context.availableWidth
        let wrappedLines = wordWrap(content, maxWidth: maxWidth)

        let width = wrappedLines.map(\.strippedLength).max() ?? 0
        let height = wrappedLines.count

        // Text is never flexible - it has a fixed size
        return ViewSize.fixed(width, height)
    }

    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        var effectiveStyle = style

        // If no explicit foreground color is set on the Text itself,
        // inherit from the environment (set by .foregroundStyle() on parent views),
        // or fall back to the palette's default foreground color
        if effectiveStyle.foregroundColor == nil {
            effectiveStyle.foregroundColor = context.environment.foregroundStyle
                ?? context.environment.palette.foreground
        }

        let resolvedStyle = effectiveStyle.resolved(with: context.environment.palette)

        // Word-wrap text to fit available width
        let wrappedLines = wordWrap(content, maxWidth: context.availableWidth)

        // Apply styling to each line
        let styledLines = wrappedLines.map { ANSIRenderer.render($0, with: resolvedStyle) }

        return FrameBuffer(lines: styledLines)
    }

    /// Wraps text into lines that fit a maximum terminal-cell width.
    ///
    /// Splits on word boundaries where possible and splits long words only
    /// between complete grapheme clusters.
    ///
    /// - Parameters:
    ///   - text: The text to wrap.
    ///   - maxWidth: Maximum characters per line.
    /// - Returns: An array of wrapped lines (never empty).
    private func wordWrap(_ text: String, maxWidth: Int) -> [String] {
        let paragraphs = text.split(separator: "\n", omittingEmptySubsequences: false)
        let lines = paragraphs.flatMap { paragraph in
            wrapParagraph(String(paragraph).sanitizedForTerminal, maxWidth: maxWidth)
        }
        return lines.isEmpty ? [""] : lines
    }

    private func wrapParagraph(_ paragraph: String, maxWidth: Int) -> [String] {
        guard maxWidth > 0 else { return [paragraph] }

        let words = paragraph.split(separator: " ", omittingEmptySubsequences: false)
        var lines: [String] = []
        var currentLine = ""

        for (wordIndex, word) in words.enumerated() {
            let wordStr = String(word)
            let separator = wordIndex == 0 ? "" : " "
            let candidate = currentLine + separator + wordStr

            if candidate.strippedLength <= maxWidth {
                currentLine = candidate
                continue
            }

            if !currentLine.isEmpty {
                lines.append(currentLine)
                currentLine = ""
            }

            let chunks = splitWord(wordStr, maxWidth: maxWidth)
            if chunks.count > 1 {
                lines.append(contentsOf: chunks.dropLast())
            }
            currentLine = chunks.last ?? ""
        }

        if !currentLine.isEmpty || lines.isEmpty {
            lines.append(currentLine)
        }

        return lines
    }

    private func splitWord(_ word: String, maxWidth: Int) -> [String] {
        guard !word.isEmpty else { return [""] }

        var chunks: [String] = []
        var chunk = ""
        var chunkWidth = 0

        for character in word {
            let characterWidth = character.terminalWidth
            if !chunk.isEmpty && chunkWidth + characterWidth > maxWidth {
                chunks.append(chunk)
                chunk = ""
                chunkWidth = 0
            }

            chunk.append(character)
            chunkWidth += characterWidth

            if chunkWidth > maxWidth {
                chunks.append(chunk)
                chunk = ""
                chunkWidth = 0
            }
        }

        if !chunk.isEmpty {
            chunks.append(chunk)
        }

        return chunks.isEmpty ? [""] : chunks
    }
}
