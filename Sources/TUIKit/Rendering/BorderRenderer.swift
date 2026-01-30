//
//  BorderRenderer.swift
//  TUIKit
//
//  Centralized border rendering utilities for standard and block styles.
//

/// Reusable building blocks for border rendering.
///
/// Each method produces a single rendered line (`String`) that callers
/// append to a `[String]` array for `FrameBuffer` construction.
/// This eliminates duplicated border-assembly code across Views and Modifiers.
///
/// Two style families are supported:
/// - **Standard**: box-drawing characters (┌─┐│└─┘├─┤)
/// - **Block**: half-block characters (▄ █ ▀) for smooth visual edges
public enum BorderRenderer {

    /// The total width consumed by left + right border characters (1 + 1 = 2).
    public static let borderWidthOverhead = 2

    // MARK: - Standard Style (Box-Drawing Characters)

    /// Renders a plain top border line.
    ///
    ///     ┌──────────────┐
    ///
    /// - Parameters:
    ///   - style: The border style providing corner and edge characters.
    ///   - innerWidth: The width of the content area (excluding borders).
    ///   - color: The foreground color for the border.
    /// - Returns: A colorized top border string.
    public static func standardTopBorder(
        style: BorderStyle,
        innerWidth: Int,
        color: Color
    ) -> String {
        let line =
            String(style.topLeft)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.topRight)
        return ANSIRenderer.colorize(line, foreground: color)
    }

    /// Renders a top border line with an inline title.
    ///
    ///     ┌─ Title ──────┐
    ///
    /// - Parameters:
    ///   - style: The border style.
    ///   - innerWidth: The content width.
    ///   - color: The border color.
    ///   - title: The title text.
    ///   - titleColor: The title foreground color.
    /// - Returns: A colorized top border string with embedded title.
    public static func standardTopBorder(
        style: BorderStyle,
        innerWidth: Int,
        color: Color,
        title: String,
        titleColor: Color
    ) -> String {
        let titleStyled = ANSIRenderer.colorize(" \(title) ", foreground: titleColor, bold: true)
        let leftPart = ANSIRenderer.colorize(
            String(style.topLeft) + String(style.horizontal),
            foreground: color
        )
        let rightPartLength = max(0, innerWidth - 1 - title.count - 2)
        let rightPart = ANSIRenderer.colorize(
            String(repeating: style.horizontal, count: rightPartLength) + String(style.topRight),
            foreground: color
        )
        return leftPart + titleStyled + rightPart
    }

    /// Renders a plain bottom border line.
    ///
    ///     └──────────────┘
    ///
    /// - Parameters:
    ///   - style: The border style.
    ///   - innerWidth: The content width.
    ///   - color: The border color.
    /// - Returns: A colorized bottom border string.
    public static func standardBottomBorder(
        style: BorderStyle,
        innerWidth: Int,
        color: Color
    ) -> String {
        let line =
            String(style.bottomLeft)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.bottomRight)
        return ANSIRenderer.colorize(line, foreground: color)
    }

    /// Renders a horizontal divider with T-junctions.
    ///
    ///     ├──────────────┤
    ///
    /// - Parameters:
    ///   - style: The border style (uses leftT, horizontal, rightT).
    ///   - innerWidth: The content width.
    ///   - color: The border color.
    /// - Returns: A colorized divider string.
    public static func standardDivider(
        style: BorderStyle,
        innerWidth: Int,
        color: Color
    ) -> String {
        let line =
            String(style.leftT)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.rightT)
        return ANSIRenderer.colorize(line, foreground: color)
    }

    /// Wraps a single content line with vertical side borders.
    ///
    ///     │ padded content │
    ///
    /// If `backgroundColor` is provided, `applyPersistentBackground` is used
    /// so the background survives inner ANSI resets.
    ///
    /// - Parameters:
    ///   - content: The content string (will be padded to `innerWidth`).
    ///   - innerWidth: The target content width.
    ///   - style: The border style (for the vertical character).
    ///   - color: The border color.
    ///   - backgroundColor: Optional background applied to the content area.
    /// - Returns: The bordered content line.
    public static func standardContentLine(
        content: String,
        innerWidth: Int,
        style: BorderStyle,
        color: Color,
        backgroundColor: Color? = nil
    ) -> String {
        let paddedLine = content.padToVisibleWidth(innerWidth)
        let styledContent: String
        if let bgColor = backgroundColor {
            styledContent = ANSIRenderer.applyPersistentBackground(paddedLine, color: bgColor)
        } else {
            styledContent = paddedLine
        }
        let vertical = ANSIRenderer.colorize(String(style.vertical), foreground: color)
        return vertical + styledContent + ANSIRenderer.reset + vertical
    }

    // MARK: - Block Style (Half-Block Characters)

    /// Renders a block-style top border.
    ///
    ///     ▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    ///
    /// - Parameters:
    ///   - innerWidth: The content width (border width = innerWidth + 2).
    ///   - color: The foreground color (typically the section's background color).
    /// - Returns: The top border string.
    public static func blockTopBorder(
        innerWidth: Int,
        color: Color
    ) -> String {
        let line = String(repeating: BorderStyle.block.horizontal, count: innerWidth + 2)
        return ANSIRenderer.colorize(line, foreground: color)
    }

    /// Renders a block-style bottom border.
    ///
    ///     ▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    ///
    /// - Parameters:
    ///   - innerWidth: The content width (border width = innerWidth + 2).
    ///   - color: The foreground color (typically the section's background color).
    /// - Returns: The bottom border string.
    public static func blockBottomBorder(
        innerWidth: Int,
        color: Color
    ) -> String {
        let line = String(repeating: BorderStyle.blockBottomHorizontal, count: innerWidth + 2)
        return ANSIRenderer.colorize(line, foreground: color)
    }

    /// Wraps a single content line with full-block side borders
    /// and applies a persistent background.
    ///
    ///     █ content █
    ///
    /// - Parameters:
    ///   - content: The content string (will be padded to `innerWidth`).
    ///   - innerWidth: The target content width.
    ///   - sectionColor: The color for both `█` borders and content background.
    /// - Returns: The bordered content line.
    public static func blockContentLine(
        content: String,
        innerWidth: Int,
        sectionColor: Color
    ) -> String {
        let paddedLine = content.padToVisibleWidth(innerWidth)
        let sideBorder = ANSIRenderer.colorize(String(BorderStyle.block.vertical), foreground: sectionColor)
        let styledContent = ANSIRenderer.applyPersistentBackground(paddedLine, color: sectionColor)
        return sideBorder + styledContent + ANSIRenderer.reset + sideBorder
    }

    /// Renders a block-style section separator (transition between two background colors).
    ///
    ///     ▀▀▀▀▀▀▀▀▀▀▀▀▀▀  (header→body: FG=headerBg, BG=bodyBg)
    ///     ▄▄▄▄▄▄▄▄▄▄▄▄▄▄  (body→footer: FG=footerBg, BG=bodyBg)
    ///
    /// - Parameters:
    ///   - innerWidth: The content width (separator width = innerWidth + 2).
    ///   - character: The separator character (`.blockBottomHorizontal` for header→body, `.blockFooterSeparator` for body→footer).
    ///   - foregroundColor: The FG color (the section being transitioned from or to).
    ///   - backgroundColor: The BG color (the adjacent section).
    /// - Returns: The separator line.
    public static func blockSeparator(
        innerWidth: Int,
        character: Character = BorderStyle.blockBottomHorizontal,
        foregroundColor: Color,
        backgroundColor: Color
    ) -> String {
        let line = String(repeating: character, count: innerWidth + 2)
        return ANSIRenderer.colorize(line, foreground: foregroundColor, background: backgroundColor)
    }
}
