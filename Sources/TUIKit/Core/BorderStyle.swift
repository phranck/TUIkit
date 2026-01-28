//
//  BorderStyle.swift
//  TUIKit
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
    public static let line = BorderStyle(
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
    public static let doubleLine = BorderStyle(
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
    public static let rounded = BorderStyle(
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
    public static let heavy = BorderStyle(
        topLeft: "┏",
        topRight: "┓",
        bottomLeft: "┗",
        bottomRight: "┛",
        horizontal: "━",
        vertical: "┃",
        leftT: "┣",
        rightT: "┫"
    )

    /// Block/solid border using block characters (█).
    ///
    /// ```
    /// ██████████
    /// █ Title  █
    /// ██████████
    /// █ Content█
    /// ██████████
    /// ```
    public static let block = BorderStyle(
        topLeft: "█",
        topRight: "█",
        bottomLeft: "█",
        bottomRight: "█",
        horizontal: "█",
        vertical: "█",
        leftT: "█",
        rightT: "█"
    )

    /// No visible border (space characters).
    public static let none = BorderStyle(
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
    public static let ascii = BorderStyle(
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
