//  TUIKit - Terminal UI Kit for Swift
//  Toggle.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - ToggleStyle Protocol

/// The appearance and behavior of a toggle.
///
/// To configure the style for a single `Toggle` or for all toggle instances
/// in a view hierarchy, use the `toggleStyle(_:)` modifier.
///
/// ## Built-in Styles
///
/// | Style | Description |
/// |-------|-------------|
/// | `.automatic` | Platform default (checkbox in TUI) |
/// | `.checkbox` | Classic checkbox: `[ ]` / `[x]` |
/// | `.switch` | Switch style (renders same as checkbox in TUI) |
///
/// > Note: In TUIkit, all styles render identically as `[ ]` / `[x]`
/// > due to terminal constraints. The API matches SwiftUI for compatibility.
public protocol ToggleStyle: Sendable {}

// MARK: - Built-in Toggle Styles

/// The default toggle style.
///
/// In TUIkit, the default style is checkbox: `[ ]` / `[x]`.
public struct DefaultToggleStyle: ToggleStyle {
    public init() {}
}

/// A toggle style that displays a checkbox followed by its label.
///
/// ```
/// [ ] Label     (OFF)
/// [x] Label     (ON)
/// ```
public struct CheckboxToggleStyle: ToggleStyle {
    public init() {}
}

/// A toggle style that displays a leading label and a trailing switch.
///
/// > Note: In TUIkit, this renders identically to `CheckboxToggleStyle`
/// > due to terminal constraints. The API exists for SwiftUI compatibility.
public struct SwitchToggleStyle: ToggleStyle {
    public init() {}
}

// MARK: - ToggleStyle Static Extensions

extension ToggleStyle where Self == DefaultToggleStyle {
    /// The default toggle style.
    public static var automatic: DefaultToggleStyle { DefaultToggleStyle() }
}

extension ToggleStyle where Self == CheckboxToggleStyle {
    /// A toggle style that displays a checkbox followed by its label.
    public static var checkbox: CheckboxToggleStyle { CheckboxToggleStyle() }
}

extension ToggleStyle where Self == SwitchToggleStyle {
    /// A toggle style that displays a leading label and a trailing switch.
    ///
    /// > Note: In TUIkit, this renders identically to checkbox style.
    public static var `switch`: SwitchToggleStyle { SwitchToggleStyle() }
}

// MARK: - Environment Key

/// Environment key for toggle style.
private struct ToggleStyleKey: EnvironmentKey {
    static let defaultValue: any ToggleStyle = DefaultToggleStyle()
}

extension EnvironmentValues {
    /// The toggle style for this environment.
    public var toggleStyle: any ToggleStyle {
        get { self[ToggleStyleKey.self] }
        set { self[ToggleStyleKey.self] = newValue }
    }
}

// MARK: - Toggle Style Modifier

extension View {
    /// Sets the style for toggles within this view.
    ///
    /// Use this modifier to set a specific style for all toggles within a view:
    ///
    /// ```swift
    /// VStack {
    ///     Toggle("Option 1", isOn: $option1)
    ///     Toggle("Option 2", isOn: $option2)
    /// }
    /// .toggleStyle(.checkbox)
    /// ```
    ///
    /// > Note: In TUIkit, all styles currently render as checkbox `[ ]` / `[x]`.
    ///
    /// - Parameter style: The toggle style to use.
    /// - Returns: A view with the toggle style set.
    public func toggleStyle<S: ToggleStyle>(_ style: S) -> some View {
        environment(\.toggleStyle, style)
    }
}

// MARK: - Toggle

/// A control that toggles between on and off states.
///
/// You create a toggle by providing an `isOn` binding and a label:
///
/// ```swift
/// @State private var isEnabled = false
///
/// Toggle("Enable notifications", isOn: $isEnabled)
/// ```
///
/// ## Rendering
///
/// ```
/// [ ] Label     (OFF - dimmed)
/// [x] Label     (ON - accent color)
/// ```
///
/// When focused, the brackets pulse in the accent color.
///
/// ## Styling
///
/// Use the `toggleStyle(_:)` modifier to customize appearance:
///
/// ```swift
/// Toggle("Option", isOn: $isOn)
///     .toggleStyle(.checkbox)
/// ```
///
/// Available styles: `.automatic`, `.checkbox`, `.switch`
///
/// > Note: In TUIkit, all styles currently render identically as checkbox
/// > due to terminal constraints.
public struct Toggle<Label: View>: View {
    /// The binding to the toggle's boolean state.
    let isOn: Binding<Bool>

    /// The label view.
    let label: Label

    /// The unique focus identifier.
    var focusID: String?

    /// Whether the toggle is disabled.
    var isDisabled: Bool

    public var body: some View {
        _ToggleCore(
            isOn: isOn,
            label: label,
            focusID: focusID,
            isDisabled: isDisabled
        )
    }
}

// MARK: - Toggle Initializers (String Label)

extension Toggle where Label == Text {
    /// Creates a toggle with a string label.
    ///
    /// - Parameters:
    ///   - title: The toggle's label text.
    ///   - isOn: A binding to the toggle's boolean state.
    public init<S: StringProtocol>(
        _ title: S,
        isOn: Binding<Bool>
    ) {
        self.isOn = isOn
        self.label = Text(String(title))
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
        self.isDisabled = false
    }
}

// MARK: - Toggle Initializers (ViewBuilder Label)

extension Toggle {
    /// Creates a toggle with a custom label.
    ///
    /// - Parameters:
    ///   - isOn: A binding to the toggle's boolean state.
    ///   - label: A view that describes the purpose of the toggle.
    public init(
        isOn: Binding<Bool>,
        @ViewBuilder label: () -> Label
    ) {
        self.isOn = isOn
        self.label = label()
        self.focusID = nil
        self.isDisabled = false
    }
}

// MARK: - Toggle Modifiers

extension Toggle {
    /// Creates a disabled version of this toggle.
    ///
    /// - Parameter disabled: Whether the toggle is disabled.
    /// - Returns: A new toggle with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Toggle {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    /// Sets a custom focus identifier for this toggle.
    ///
    /// - Parameter id: The unique focus identifier.
    /// - Returns: A toggle with the specified focus identifier.
    public func focusID(_ id: String) -> Toggle {
        var copy = self
        copy.focusID = id
        return copy
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of Toggle.
private struct _ToggleCore<Label: View>: View, Renderable {
    let isOn: Binding<Bool>
    let label: Label
    let focusID: String?
    let isDisabled: Bool

    var body: Never {
        fatalError("_ToggleCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let palette = context.environment.palette

        let persistedFocusID = FocusRegistration.persistFocusID(
            context: context,
            explicitFocusID: focusID,
            defaultPrefix: "toggle",
            propertyIndex: 0  // focusID
        )
        let binding = isOn
        let handler = ActionHandler(
            focusID: persistedFocusID,
            action: { binding.wrappedValue.toggle() },
            canBeFocused: !isDisabled
        )
        FocusRegistration.register(context: context, handler: handler)
        let isFocused = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)
        let isOnValue = isOn.wrappedValue

        // Render the label to get its text
        let labelBuffer = TUIkit.renderToBuffer(label, context: context)
        let labelText = labelBuffer.lines.joined(separator: " ").stripped

        // Bracket color: pulsing accent when focused, dimmed otherwise
        let bracketColor: Color
        if isDisabled {
            bracketColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
        } else if isFocused {
            let dimAccent = palette.accent.opacity(ViewConstants.focusPulseMin)
            bracketColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
        } else {
            bracketColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
        }

        let openBracket = ANSIRenderer.colorize("[", foreground: bracketColor)
        let closeBracket = ANSIRenderer.colorize("]", foreground: bracketColor)

        // Content: [ ] (OFF) or [x] (ON)
        let contentColor: Color
        if isDisabled {
            contentColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
        } else if isOnValue {
            contentColor = palette.accent
        } else {
            contentColor = palette.foregroundTertiary.opacity(ViewConstants.disabledForeground)
        }

        let content = isOnValue ? "x" : " "
        let styledContent = ANSIRenderer.colorize(content, foreground: contentColor)
        let styledIndicator = openBracket + styledContent + closeBracket

        // Combine: [indicator] label
        let combinedLine = styledIndicator + " " + labelText

        return FrameBuffer(lines: [combinedLine])
    }
}
