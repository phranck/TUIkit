//  🖥️ TUIKit — Terminal UI Kit for Swift
//  String+TerminalWidth.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Terminal Character Width

extension Character {
    /// The display width of this character in a terminal (number of cells).
    ///
    /// Most characters occupy 1 cell. East Asian wide characters (CJK, most
    /// emoji) occupy 2 cells. Zero-width characters (combining marks,
    /// variation selectors, ZWJ) occupy 0 cells.
    public var terminalWidth: Int {
        let visibleScalars = unicodeScalars.filter { !$0.isZeroWidthInTerminal }
        guard !visibleScalars.isEmpty else { return 0 }

        return visibleScalars.contains(where: \.isWideInTerminal) ? 2 : 1
    }
}

private extension Unicode.Scalar {
    var isZeroWidthInTerminal: Bool {
        switch properties.generalCategory {
        case .control, .format, .nonspacingMark, .spacingMark, .enclosingMark:
            return true
        default:
            return value == 0x00AD ||
                (0xFE00...0xFE0F).contains(value) ||
                (0xE0100...0xE01EF).contains(value) ||
                (0xE0000...0xE007F).contains(value)
        }
    }

    var isWideInTerminal: Bool {
        (0x1100...0x115F).contains(value) ||
            (0x2329...0x232A).contains(value) ||
            (0x2E80...0x303E).contains(value) ||
            (0x3041...0x33BF).contains(value) ||
            (0x33D0...0x33FF).contains(value) ||
            (0x3400...0x4DBF).contains(value) ||
            (0x4E00...0x9FFF).contains(value) ||
            (0xA000...0xA4CF).contains(value) ||
            (0xA960...0xA97F).contains(value) ||
            (0xAC00...0xD7AF).contains(value) ||
            (0xF900...0xFAFF).contains(value) ||
            (0xFE10...0xFE19).contains(value) ||
            (0xFE30...0xFE6F).contains(value) ||
            (0xFF01...0xFF60).contains(value) ||
            (0xFFE0...0xFFE6).contains(value) ||
            (0x1F000...0x1FBFF).contains(value) ||
            (0x20000...0x2FA1F).contains(value) ||
            (0x30000...0x3134F).contains(value)
    }
}

// MARK: - ANSI String Helpers

extension String {
    /// The visible width of the string in terminal cells, excluding ANSI escape codes.
    ///
    /// Accounts for wide characters (emoji, CJK) that occupy 2 terminal cells
    /// and zero-width characters (combining marks, variation selectors).
    public var strippedLength: Int {
        var width = 0
        TerminalTextParser.scan(self) { token in
            if case .grapheme(let character) = token {
                width += character.terminalWidth
            }
        }
        return width
    }

    /// The string with all ANSI escape codes removed.
    public var stripped: String {
        var result = ""
        result.reserveCapacity(count)
        TerminalTextParser.scan(self) { token in
            if case .grapheme(let character) = token {
                result.append(character)
            }
        }
        return result
    }

    /// Returns a copy with ANSI escape sequences removed, suitable for rendering user-provided content.
    ///
    /// Use this to sanitize user input before passing it to ``Text`` or other views
    /// to prevent terminal escape sequence injection (cursor manipulation, color changes, etc.).
    ///
    /// ```swift
    /// Text(userInput.sanitizedForTerminal)
    /// ```
    public var sanitizedForTerminal: String {
        stripped
    }

    /// Pads the string to the specified visible width using spaces.
    ///
    /// ANSI codes and wide characters are handled correctly.
    ///
    /// - Parameter targetWidth: The desired visible width in terminal cells.
    /// - Returns: The padded string.
    public func padToVisibleWidth(_ targetWidth: Int) -> String {
        let currentWidth = strippedLength
        if currentWidth >= targetWidth {
            return self
        }
        return self + String(repeating: " ", count: targetWidth - currentWidth)
    }

    // MARK: - ANSI-Aware Splitting

    /// Returns the first `visibleCount` terminal cells worth of visible characters,
    /// preserving all ANSI codes that appear before or within that range.
    ///
    /// Wide characters (emoji, CJK) count as 2 cells. If a wide character would
    /// exceed the limit, it is excluded.
    ///
    /// - Parameter visibleCount: The number of terminal cells to include.
    /// - Returns: A substring with ANSI codes intact up to the visible boundary.
    public func ansiAwarePrefix(visibleCount: Int) -> String {
        guard visibleCount > 0 else { return "" }

        var result = ""
        var visible = 0
        var reachedBoundary = false
        TerminalTextParser.scan(self) { token in
            guard !reachedBoundary, visible < visibleCount else { return }
            switch token {
            case .sgr(_, let sequence):
                result += sequence
            case .grapheme(let character):
                let charWidth = character.terminalWidth
                guard visible + charWidth <= visibleCount else {
                    reachedBoundary = true
                    return
                }
                result.append(character)
                visible += charWidth
            }
        }
        return result
    }

    /// Returns everything after the first `dropCount` terminal cells of visible characters,
    /// preserving ANSI codes that appear at or after that boundary.
    ///
    /// Wide characters count as 2 cells.
    ///
    /// - Parameter dropCount: The number of terminal cells to skip.
    /// - Returns: The remainder of the string with ANSI codes intact.
    public func ansiAwareSuffix(droppingVisible dropCount: Int) -> String {
        var visible = 0
        var result = ""
        TerminalTextParser.scan(self) { token in
            switch token {
            case .sgr(_, let sequence):
                if visible >= dropCount {
                    result += sequence
                }
            case .grapheme(let character):
                if visible >= dropCount {
                    result.append(character)
                }
                visible += character.terminalWidth
            }
        }
        return result
    }

    // MARK: - ANSI State Extraction

    /// Extracts all leading ANSI SGR sequences that appear before the first
    /// visible character and returns them concatenated.
    ///
    /// This captures the full styling state set up at the beginning of a line
    /// (e.g. background, foreground, dim) so it can be replayed to restore
    /// that state after an interruption (like an overlay insertion).
    ///
    /// Unlike scanning the entire string, this avoids picking up trailing
    /// codes that follow a reset (e.g. the lone background code appended by
    /// `applyPersistentBackground`).
    ///
    /// - Returns: The concatenated leading ANSI sequences, or an empty string
    ///   if the line starts with a visible character.
    public func leadingANSISequences() -> String {
        var result = ""
        var foundGrapheme = false
        TerminalTextParser.scan(self) { token in
            guard !foundGrapheme else { return }
            switch token {
            case .sgr(_, let sequence):
                result += sequence
            case .grapheme:
                foundGrapheme = true
            }
        }
        return result
    }
}
