//  🖥️ TUIKit — Terminal UI Kit for Swift
//  String+ANSI.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - ANSI String Helpers

extension String {
    /// The visible length of the string, excluding ANSI escape codes.
    ///
    /// Counts visible characters by walking the string and skipping
    /// ANSI escape sequences. This is faster than regex-based approaches.
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
                count += 1
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

    /// Pads the string to the specified visible width using spaces.
    ///
    /// ANSI codes are excluded from the width calculation.
    ///
    /// - Parameter targetWidth: The desired visible width.
    /// - Returns: The padded string.
    func padToVisibleWidth(_ targetWidth: Int) -> String {
        let currentWidth = strippedLength
        if currentWidth >= targetWidth {
            return self
        }
        return self + String(repeating: " ", count: targetWidth - currentWidth)
    }

    // MARK: - ANSI-Aware Splitting

    /// Returns the first `visibleCount` visible characters, preserving all ANSI codes
    /// that appear before or within that range.
    ///
    /// Walks the string character by character, passing through ANSI escape sequences
    /// without counting them as visible. Stops after emitting `visibleCount` visible characters.
    ///
    /// - Parameter visibleCount: The number of visible characters to include.
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
                result.append(self[index])
                visible += 1
                index = self.index(after: index)
            }
        }

        return result
    }

    /// Returns everything after the first `dropCount` visible characters,
    /// preserving ANSI codes that appear at or after that boundary.
    ///
    /// Skips past the first `dropCount` visible characters (and any interleaved
    /// ANSI codes), then returns the remainder of the string.
    ///
    /// - Parameter dropCount: The number of visible characters to skip.
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
                visible += 1
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
}
