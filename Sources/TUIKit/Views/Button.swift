//
//  Button.swift
//  TUIKit
//
//  An interactive button view that responds to keyboard input.
//

import Foundation

// MARK: - Button Style

/// Defines the visual style of a button.
public struct ButtonStyle: Sendable {
    /// The foreground color for the label.
    public var foregroundColor: Color?

    /// The background color.
    public var backgroundColor: Color?

    /// The border style.
    public var borderStyle: BorderStyle?

    /// The border color.
    public var borderColor: Color?

    /// Whether the label is bold.
    public var isBold: Bool

    /// Horizontal padding inside the button.
    public var horizontalPadding: Int

    /// Creates a button style.
    ///
    /// - Parameters:
    ///   - foregroundColor: The label color (default: theme accent).
    ///   - backgroundColor: The background color.
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - isBold: Whether the label is bold.
    ///   - horizontalPadding: Horizontal padding inside the button.
    public init(
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        isBold: Bool = false,
        horizontalPadding: Int = 2
    ) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.isBold = isBold
        self.horizontalPadding = horizontalPadding
    }

    // MARK: - Preset Styles

    /// Default button style with border.
    public static let `default` = Self()

    /// Primary button style (cyan, bold).
    public static let primary = Self(
        foregroundColor: .cyan,
        borderColor: .cyan,
        isBold: true
    )

    /// Destructive button style (red).
    public static let destructive = Self(
        foregroundColor: .red,
        borderColor: .red
    )

    /// Success button style (green).
    public static let success = Self(
        foregroundColor: .green,
        borderColor: .green
    )

    /// Plain button style (no border).
    public static let plain = Self(
        borderStyle: BorderStyle.none,
        horizontalPadding: 0
    )
}

// MARK: - Button

/// An interactive button that triggers an action when pressed.
///
/// Buttons can receive focus and respond to keyboard input (Enter or Space).
/// They display differently when focused to indicate the current selection.
///
/// # Basic Example
///
/// ```swift
/// Button("Submit") {
///     handleSubmit()
/// }
/// ```
///
/// # Styled Button
///
/// ```swift
/// Button("Delete", style: .destructive) {
///     handleDelete()
/// }
/// ```
///
/// # Custom Focus ID
///
/// ```swift
/// Button("OK", focusID: "okButton") {
///     dismiss()
/// }
/// ```
public struct Button: View {
    /// The button's label text.
    public let label: String

    /// The action to perform when pressed.
    public let action: () -> Void

    /// The normal (unfocused) style.
    public let style: ButtonStyle

    /// The focused style.
    public let focusedStyle: ButtonStyle

    /// The unique focus identifier.
    public let focusID: String

    /// Whether the button is disabled.
    public let isDisabled: Bool

    /// Creates a button with a label and action.
    ///
    /// - Parameters:
    ///   - label: The button's label text.
    ///   - style: The button style (default: `.default`).
    ///   - focusedStyle: The style when focused (default: inverted colors).
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - isDisabled: Whether the button is disabled (default: false).
    ///   - action: The action to perform when pressed.
    public init(
        _ label: String,
        style: ButtonStyle = .default,
        focusedStyle: ButtonStyle? = nil,
        focusID: String = UUID().uuidString,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.action = action
        self.style = style
        self.focusID = focusID
        self.isDisabled = isDisabled

        // Default focused style: use theme accent color, bold
        // Note: Theme colors are resolved at render time via Color.theme
        self.focusedStyle =
            focusedStyle
            ?? ButtonStyle(
                foregroundColor: nil,  // Will use theme.accent at render time
                backgroundColor: style.backgroundColor,
                borderStyle: style.borderStyle,
                borderColor: nil,  // Will use theme.borderFocused at render time
                isBold: true,
                horizontalPadding: style.horizontalPadding
            )
    }

    public var body: Never {
        fatalError("Button renders via Renderable")
    }
}

// MARK: - Button Handler

/// Internal handler class for button focus management.
final class ButtonHandler: Focusable {
    let focusID: String
    let action: () -> Void
    var canBeFocused: Bool

    init(focusID: String, action: @escaping () -> Void, canBeFocused: Bool) {
        self.focusID = focusID
        self.action = action
        self.canBeFocused = canBeFocused
    }

    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        // Trigger action on Enter or Space
        switch event.key {
        case .enter:
            action()
            return true
        case .character(" "):
            action()
            return true
        default:
            return false
        }
    }
}

// MARK: - Button Rendering

extension Button: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Get focus manager from environment
        let focusManager = context.environment.focusManager

        // Register this button with the focus manager
        let handler = ButtonHandler(
            focusID: focusID,
            action: action,
            canBeFocused: !isDisabled
        )
        focusManager.register(handler)

        // Determine if focused
        let isFocused = focusManager.isFocused(id: focusID)
        let currentStyle = isFocused ? focusedStyle : style

        // Build the label with padding
        let padding = String(repeating: " ", count: currentStyle.horizontalPadding)
        let paddedLabel = padding + label + padding

        // Apply text styling
        var textStyle = TextStyle()
        if isDisabled {
            textStyle.foregroundColor = Color.theme.disabled
        } else {
            // Use theme accent if no explicit color is set
            textStyle.foregroundColor = currentStyle.foregroundColor ?? Color.theme.accent
        }
        textStyle.backgroundColor = currentStyle.backgroundColor
        textStyle.isBold = currentStyle.isBold && !isDisabled

        // In block appearance, add buttonBackground to button
        let isBlockAppearance = context.environment.appearance.rawId == .block
        if isBlockAppearance && textStyle.backgroundColor == nil {
            textStyle.backgroundColor = context.environment.palette.buttonBackground
        }

        let styledLabel = ANSIRenderer.render(paddedLabel, with: textStyle)

        // Create content buffer
        var buffer = FrameBuffer(lines: [styledLabel])

        // Apply border if specified
        // Note: ButtonStyle.plain explicitly sets borderStyle to .none for no border
        if let borderStyle = currentStyle.borderStyle {
            // Skip if it's the "none" style (invisible border)
            if borderStyle != .none {
                let borderColor: Color
                if isDisabled {
                    borderColor = Color.theme.disabled
                } else {
                    borderColor = currentStyle.borderColor ?? Color.theme.border
                }
                buffer = applyBorder(
                    to: buffer,
                    style: borderStyle,
                    color: borderColor,
                    context: context
                )
            }
        } else {
            // nil means use appearance default, but skip border for block appearance
            if !isBlockAppearance {
                let effectiveBorderStyle = context.environment.appearance.borderStyle
                let borderColor: Color
                if isDisabled {
                    borderColor = Color.theme.disabled
                } else {
                    borderColor = currentStyle.borderColor ?? Color.theme.border
                }
                buffer = applyBorder(
                    to: buffer,
                    style: effectiveBorderStyle,
                    color: borderColor,
                    context: context
                )
            }
        }

        // Add focus indicator if focused (but not for primary/bold buttons)
        if isFocused && !isDisabled && !currentStyle.isBold {
            buffer = addFocusIndicator(to: buffer)
        }

        return buffer
    }

    /// Applies a border to the buffer.
    private func applyBorder(to buffer: FrameBuffer, style: BorderStyle, color: Color, context: RenderContext) -> FrameBuffer {
        guard !buffer.isEmpty else { return buffer }

        let innerWidth = buffer.width
        var result: [String] = []

        result.append(BorderRenderer.standardTopBorder(style: style, innerWidth: innerWidth, color: color))
        for line in buffer.lines {
            result.append(
                BorderRenderer.standardContentLine(
                    content: line,
                    innerWidth: innerWidth,
                    style: style,
                    color: color
                )
            )
        }
        result.append(BorderRenderer.standardBottomBorder(style: style, innerWidth: innerWidth, color: color))

        return FrameBuffer(lines: result)
    }

    /// Adds a focus indicator (▸) to the left of the button.
    private func addFocusIndicator(to buffer: FrameBuffer) -> FrameBuffer {
        guard buffer.height > 0 else { return buffer }

        var lines = buffer.lines

        // Add indicator on the middle line (or first line if single line)
        let middleIndex = buffer.height / 2
        let indicator = ANSIRenderer.render(
            "▸ ",
            with: {
                var style = TextStyle()
                style.foregroundColor = Color.theme.accent
                style.isBold = true
                return style
            }()
        )

        // Prepend indicator to the middle line, pad other lines
        for index in 0..<lines.count {
            if index == middleIndex {
                lines[index] = indicator + lines[index]
            } else {
                lines[index] = "  " + lines[index]
            }
        }

        return FrameBuffer(lines: lines)
    }
}

// MARK: - Button Convenience Modifiers

extension Button {
    /// Creates a disabled version of this button.
    ///
    /// - Parameter disabled: Whether the button is disabled.
    /// - Returns: A new button with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Button {
        Button(
            label,
            style: style,
            focusedStyle: focusedStyle,
            focusID: focusID,
            isDisabled: disabled,
            action: action
        )
    }
}

// MARK: - Button Row Helper

/// A horizontal row of buttons.
///
/// Use this to display multiple buttons side by side with consistent spacing.
///
/// # Example
///
/// ```swift
/// ButtonRow {
///     Button("Cancel", style: .plain) { dismiss() }
///     Button("OK", style: .primary) { confirm() }
/// }
/// ```
public struct ButtonRow: View {
    private let buttons: [Button]
    private let spacing: Int

    /// Creates a button row.
    ///
    /// - Parameters:
    ///   - spacing: The horizontal spacing between buttons (default: 2).
    ///   - buttons: The buttons to display.
    public init(spacing: Int = 2, @ButtonRowBuilder _ buttons: () -> [Button]) {
        self.spacing = spacing
        self.buttons = buttons()
    }

    public var body: Never {
        fatalError("ButtonRow renders via Renderable")
    }
}

// MARK: - ButtonRow Builder

/// Result builder for creating button rows.
@resultBuilder
public struct ButtonRowBuilder {
    /// Combines multiple buttons into a single array.
    public static func buildBlock(_ buttons: Button...) -> [Button] {
        buttons
    }

    /// Combines an array of button arrays (from `for` loops).
    public static func buildArray(_ components: [[Button]]) -> [Button] {
        components.flatMap { $0 }
    }

    /// Handles optional button arrays (from `if` without `else`).
    public static func buildOptional(_ component: [Button]?) -> [Button] {
        component ?? []
    }

    /// Handles the first branch of an `if`/`else`.
    public static func buildEither(first component: [Button]) -> [Button] {
        component
    }

    /// Handles the second branch of an `if`/`else`.
    public static func buildEither(second component: [Button]) -> [Button] {
        component
    }
}

// MARK: - ButtonRow Rendering

extension ButtonRow: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard !buttons.isEmpty else {
            return FrameBuffer(lines: [])
        }

        // Render each button
        var buttonBuffers: [FrameBuffer] = []
        for button in buttons {
            let buffer = TUIKit.renderToBuffer(button, context: context)
            buttonBuffers.append(buffer)
        }

        // Find the maximum height
        let maxHeight = buttonBuffers.map { $0.height }.max() ?? 0

        // Calculate total width needed (buttons + spacing)
        let totalButtonWidth = buttonBuffers.reduce(0) { $0 + $1.width }
        let totalSpacingWidth = max(0, buttonBuffers.count - 1) * spacing
        let totalNeededWidth = totalButtonWidth + totalSpacingWidth

        // Available width from context
        let availableWidth = context.availableWidth

        // Right-align: calculate left padding
        let leftPadding = max(0, availableWidth - totalNeededWidth)

        // Combine horizontally (right-aligned)
        var resultLines: [String] = Array(repeating: "", count: maxHeight)
        let spacer = String(repeating: " ", count: spacing)

        for lineIndex in 0..<maxHeight {
            // Add left padding
            resultLines[lineIndex] = String(repeating: " ", count: leftPadding)

            // Add buttons
            for (index, buffer) in buttonBuffers.enumerated() {
                let buttonWidth = buffer.width

                if index > 0 {
                    resultLines[lineIndex] += spacer
                }

                if lineIndex < buffer.height {
                    resultLines[lineIndex] += buffer.lines[lineIndex]
                } else {
                    // Pad with spaces if this button is shorter
                    resultLines[lineIndex] += String(repeating: " ", count: buttonWidth)
                }
            }
        }

        return FrameBuffer(lines: resultLines)
    }
}
