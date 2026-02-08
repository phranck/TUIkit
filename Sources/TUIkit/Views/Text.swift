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
///     .foregroundColor(.red)
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
    /// Sets the text color.
    ///
    /// - Parameter color: The desired foreground color.
    /// - Returns: A new text with the applied color.
    public func foregroundColor(_ color: Color) -> Text {
        var copy = self
        copy.style.foregroundColor = color
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

extension Text: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        var effectiveStyle = style

        // If no explicit foreground color is set on the Text itself,
        // inherit from the environment (set by .foregroundColor() on parent views),
        // or fall back to the palette's default foreground color
        if effectiveStyle.foregroundColor == nil {
            effectiveStyle.foregroundColor = context.environment.foregroundColor
                ?? context.environment.palette.foreground
        }

        let resolvedStyle = effectiveStyle.resolved(with: context.environment.palette)

        // Word-wrap text to fit available width
        let wrappedLines = wordWrap(content, maxWidth: context.availableWidth)

        // Apply styling to each line
        let styledLines = wrappedLines.map { ANSIRenderer.render($0, with: resolvedStyle) }

        return FrameBuffer(lines: styledLines)
    }

    /// Wraps text into lines that fit a maximum character width.
    ///
    /// Splits on word boundaries (spaces). Words longer than `maxWidth`
    /// are placed on their own line without further splitting.
    ///
    /// - Parameters:
    ///   - text: The text to wrap.
    ///   - maxWidth: Maximum characters per line.
    /// - Returns: An array of wrapped lines (never empty).
    private func wordWrap(_ text: String, maxWidth: Int) -> [String] {
        guard maxWidth > 0 else { return [text] }

        let words = text.split(separator: " ", omittingEmptySubsequences: false)
        var lines: [String] = []
        var currentLine = ""

        for word in words {
            let wordStr = String(word)
            if currentLine.isEmpty {
                currentLine = wordStr
            } else if currentLine.count + 1 + wordStr.count <= maxWidth {
                currentLine += " " + wordStr
            } else {
                lines.append(currentLine)
                currentLine = wordStr
            }
        }

        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        return lines.isEmpty ? [""] : lines
    }
}
