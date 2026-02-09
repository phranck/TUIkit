//  TUIKit - Terminal UI Kit for Swift
//  TrackRenderer.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Track Renderer

/// Utility for rendering track-based visual indicators.
///
/// `TrackRenderer` provides shared rendering logic for controls that display
/// a visual track, such as `ProgressView` and `Slider`. It supports multiple
/// styles via ``TrackStyle``.
///
/// ## Usage
///
/// ```swift
/// let track = TrackRenderer.render(
///     fraction: 0.5,
///     width: 20,
///     style: .block,
///     filledColor: palette.foregroundSecondary,
///     emptyColor: palette.foregroundTertiary,
///     accentColor: palette.accent
/// )
/// ```
enum TrackRenderer {
    /// Renders a track with the specified style and colors.
    ///
    /// - Parameters:
    ///   - fraction: The completed fraction (0.0 to 1.0).
    ///   - width: The width in characters.
    ///   - style: The visual style to use.
    ///   - filledColor: The color for filled portions.
    ///   - emptyColor: The color for empty portions.
    ///   - accentColor: The color for accent elements (e.g., dot head).
    /// - Returns: An ANSI-styled string representing the track.
    static func render(
        fraction: Double,
        width: Int,
        style: TrackStyle,
        filledColor: Color,
        emptyColor: Color,
        accentColor: Color
    ) -> String {
        guard width > 0 else { return "" }

        switch style {
        case .block:
            return renderSimpleStyle(
                fraction: fraction, width: width,
                filledChar: "█", emptyChar: "░",
                filledColor: filledColor, emptyColor: emptyColor
            )
        case .blockFine:
            return renderBlockFineStyle(
                fraction: fraction, width: width,
                filledColor: filledColor, emptyColor: emptyColor
            )
        case .shade:
            return renderSimpleStyle(
                fraction: fraction, width: width,
                filledChar: "▓", emptyChar: "░",
                filledColor: filledColor, emptyColor: emptyColor
            )
        case .bar:
            return renderSimpleStyle(
                fraction: fraction, width: width,
                filledChar: "▌", emptyChar: "─",
                filledColor: filledColor, emptyColor: emptyColor
            )
        case .dot:
            return renderHeadStyle(
                fraction: fraction, width: width,
                filledChar: "▬", headChar: "●", emptyChar: "─",
                filledColor: filledColor, headColor: accentColor, emptyColor: emptyColor
            )
        }
    }
}

// MARK: - Private Rendering Methods

extension TrackRenderer {
    /// Renders a simple two-character style (filled + empty, no head indicator).
    private static func renderSimpleStyle(
        fraction: Double,
        width: Int,
        filledChar: Character,
        emptyChar: Character,
        filledColor: Color,
        emptyColor: Color
    ) -> String {
        let filledCount = Int((fraction * Double(width)).rounded())
        let emptyCount = width - filledCount

        var result = ""
        if filledCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: filledChar, count: filledCount),
                foreground: filledColor
            )
        }
        if emptyCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: emptyChar, count: emptyCount),
                foreground: emptyColor
            )
        }
        return result
    }

    /// Renders the `.blockFine` style with sub-character fractional precision.
    private static func renderBlockFineStyle(
        fraction: Double,
        width: Int,
        filledColor: Color,
        emptyColor: Color
    ) -> String {
        let totalEighths = fraction * Double(width) * 8.0
        let fullCells = Int(totalEighths) / 8
        let remainderEighths = Int(totalEighths) % 8

        let fractionalBlocks: [Character] = ["▏", "▎", "▍", "▌", "▋", "▊", "▉"]

        var result = ""

        if fullCells > 0 {
            let filledBar = String(repeating: "█", count: fullCells)
            result += ANSIRenderer.colorize(filledBar, foreground: filledColor)
        }

        let cellsUsed: Int
        if remainderEighths > 0 && fullCells < width {
            let partialChar = fractionalBlocks[remainderEighths - 1]
            result += ANSIRenderer.colorize(String(partialChar), foreground: filledColor)
            cellsUsed = fullCells + 1
        } else {
            cellsUsed = fullCells
        }

        let emptyCount = width - cellsUsed
        if emptyCount > 0 {
            let emptyBar = String(repeating: "░", count: emptyCount)
            result += ANSIRenderer.colorize(emptyBar, foreground: emptyColor)
        }

        return result
    }

    /// Renders a head-indicator style (filled track + head + empty track).
    private static func renderHeadStyle(
        fraction: Double,
        width: Int,
        filledChar: Character,
        headChar: Character,
        emptyChar: Character,
        filledColor: Color,
        headColor: Color,
        emptyColor: Color
    ) -> String {
        let filledCount = Int((fraction * Double(width)).rounded())

        var result = ""

        let trackCount = max(0, filledCount - 1)
        if trackCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: filledChar, count: trackCount),
                foreground: filledColor
            )
        }

        if filledCount > 0 && filledCount <= width {
            result += ANSIRenderer.colorize(String(headChar), foreground: headColor)
        }

        let emptyCount = width - max(filledCount, 0)
        if emptyCount > 0 {
            result += ANSIRenderer.colorize(
                String(repeating: emptyChar, count: emptyCount),
                foreground: emptyColor
            )
        }

        return result
    }
}
