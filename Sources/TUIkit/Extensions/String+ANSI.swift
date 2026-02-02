//
//  String+ANSI.swift
//  TUIkit
//
//  ANSI-aware String helpers for visible-length calculation and padding.
//

// MARK: - ANSI String Helpers

extension String {
    /// The visible length of the string, excluding ANSI escape codes.
    ///
    /// Counts visible characters without allocating an intermediate
    /// stripped string. Subtracts the total length of all ANSI escape
    /// sequences from the character count.
    var strippedLength: Int {
        var ansiLength = 0
        for match in self.matches(of: ANSIRenderer.ansiRegex) {
            ansiLength += self[match.range].count
        }
        return count - ansiLength
    }

    /// The string with all ANSI escape codes removed.
    var stripped: String {
        replacing(ANSIRenderer.ansiRegex, with: "")
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
}
