//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ScrollIndicator.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Scroll Direction

/// The direction of a scroll indicator arrow.
enum ScrollDirection {
    case up, down
}

// MARK: - Scroll Indicator Rendering

/// Renders a centered scroll indicator line with an arrow and label.
///
/// Used by `_ListCore` and `_TableCore` to show "more above" / "more below"
/// indicators when content extends beyond the visible viewport.
///
/// - Parameters:
///   - direction: Whether the indicator points up or down.
///   - width: The total width available for the indicator line.
///   - palette: The color palette for styling.
/// - Returns: A styled string with a centered scroll indicator.
@MainActor
func renderScrollIndicator(direction: ScrollDirection, width: Int, palette: any Palette) -> String {
    let arrow = direction == .up ? "▲" : "▼"
    let label = direction == .up ? " more above " : " more below "

    let styledArrow = ANSIRenderer.colorize(arrow, foreground: palette.foregroundTertiary)
    let styledLabel = ANSIRenderer.colorize(label, foreground: palette.foregroundTertiary)

    let indicatorWidth = 1 + label.count
    let padding = max(0, (width - indicatorWidth) / 2)

    return String(repeating: " ", count: padding) + styledArrow + styledLabel
}
