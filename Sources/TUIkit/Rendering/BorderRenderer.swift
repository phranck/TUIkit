//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BorderRenderer.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// Reusable building blocks for border rendering.
///
/// Each method produces a single rendered line (`String`) that callers
/// append to a `[String]` array for `FrameBuffer` construction.
/// This eliminates duplicated border-assembly code across Views and Modifiers.
///
/// Uses standard box-drawing characters (┌─┐│└─┘├─┤) with configurable
/// ``BorderStyle`` presets (line, rounded, doubleLine, heavy).
enum BorderRenderer {

    /// The total width consumed by left + right border characters (1 + 1 = 2).
    static let borderWidthOverhead = 2

    /// The breathing focus indicator character.
    static let focusIndicator: Character = "●"
}

// MARK: - Border Rendering

extension BorderRenderer {
    /// Renders a plain top border line.
    ///
    ///     ┌──────────────┐
    ///
    /// - Parameters:
    ///   - style: The border style providing corner and edge characters.
    ///   - innerWidth: The width of the content area (excluding borders).
    ///   - color: The foreground color for the border.
    ///   - focusIndicatorColor: If non-nil, renders a ● after the top-left corner
    ///     in this color. Used for the breathing focus section indicator.
    /// - Returns: A colorized top border string.
    static func standardTopBorder(
        style: BorderStyle,
        innerWidth: Int,
        color: Color,
        focusIndicatorColor: Color? = nil
    ) -> String {
        if let indicatorColor = focusIndicatorColor, innerWidth > 1 {
            // ╭●──────────────╮
            let leftCorner = ANSIRenderer.colorize(String(style.topLeft), foreground: color)
            let indicator = ANSIRenderer.colorize(String(focusIndicator), foreground: indicatorColor)
            let remainingWidth = innerWidth - 1  // -1 for the ● character
            let rest = ANSIRenderer.colorize(
                String(repeating: style.horizontal, count: remainingWidth)
                    + String(style.topRight),
                foreground: color
            )
            return leftCorner + indicator + rest
        }

        let line =
            String(style.topLeft)
            + String(repeating: style.horizontal, count: innerWidth)
            + String(style.topRight)
        return ANSIRenderer.colorize(line, foreground: color)
    }

    /// Renders a top border line with an inline title.
    ///
    ///     ┌─ Title ──────┐   (without focus indicator)
    ///     ┌● Title ──────┐   (with focus indicator)
    ///
    /// - Parameters:
    ///   - style: The border style.
    ///   - innerWidth: The content width.
    ///   - color: The border color.
    ///   - title: The title text.
    ///   - titleColor: The title foreground color.
    ///   - focusIndicatorColor: If non-nil, renders a ● between the corner
    ///     and the title. Used for the breathing focus section indicator.
    /// - Returns: A colorized top border string with embedded title.
    static func standardTopBorder(
        style: BorderStyle,
        innerWidth: Int,
        color: Color,
        title: String,
        titleColor: Color,
        focusIndicatorColor: Color? = nil
    ) -> String {
        let titleStyled = ANSIRenderer.colorize(" \(title) ", foreground: titleColor, bold: true)

        let leftPart: String
        let usedLeftWidth: Int
        if let indicatorColor = focusIndicatorColor {
            // ╭● Title
            let corner = ANSIRenderer.colorize(String(style.topLeft), foreground: color)
            let indicator = ANSIRenderer.colorize(String(focusIndicator), foreground: indicatorColor)
            leftPart = corner + indicator
            usedLeftWidth = 1  // only the ● (corner is outside innerWidth)
        } else {
            // ╭─ Title
            leftPart = ANSIRenderer.colorize(
                String(style.topLeft) + String(style.horizontal),
                foreground: color
            )
            usedLeftWidth = 1  // only the ─ after corner
        }

        let rightPartLength = max(0, innerWidth - usedLeftWidth - title.count - 2)
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
    static func standardBottomBorder(
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
    static func standardDivider(
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
    static func standardContentLine(
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
}


