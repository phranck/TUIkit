//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Button.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Button Role

/// A value that describes the purpose of a button.
///
/// Use button roles to give buttons a semantic meaning that affects
/// their appearance and behavior. In alerts and dialogs, buttons are
/// automatically ordered based on their role.
///
/// - `cancel`: A button that cancels the current operation. Placed on the left.
/// - `destructive`: A button that deletes data or performs an irreversible action.
public struct ButtonRole: Equatable, Sendable {
    let rawValue: String

    private init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    /// A role that indicates a cancellation action.
    ///
    /// Cancel buttons are placed on the left side in alerts and dialogs.
    /// Pressing ESC triggers the cancel action if one exists.
    public static let cancel = Self("cancel")

    /// A role that indicates a destructive action.
    ///
    /// Destructive buttons are styled with the error color to indicate danger.
    /// Use for buttons that delete user data or perform irreversible operations.
    public static let destructive = Self("destructive")
}

// MARK: - Button Style

/// Defines the visual style of a button.
public struct ButtonStyle: Sendable {
    /// The foreground color for the label.
    ///
    /// Uses a semantic color reference so the actual value is resolved
    /// at render time from the active palette. Set to `nil` to use the
    /// palette's accent color.
    public var foregroundColor: Color?

    /// The background color (reserved for future use).
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

    /// Default button style — dimmed foreground, not bold.
    public static let `default` = Self(
        foregroundColor: .palette.foregroundSecondary
    )

    /// Primary button style — bold, uses palette accent.
    public static let primary = Self(
        foregroundColor: .palette.accent,
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

    /// The button's semantic role.
    ///
    /// Roles affect button ordering in alerts/dialogs and can trigger
    /// automatic styling. Cancel buttons appear on the left; destructive
    /// buttons use error coloring.
    let role: ButtonRole?

    /// The normal (unfocused) style.
    let style: ButtonStyle

    /// The focused style.
    let focusedStyle: ButtonStyle

    /// The unique focus identifier.
    ///
    /// If `nil`, automatically generated from the view's identity path.
    /// Use the `.focusID()` modifier to override.
    var focusID: String?

    /// Whether the button is disabled.
    var isDisabled: Bool

    /// Creates a button with a label and action.
    ///
    /// - Parameters:
    ///   - label: The button's label text.
    ///   - style: The button style (default: `.default`).
    ///   - focusedStyle: The style when focused (default: bold variant).
    ///   - isDisabled: Whether the button is disabled (default: false).
    ///   - action: The action to perform when pressed.
    public init(
        _ label: String,
        style: ButtonStyle = .default,
        focusedStyle: ButtonStyle? = nil,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.action = action
        self.role = nil
        self.style = style
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
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

    /// Creates a button with an optional role for semantic meaning.
    ///
    /// Use this initializer to create buttons with roles like `.cancel` or `.destructive`.
    /// The role affects button ordering in alerts and can influence styling.
    ///
    /// This matches the SwiftUI signature:
    /// `init(_ title: S, role: ButtonRole?, action: () -> Void)`
    ///
    /// - Parameters:
    ///   - label: The button's label text.
    ///   - role: An optional semantic role describing the button.
    ///   - action: The action to perform when pressed.
    public init(
        _ label: String,
        role: ButtonRole?,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.action = action
        self.role = role
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
        self.isDisabled = false

        // Style based on role
        switch role {
        case .destructive:
            self.style = .destructive
            self.focusedStyle = ButtonStyle(
                foregroundColor: .palette.error,
                isBold: true,
                horizontalPadding: 1
            )
        case .cancel:
            self.style = .default
            self.focusedStyle = ButtonStyle(
                foregroundColor: nil,
                isBold: true,
                horizontalPadding: 1
            )
        default:
            self.style = .default
            self.focusedStyle = ButtonStyle(isBold: true, horizontalPadding: 1)
        }
    }

    public var body: some View {
        _ButtonCore(
            label: label,
            action: action,
            role: role,
            style: style,
            focusedStyle: focusedStyle,
            focusID: focusID,
            isDisabled: isDisabled
        )
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of Button.
private struct _ButtonCore: View, Renderable {
    let label: String
    let action: () -> Void
    let role: ButtonRole?
    let style: ButtonStyle
    let focusedStyle: ButtonStyle
    let focusID: String?
    let isDisabled: Bool

    var body: Never {
        fatalError("_ButtonCore renders via Renderable")
    }

    private enum StateIndex {
        static let focusID = 0
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let persistedFocusID = FocusRegistration.persistFocusID(
            context: context,
            explicitFocusID: focusID,
            defaultPrefix: "button",
            propertyIndex: StateIndex.focusID
        )
        let handler = ActionHandler(
            focusID: persistedFocusID,
            action: action,
            canBeFocused: !isDisabled
        )
        FocusRegistration.register(context: context, handler: handler)
        let isFocused = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)
        let currentStyle = isFocused ? focusedStyle : style
        let palette = context.environment.palette
        let isPlainStyle = currentStyle.horizontalPadding == 0 && style.foregroundColor == nil && !style.isBold

        // Build the label with padding
        let padding = String(repeating: " ", count: currentStyle.horizontalPadding)
        let paddedLabel = padding + label + padding

        // Resolve foreground color
        let foregroundColor: Color
        if isDisabled {
            // Use tertiary at 50% opacity for clearly disabled appearance
            foregroundColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
        } else {
            foregroundColor = currentStyle.foregroundColor?.resolve(with: palette) ?? palette.accent
        }

        // Build text style
        var textStyle = TextStyle()
        textStyle.foregroundColor = foregroundColor
        textStyle.isBold = currentStyle.isBold && !isDisabled

        // Determine rendering mode
        if isPlainStyle {
            // Plain: pulsing dot prefix + label, no brackets
            let focusPrefix = BorderRenderer.focusIndicatorPrefix(
                isFocused: isFocused && !isDisabled,
                pulsePhase: context.environment.pulsePhase,
                palette: palette
            )
            let styledLabel = ANSIRenderer.render(paddedLabel, with: textStyle)
            let fullLine = focusPrefix + styledLabel
            return FrameBuffer(lines: [fullLine])
        } else {
            // Standard: half-block caps with accent-tinted background
            let buttonBg = palette.accent.opacity(ViewConstants.focusBorderDim)

            // Label foreground: primary = accent/highlight, others = dimmed foreground
            let labelFg: Color
            if isDisabled {
                labelFg = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
            } else if currentStyle.isBold {
                labelFg = currentStyle.foregroundColor?.resolve(with: palette) ?? palette.accent
            } else {
                labelFg = palette.foregroundSecondary
            }

            // Caps: match button background normally, pulse to accent when focused
            let resolvedCapColor: Color
            if isDisabled {
                resolvedCapColor = buttonBg
            } else if isFocused {
                resolvedCapColor = Color.lerp(buttonBg, palette.accent.opacity(ViewConstants.buttonCapPulseBright), phase: context.environment.pulsePhase)
            } else {
                resolvedCapColor = buttonBg
            }

            let openCap = ANSIRenderer.colorize(String(TerminalSymbols.openCap), foreground: resolvedCapColor)
            let closeCap = ANSIRenderer.colorize(String(TerminalSymbols.closeCap), foreground: resolvedCapColor)
            let styledLabel = ANSIRenderer.colorize(
                paddedLabel,
                foreground: labelFg,
                background: buttonBg,
                bold: currentStyle.isBold && !isDisabled
            )

            let line = openCap + styledLabel + closeCap
            return FrameBuffer(lines: [line])
        }
    }
}

// MARK: - Button Convenience Modifiers

extension Button {
    /// Creates a disabled version of this button.
    ///
    /// - Parameter disabled: Whether the button is disabled.
    /// - Returns: A new button with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Button {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    /// Sets a custom focus identifier for this button.
    ///
    /// - Parameter id: The unique focus identifier.
    /// - Returns: A button with the specified focus identifier.
    public func focusID(_ id: String) -> Button {
        var copy = self
        copy.focusID = id
        return copy
    }
}
