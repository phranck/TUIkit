//  🖥️ TUIKit — Terminal UI Kit for Swift
//  String+ANSI.swift
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
    var terminalWidth: Int {
        let scalars = unicodeScalars
        guard let first = scalars.first else { return 0 }
        let scalarValue = first.value

        // Zero-width characters
        if scalarValue == 0x200B || scalarValue == 0x200C || scalarValue == 0x200D || scalarValue == 0xFEFF { return 0 } // ZW space/NJ/J/BOM
        if scalarValue == 0x00AD { return 0 } // soft hyphen
        if (0xFE00...0xFE0F).contains(scalarValue) { return 0 } // variation selectors
        if (0xE0100...0xE01EF).contains(scalarValue) { return 0 } // variation selectors supplement
        if (0x0300...0x036F).contains(scalarValue) { return 0 } // combining diacritical marks
        if (0x1AB0...0x1AFF).contains(scalarValue) { return 0 } // combining diacritical marks extended
        if (0x1DC0...0x1DFF).contains(scalarValue) { return 0 } // combining diacritical marks supplement
        if (0x20D0...0x20FF).contains(scalarValue) { return 0 } // combining marks for symbols
        if (0xFE20...0xFE2F).contains(scalarValue) { return 0 } // combining half marks
        if (0xE0000...0xE007F).contains(scalarValue) { return 0 } // tags block

        // Multi-scalar grapheme clusters (emoji sequences with ZWJ, skin tones,
        // flag sequences, keycap sequences) are typically 2 cells wide.
        if scalars.count > 1 {
            // If the only extra scalars are variation selectors (U+FE0F/U+FE0E),
            // fall through to the base character width check. Many terminals
            // don't widen characters just because of a presentation selector
            // (e.g. ⚙️ = U+2699 + U+FE0F is still 1 cell in most terminals).
            let hasNonVariationExtras = scalars.dropFirst().contains { scalar in
                let sv = scalar.value
                return !(0xFE00...0xFE0F).contains(sv) && !(0xE0100...0xE01EF).contains(sv)
            }
            if hasNonVariationExtras {
                // True multi-character sequence (ZWJ, flags, keycaps, skin tones)
                return 2
            }
            // Just base + variation selector(s): fall through to base char width
        }

        // East Asian Wide and Fullwidth characters (2 cells)
        if (0x1100...0x115F).contains(scalarValue) { return 2 } // Hangul Jamo
        if (0x2329...0x232A).contains(scalarValue) { return 2 } // angle brackets
        if (0x2E80...0x303E).contains(scalarValue) { return 2 } // CJK radicals, Kangxi, ideographic
        if (0x3041...0x33BF).contains(scalarValue) { return 2 } // Hiragana, Katakana, Bopomofo, Hangul compat, Kanbun, CJK
        if (0x33D0...0x33FF).contains(scalarValue) { return 2 } // CJK compatibility
        if (0x3400...0x4DBF).contains(scalarValue) { return 2 } // CJK unified ext A
        if (0x4E00...0x9FFF).contains(scalarValue) { return 2 } // CJK unified
        if (0xA000...0xA4CF).contains(scalarValue) { return 2 } // Yi
        if (0xA960...0xA97F).contains(scalarValue) { return 2 } // Hangul Jamo extended A
        if (0xAC00...0xD7AF).contains(scalarValue) { return 2 } // Hangul syllables
        if (0xF900...0xFAFF).contains(scalarValue) { return 2 } // CJK compatibility ideographs
        if (0xFE10...0xFE19).contains(scalarValue) { return 2 } // vertical forms
        if (0xFE30...0xFE6F).contains(scalarValue) { return 2 } // CJK compatibility forms, small forms
        if (0xFF01...0xFF60).contains(scalarValue) { return 2 } // fullwidth forms
        if (0xFFE0...0xFFE6).contains(scalarValue) { return 2 } // fullwidth signs
        if (0x1F000...0x1FBFF).contains(scalarValue) { return 2 } // emoji and symbols (Mahjong, Dominos, Playing Cards, Emoji, etc.)
        if (0x20000...0x2FA1F).contains(scalarValue) { return 2 } // CJK unified extensions B-F, compatibility supplement
        if (0x30000...0x3134F).contains(scalarValue) { return 2 } // CJK unified extension G

        return 1
    }
}

// MARK: - ANSI String Helpers

extension String {
    /// The visible width of the string in terminal cells, excluding ANSI escape codes.
    ///
    /// Accounts for wide characters (emoji, CJK) that occupy 2 terminal cells
    /// and zero-width characters (combining marks, variation selectors).
    var strippedLength: Int {
        var count = 0
        var index = startIndex

        while index < endIndex {
            if self[index] == "\u{1B}" {
                // Skip ANSI sequence: ESC [ params letter
                index = self.index(after: index)
                if index < endIndex && self[index] == "[" {
                    index = self.index(after: index)
                    // Skip parameter bytes (digits, semicolons)
                    while index < endIndex && (self[index].isNumber || self[index] == ";") {
                        index = self.index(after: index)
                    }
                    // Skip the final byte (letter)
                    if index < endIndex && self[index].isLetter {
                        index = self.index(after: index)
                    }
                }
            } else {
                count += self[index].terminalWidth
                index = self.index(after: index)
            }
        }

        return count
    }

    /// The string with all ANSI escape codes removed.
    var stripped: String {
        var result = ""
        result.reserveCapacity(count)
        var index = startIndex

        while index < endIndex {
            if self[index] == "\u{1B}" {
                // Skip ANSI sequence: ESC [ params letter
                index = self.index(after: index)
                if index < endIndex && self[index] == "[" {
                    index = self.index(after: index)
                    while index < endIndex && (self[index].isNumber || self[index] == ";") {
                        index = self.index(after: index)
                    }
                    if index < endIndex && self[index].isLetter {
                        index = self.index(after: index)
                    }
                }
            } else {
                result.append(self[index])
                index = self.index(after: index)
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
    func padToVisibleWidth(_ targetWidth: Int) -> String {
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
    func ansiAwarePrefix(visibleCount: Int) -> String {
        guard visibleCount > 0 else { return "" }

        var result = ""
        var visible = 0
        var index = startIndex

        while index < endIndex && visible < visibleCount {
            // Check if we're at the start of an ANSI escape sequence
            if self[index] == "\u{1B}" {
                // Consume the entire ANSI sequence (ESC [ ... letter)
                let seqStart = index
                index = self.index(after: index)
                if index < endIndex && self[index] == "[" {
                    index = self.index(after: index)
                    // Skip parameter bytes (digits, semicolons)
                    while index < endIndex && (self[index].isNumber || self[index] == ";") {
                        index = self.index(after: index)
                    }
                    // Skip the final byte (letter)
                    if index < endIndex && self[index].isLetter {
                        index = self.index(after: index)
                    }
                }
                result += String(self[seqStart..<index])
            } else {
                let charWidth = self[index].terminalWidth
                if visible + charWidth > visibleCount { break }
                result.append(self[index])
                visible += charWidth
                index = self.index(after: index)
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
    func ansiAwareSuffix(droppingVisible dropCount: Int) -> String {
        var visible = 0
        var index = startIndex

        while index < endIndex && visible < dropCount {
            if self[index] == "\u{1B}" {
                // Skip the entire ANSI sequence
                index = self.index(after: index)
                if index < endIndex && self[index] == "[" {
                    index = self.index(after: index)
                    while index < endIndex && (self[index].isNumber || self[index] == ";") {
                        index = self.index(after: index)
                    }
                    if index < endIndex && self[index].isLetter {
                        index = self.index(after: index)
                    }
                }
            } else {
                visible += self[index].terminalWidth
                index = self.index(after: index)
            }
        }

        guard index < endIndex else { return "" }
        return String(self[index...])
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
    func leadingANSISequences() -> String {
        var result = ""
        var index = startIndex

        while index < endIndex {
            guard self[index] == "\u{1B}" else { break }

            // Consume the ANSI sequence (ESC [ params letter)
            let seqStart = index
            index = self.index(after: index)
            if index < endIndex && self[index] == "[" {
                index = self.index(after: index)
                while index < endIndex && (self[index].isNumber || self[index] == ";") {
                    index = self.index(after: index)
                }
                if index < endIndex && self[index].isLetter {
                    index = self.index(after: index)
                }
            }
            result += String(self[seqStart..<index])
        }

        return result
    }

    /// Applies a persistent background color that survives inner ANSI resets.
    ///
    /// If `color` is `nil`, the string is returned unchanged.
    ///
    /// - Parameter color: The background color, or `nil` for no change.
    /// - Returns: The string with persistent background applied, or unchanged if `color` is `nil`.
    func withPersistentBackground(_ color: Color?) -> String {
        guard let color else { return self }
        return ANSIRenderer.applyPersistentBackground(self, color: color)
    }
}
