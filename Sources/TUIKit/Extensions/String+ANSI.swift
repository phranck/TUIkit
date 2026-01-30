//
//  String+ANSI.swift
//  TUIKit
//
//  ANSI-aware String helpers for visible-length calculation and padding.
//

// MARK: - ANSI String Helpers

extension String {
    /// The visible length of the string, excluding ANSI escape codes.
    var strippedLength: Int {
        stripped.count
    }

    /// The string with all ANSI escape codes removed.
    var stripped: String {
        replacingOccurrences(
            of: ANSIRenderer.ansiPattern,
            with: "",
            options: .regularExpression
        )
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
