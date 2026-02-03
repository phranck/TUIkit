//
//  Button.swift
//  TUIkit
//
//  An interactive button view that responds to keyboard input.
//

import Foundation

// MARK: - Button Style

/// Defines the visual style of a button.
public struct ButtonStyle: Sendable {
    /// The foreground color for the label.
    ///
    /// Uses a semantic color reference so the actual value is resolved
    /// at render time from the active palette. Set to `nil` to use the
    /// palette's accent color.
    public var foregroundColor: Color?

    /// The background color (used in block appearance).
    public var backgroundColor: Color?

    /// Whether the label is bold.
    public var isBold: Bool

    /// Horizontal padding inside the button.
    public var horizontalPadding: Int

    /// Creates a button style.
    ///
    /// - Parameters:
    ///   - foregroundColor: The label color (default: theme accent).
    ///   - backgroundColor: The background color.
    ///   - isBold: Whether the label is bold.
    ///   - horizontalPadding: Horizontal padding inside the button.
    public init(
        foregroundColor: Color? = nil,
        backgroundColor: Color? = nil,
        isBold: Bool = false,
        horizontalPadding: Int = 1
    ) {
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
        self.isBold = isBold
        self.horizontalPadding = horizontalPadding
    }

    // MARK: - Preset Styles

    /// Default button style — palette border/accent, not bold.
    public static let `default` = Self()

    /// Primary button style — bold, uses palette accent.
    public static let primary = Self(
        isBold: true
    )

    /// Destructive button style — uses palette error color.
    public static let destructive = Self(
        foregroundColor: .palette.error
    )

    /// Success button style — uses palette success color.
    public static let success = Self(
        foregroundColor: .palette.success
    )

    /// Plain button style — no brackets, no border, no padding.
    public static let plain = Self(
        horizontalPadding: 0
    )
}

// MARK: - Button

/// An interactive button that triggers an action when pressed.
///
/// Buttons can receive focus and respond to keyboard input (Enter or Space).
/// They display differently when focused to indicate the current selection.
///
/// ## Rendering
///
/// - **Standard appearances** (line, rounded, doubleLine, heavy):
///   Rendered as single-line `[ Label ]` with bracket delimiters.
///
/// - **Block appearance**:
///   Rendered as single-line with elevated background color, no brackets.
///
/// - **Plain style**: No brackets, no background — just the label text.
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
public struct Button: View {
    /// The button's label text.
    let label: String

    /// The action to perform when pressed.
    let action: () -> Void

    /// The normal (unfocused) style.
    let style: ButtonStyle

    /// The focused style.
    let focusedStyle: ButtonStyle

    /// The unique focus identifier.
    let focusID: String

    /// Whether the button is disabled.
    let isDisabled: Bool

    /// Creates a button with a label and action.
    ///
    /// - Parameters:
    ///   - label: The button's label text.
    ///   - style: The button style (default: `.default`).
    ///   - focusedStyle: The style when focused (default: bold variant).
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

        // Default focused style: bold version of the normal style
        self.focusedStyle =
            focusedStyle
            ?? ButtonStyle(
                foregroundColor: style.foregroundColor,
                backgroundColor: style.backgroundColor,
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
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Get focus manager from environment
        let focusManager = context.environment.focusManager

        // Register this button with the focus manager
        let handler = ButtonHandler(
            focusID: focusID,
            action: action,
            canBeFocused: !isDisabled
        )
        focusManager.register(handler, inSection: context.activeFocusSectionID)

        // Determine if focused
        let isFocused = focusManager.isFocused(id: focusID)
        let currentStyle = isFocused ? focusedStyle : style
        let palette = context.environment.palette
        let isBlockAppearance = context.environment.appearance.rawId == .block
        let isPlainStyle = currentStyle.horizontalPadding == 0 && style.foregroundColor == nil && !style.isBold

        // Build the label with padding
        let padding = String(repeating: " ", count: currentStyle.horizontalPadding)
        let paddedLabel = padding + label + padding

        // Resolve foreground color
        let foregroundColor: Color
        if isDisabled {
            foregroundColor = palette.foregroundTertiary
        } else {
            foregroundColor = currentStyle.foregroundColor?.resolve(with: palette) ?? palette.accent
        }

        // Build text style
        var textStyle = TextStyle()
        textStyle.foregroundColor = foregroundColor
        textStyle.isBold = currentStyle.isBold && !isDisabled

        // Determine rendering mode
        if isPlainStyle {
            // Plain: just the label, no decoration
            let styledLabel = ANSIRenderer.render(paddedLabel, with: textStyle)
            return FrameBuffer(lines: [styledLabel])
        } else if isBlockAppearance {
            // Block: elevated background, no brackets
            textStyle.backgroundColor = currentStyle.backgroundColor?.resolve(with: palette)
                ?? palette.blockElevatedBackground
            let styledLabel = ANSIRenderer.render(paddedLabel, with: textStyle)
            return FrameBuffer(lines: [styledLabel])
        } else {
            // Standard appearances: single-line brackets [ Label ]
            let bracketColor: Color
            if isDisabled {
                bracketColor = palette.foregroundTertiary
            } else {
                bracketColor = palette.border
            }

            let openBracket = ANSIRenderer.colorize("[", foreground: bracketColor)
            let closeBracket = ANSIRenderer.colorize("]", foreground: bracketColor)
            let styledLabel = ANSIRenderer.render(paddedLabel, with: textStyle)

            let line = openBracket + styledLabel + closeBracket

            var buffer = FrameBuffer(lines: [line])

            // Add focus indicator if focused (but not for bold/primary buttons)
            if isFocused && !isDisabled && !currentStyle.isBold {
                buffer = addFocusIndicator(to: buffer, palette: palette)
            }

            return buffer
        }
    }

    /// Adds a focus indicator (▸) to the left of the button.
    private func addFocusIndicator(to buffer: FrameBuffer, palette: any Palette) -> FrameBuffer {
        guard buffer.height > 0 else { return buffer }

        let indicator = ANSIRenderer.render(
            "▸ ",
            with: {
                var indicatorStyle = TextStyle()
                indicatorStyle.foregroundColor = palette.accent
                indicatorStyle.isBold = true
                return indicatorStyle
            }()
        )

        var lines = buffer.lines
        lines[0] = indicator + lines[0]
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
