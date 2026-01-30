//
//  BorderStyle.swift
//  TUIkit
//
//  Border styles and character sets for TUI borders.
//

/// Defines the visual style of a border.
///
/// Each style provides characters for all border components:
/// corners, edges, and T-junctions for complex layouts.
public struct BorderStyle: Sendable, Equatable {
    /// Top-left corner character.
    public let topLeft: Character

    /// Top-right corner character.
    public let topRight: Character

    /// Bottom-left corner character.
    public let bottomLeft: Character

    /// Bottom-right corner character.
    public let bottomRight: Character

    /// Horizontal edge character.
    public let horizontal: Character

    /// Vertical edge character.
    public let vertical: Character

    /// Left T-junction character (├).
    public let leftT: Character

    /// Right T-junction character (┤).
    public let rightT: Character

    /// Creates a custom border style.
    public init(
        topLeft: Character,
        topRight: Character,
        bottomLeft: Character,
        bottomRight: Character,
        horizontal: Character,
        vertical: Character,
        leftT: Character? = nil,
        rightT: Character? = nil
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
        self.horizontal = horizontal
        self.vertical = vertical
        // Default T-junctions based on the vertical character
        self.leftT = leftT ?? vertical
        self.rightT = rightT ?? vertical
    }

    // MARK: - Preset Styles

    /// Single line border (─ │ ┌ ┐ └ ┘ ├ ┤).
    ///
    /// ```
    /// ┌────────┐
    /// │ Title  │
    /// ├────────┤
    /// │ Content│
    /// └────────┘
    /// ```
    public static let line = Self(
        topLeft: "┌",
        topRight: "┐",
        bottomLeft: "└",
        bottomRight: "┘",
        horizontal: "─",
        vertical: "│",
        leftT: "├",
        rightT: "┤"
    )

    /// Double line border (═ ║ ╔ ╗ ╚ ╝ ╠ ╣).
    ///
    /// ```
    /// ╔════════╗
    /// ║ Title  ║
    /// ╠════════╣
    /// ║ Content║
    /// ╚════════╝
    /// ```
    public static let doubleLine = Self(
        topLeft: "╔",
        topRight: "╗",
        bottomLeft: "╚",
        bottomRight: "╝",
        horizontal: "═",
        vertical: "║",
        leftT: "╠",
        rightT: "╣"
    )

    /// Rounded border with curved corners (─ │ ╭ ╮ ╰ ╯ ├ ┤).
    ///
    /// ```
    /// ╭────────╮
    /// │ Title  │
    /// ├────────┤
    /// │ Content│
    /// ╰────────╯
    /// ```
    public static let rounded = Self(
        topLeft: "╭",
        topRight: "╮",
        bottomLeft: "╰",
        bottomRight: "╯",
        horizontal: "─",
        vertical: "│",
        leftT: "├",
        rightT: "┤"
    )

    /// Heavy/bold border (━ ┃ ┏ ┓ ┗ ┛ ┣ ┫).
    ///
    /// ```
    /// ┏━━━━━━━━┓
    /// ┃ Title  ┃
    /// ┣━━━━━━━━┫
    /// ┃ Content┃
    /// ┗━━━━━━━━┛
    /// ```
    public static let heavy = Self(
        topLeft: "┏",
        topRight: "┓",
        bottomLeft: "┗",
        bottomRight: "┛",
        horizontal: "━",
        vertical: "┃",
        leftT: "┣",
        rightT: "┫"
    )

    /// Block/solid border using half-block characters for smooth edges.
    ///
    /// Uses ▄ (lower half) for top edge and ▀ (upper half) for bottom edge,
    /// creating a visually smooth container appearance.
    ///
    /// ```
    /// ▄▄▄▄▄▄▄▄▄▄  ← Top: lower half block
    /// █ Title  █  ← Sides: full block
    /// ▀▀▀▀▀▀▀▀▀▀  ← Header separator: upper half block
    /// █ Content█
    /// ▄▄▄▄▄▄▄▄▄▄  ← Footer separator: lower half block
    /// █ Footer █
    /// ▀▀▀▀▀▀▀▀▀▀  ← Bottom: upper half block
    /// ```
    public static let block = Self(
        topLeft: "▄",
        topRight: "▄",
        bottomLeft: "▀",
        bottomRight: "▀",
        horizontal: "▄",  // Top edge uses lower half
        vertical: "█",  // Sides use full block
        leftT: "▀",  // Header/Body separator (upper half)
        rightT: "▀"
    )

    /// The character used for the bottom edge of block style.
    ///
    /// Block style uses different characters for top (▄) and bottom (▀).
    public static let blockBottomHorizontal: Character = "▀"

    /// The character used for body/footer separator in block style.
    ///
    /// Uses lower half block (▄) to create visual separation.
    public static let blockFooterSeparator: Character = "▄"

    /// No visible border (space characters).
    public static let none = Self(
        topLeft: " ",
        topRight: " ",
        bottomLeft: " ",
        bottomRight: " ",
        horizontal: " ",
        vertical: " ",
        leftT: " ",
        rightT: " "
    )

    /// ASCII-only border (+ - |).
    ///
    /// Maximum compatibility with all terminals, including those that
    /// don't support Unicode box-drawing characters.
    ///
    /// ```
    /// +--------+
    /// | Title  |
    /// +--------+
    /// | Content|
    /// +--------+
    /// ```
    public static let ascii = Self(
        topLeft: "+",
        topRight: "+",
        bottomLeft: "+",
        bottomRight: "+",
        horizontal: "-",
        vertical: "|",
        leftT: "+",
        rightT: "+"
    )
}
