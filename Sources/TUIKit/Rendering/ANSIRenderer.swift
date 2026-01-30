//
//  ANSIRenderer.swift
//  TUIKit
//
//  ANSI escape code generation for terminal output.
//

/// Generates ANSI escape codes for terminal formatting.
///
/// `ANSIRenderer` translates `TextStyle` and `Color` into the corresponding
/// ANSI escape sequences that are understood by most terminals.
public enum ANSIRenderer {
    /// The escape character for ANSI sequences.
    public static let escape = "\u{1B}"

    /// The Control Sequence Introducer (CSI).
    public static let csi = "\(escape)["

    /// Reset code that clears all formatting.
    public static let reset = "\(csi)0m"

    /// Dim/faint text style code.
    public static let dim = "\(csi)2m"

    /// Precompiled regex that matches any ANSI escape sequence.
    ///
    /// Used by `String.stripped` and `String.strippedLength` to remove
    /// formatting codes for visible-width calculations. Compiling once
    /// avoids per-call overhead in the hot rendering path.
    public static nonisolated(unsafe) let ansiRegex = /\u{1B}\[[0-9;]*[a-zA-Z]/

    // MARK: - SGR Style Codes

    /// Named constants for ANSI SGR (Select Graphic Rendition) attribute codes.
    ///
    /// These replace bare string literals like `"1"`, `"7"` in `buildStyleCodes()`.
    private enum StyleCode {
        static let bold = "1"
        static let dim = "2"
        static let italic = "3"
        static let underline = "4"
        static let blink = "5"
        static let inverse = "7"
        static let strikethrough = "9"
    }

    // MARK: - Style Rendering

    /// Renders text with the specified style.
    ///
    /// - Parameters:
    ///   - text: The text to render.
    ///   - style: The TextStyle to apply.
    /// - Returns: The formatted string with ANSI codes.
    public static func render(_ text: String, with style: TextStyle) -> String {
        let codes = buildStyleCodes(style)

        if codes.isEmpty {
            return text
        }

        let styleSequence = "\(csi)\(codes.joined(separator: ";"))m"
        return "\(styleSequence)\(text)\(reset)"
    }

    /// Builds the ANSI codes for a TextStyle.
    ///
    /// - Parameter style: The TextStyle to convert.
    /// - Returns: An array of ANSI code strings.
    private static func buildStyleCodes(_ style: TextStyle) -> [String] {
        var codes: [String] = []

        // Text attributes
        if style.isBold {
            codes.append(StyleCode.bold)
        }
        if style.isDim {
            codes.append(StyleCode.dim)
        }
        if style.isItalic {
            codes.append(StyleCode.italic)
        }
        if style.isUnderlined {
            codes.append(StyleCode.underline)
        }
        if style.isBlink {
            codes.append(StyleCode.blink)
        }
        if style.isInverted {
            codes.append(StyleCode.inverse)
        }
        if style.isStrikethrough {
            codes.append(StyleCode.strikethrough)
        }

        // Foreground color
        if let fgColor = style.foregroundColor {
            codes.append(contentsOf: foregroundCodes(for: fgColor))
        }

        // Background color
        if let bgColor = style.backgroundColor {
            codes.append(contentsOf: backgroundCodes(for: bgColor))
        }

        return codes
    }

    // MARK: - Color Codes

    /// Generates the ANSI codes for a foreground color.
    ///
    /// - Parameter color: The color.
    /// - Returns: The ANSI code strings.
    private static func foregroundCodes(for color: Color) -> [String] {
        switch color.value {
        case .standard(let ansi):
            return ["\(ansi.foregroundCode)"]
        case .bright(let ansi):
            return ["\(ansi.brightForegroundCode)"]
        case .palette256(let index):
            return ["38", "5", "\(index)"]
        case .rgb(let red, let green, let blue):
            return ["38", "2", "\(red)", "\(green)", "\(blue)"]
        }
    }

    /// Generates the ANSI codes for a background color.
    ///
    /// - Parameter color: The color.
    /// - Returns: The ANSI code strings.
    private static func backgroundCodes(for color: Color) -> [String] {
        switch color.value {
        case .standard(let ansi):
            return ["\(ansi.backgroundCode)"]
        case .bright(let ansi):
            return ["\(ansi.brightBackgroundCode)"]
        case .palette256(let index):
            return ["48", "5", "\(index)"]
        case .rgb(let red, let green, let blue):
            return ["48", "2", "\(red)", "\(green)", "\(blue)"]
        }
    }

    /// Generates the ANSI escape sequence for a background color.
    ///
    /// Use this to set only the background color without other styles.
    ///
    /// - Parameter color: The background color.
    /// - Returns: The ANSI escape sequence.
    public static func backgroundCode(for color: Color) -> String {
        let codes = backgroundCodes(for: color)
        return "\(csi)\(codes.joined(separator: ";"))m"
    }

    // MARK: - Convenience Colorize

    /// Applies foreground color to a string using `TextStyle` + `render()`.
    ///
    /// This is the centralized replacement for the many per-file
    /// `colorize` / `colorizeBorder` / `colorizeWithForeground` helpers.
    ///
    /// - Parameters:
    ///   - string: The text to colorize.
    ///   - foreground: Optional foreground color.
    ///   - background: Optional background color.
    ///   - bold: Whether to apply bold.
    /// - Returns: The ANSI-formatted string.
    public static func colorize(
        _ string: String,
        foreground: Color? = nil,
        background: Color? = nil,
        bold: Bool = false
    ) -> String {
        var style = TextStyle()
        style.foregroundColor = foreground
        style.backgroundColor = background
        style.isBold = bold
        return render(string, with: style)
    }

    /// Wraps a string in a background color that persists across ANSI resets.
    ///
    /// Every occurrence of the reset code inside `string` is replaced with
    /// `reset + bgCode`, so the background "survives" foreground-color resets.
    /// This is necessary for container backgrounds where inner content contains
    /// its own ANSI reset sequences.
    ///
    /// - Parameters:
    ///   - string: The text to wrap.
    ///   - color: The background color.
    /// - Returns: The string with persistent background applied.
    public static func applyPersistentBackground(_ string: String, color: Color) -> String {
        let bgCode = backgroundCode(for: color)
        let stringWithPersistentBg = string.replacingOccurrences(
            of: reset,
            with: reset + bgCode
        )
        return bgCode + stringWithPersistentBg
    }

    // MARK: - Cursor Control

    /// Moves the cursor to the specified position.
    ///
    /// - Parameters:
    ///   - row: The row (1-based).
    ///   - column: The column (1-based).
    /// - Returns: The ANSI escape sequence.
    public static func moveCursor(toRow row: Int, column: Int) -> String {
        "\(csi)\(row);\(column)H"
    }

    /// Moves the cursor up by the specified number of lines.
    ///
    /// - Parameter lines: Number of lines.
    /// - Returns: The ANSI escape sequence.
    public static func cursorUp(_ lines: Int = 1) -> String {
        "\(csi)\(lines)A"
    }

    /// Moves the cursor down by the specified number of lines.
    ///
    /// - Parameter lines: Number of lines.
    /// - Returns: The ANSI escape sequence.
    public static func cursorDown(_ lines: Int = 1) -> String {
        "\(csi)\(lines)B"
    }

    /// Moves the cursor forward by the specified number of columns.
    ///
    /// - Parameter columns: Number of columns.
    /// - Returns: The ANSI escape sequence.
    public static func cursorForward(_ columns: Int = 1) -> String {
        "\(csi)\(columns)C"
    }

    /// Moves the cursor back by the specified number of columns.
    ///
    /// - Parameter columns: Number of columns.
    /// - Returns: The ANSI escape sequence.
    public static func cursorBack(_ columns: Int = 1) -> String {
        "\(csi)\(columns)D"
    }

    /// Hides the cursor.
    public static let hideCursor = "\(csi)?25l"

    /// Shows the cursor.
    public static let showCursor = "\(csi)?25h"

    /// Saves the current cursor position.
    public static let saveCursor = "\(csi)s"

    /// Restores the saved cursor position.
    public static let restoreCursor = "\(csi)u"

    // MARK: - Screen Control

    /// Clears the entire screen.
    public static let clearScreen = "\(csi)2J"

    /// Clears from cursor to end of screen.
    public static let clearToEnd = "\(csi)0J"

    /// Clears from cursor to beginning of screen.
    public static let clearToBeginning = "\(csi)1J"

    /// Clears the current line.
    public static let clearLine = "\(csi)2K"

    /// Clears from cursor to end of line.
    public static let clearLineToEnd = "\(csi)0K"

    /// Clears from cursor to beginning of line.
    public static let clearLineToBeginning = "\(csi)1K"

    // MARK: - Alternate Screen Buffer

    /// Enters the alternate screen buffer.
    public static let enterAlternateScreen = "\(csi)?1049h"

    /// Exits the alternate screen buffer.
    public static let exitAlternateScreen = "\(csi)?1049l"
}
