//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Toggle.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Toggle Style

/// Defines the visual style of a toggle component.
public enum ToggleStyle: Sendable {
    /// Slider style: `[●○]` when off, `[○●]` when on.
    case toggle

    /// Checkbox style: `[ ]` when off, `[x]` when on.
    case checkbox
}

// MARK: - Toggle

/// An interactive toggle component for boolean state.
///
/// Toggles can receive focus and respond to keyboard input (Space or Enter).
/// They display with a focus indicator when focused, matching the Button focus behavior.
///
/// ## Rendering
///
/// The toggle renders as `[focus●] [toggle/checkbox] label`, where the focus indicator
/// only appears when focused (pulsing accent dot).
///
/// # Basic Example
///
/// ```swift
/// @State var isEnabled = false
///
/// Toggle("Enable notifications", isOn: $isEnabled)
/// ```
///
/// # Checkbox Style
///
/// ```swift
/// Toggle("Dark mode", isOn: $darkMode, style: .checkbox)
/// ```
public struct Toggle: View {
    /// The binding to the toggle's boolean state.
    let isOn: Binding<Bool>

    /// The label text to display next to the toggle.
    let label: String

    /// The visual style of the toggle.
    let style: ToggleStyle

    /// The unique focus identifier.
    let focusID: String

    /// Whether the toggle is disabled.
    let isDisabled: Bool

    /// Creates a toggle with a string label and binding.
    ///
    /// - Parameters:
    ///   - title: The toggle's label text.
    ///   - isOn: A binding to the toggle's boolean state.
    ///   - style: The visual style (default: `.toggle`).
    ///   - focusID: The unique focus identifier (default: auto-generated).
    ///   - isDisabled: Whether the toggle is disabled (default: false).
    public init(
        _ title: String,
        isOn: Binding<Bool>,
        style: ToggleStyle = .toggle,
        focusID: String? = nil,
        isDisabled: Bool = false
    ) {
        self.isOn = isOn
        self.label = title
        self.style = style
        self.focusID = focusID ?? "toggle-\(title)"
        self.isDisabled = isDisabled
    }

    public var body: Never {
        fatalError("Toggle renders via Renderable")
    }
}

// MARK: - Toggle Handler

/// Internal handler class for toggle focus management and state updates.
final class ToggleHandler: Focusable {
    let focusID: String
    let isOn: Binding<Bool>
    var canBeFocused: Bool

    init(focusID: String, isOn: Binding<Bool>, canBeFocused: Bool) {
        self.focusID = focusID
        self.isOn = isOn
        self.canBeFocused = canBeFocused
    }
}

// MARK: - Key Event Handling

extension ToggleHandler {
    func handleKeyEvent(_ event: KeyEvent) -> Bool {
        // Toggle state on Space or Enter
        switch event.key {
        case .enter:
            isOn.wrappedValue.toggle()
            return true
        case .character(" "):
            isOn.wrappedValue.toggle()
            return true
        default:
            return false
        }
    }
}

// MARK: - Toggle Rendering

extension Toggle: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Register with focus manager
        let focusManager = context.environment.focusManager
        let handler = ToggleHandler(
            focusID: focusID,
            isOn: isOn,
            canBeFocused: !isDisabled
        )
        focusManager.register(handler, inSection: context.activeFocusSectionID)

        // Determine if focused
        let isFocused = focusManager.isFocused(id: focusID)
        let palette = context.environment.palette

        // Build the toggle content (indicator inside brackets)
        let indicatorContent: String
        switch style {
        case .toggle:
            indicatorContent = isOn.wrappedValue ? "●○" : "○●"
        case .checkbox:
            // U+25FE: Black medium square
            indicatorContent = isOn.wrappedValue ? "\u{25FE}" : " "
        }

        // Determine bracket color: pulsing accent when focused, border when unfocused
        let bracketColor: Color
        if isDisabled {
            bracketColor = palette.foregroundTertiary
        } else if isFocused {
            // Subtle pulse: interpolate between 35% and 100% accent
            let dimAccent = palette.accent.opacity(0.35)
            bracketColor = Color.lerp(dimAccent, palette.accent, phase: context.pulsePhase)
        } else {
            bracketColor = palette.border
        }

        // Render brackets with pulse, content without pulse
        let openBracket = ANSIRenderer.colorize("[", foreground: bracketColor, bold: isFocused && !isDisabled)
        let closeBracket = ANSIRenderer.colorize("]", foreground: bracketColor, bold: isFocused && !isDisabled)

        // Indicator color: accent if focused, foreground if not focused/disabled
        let indicatorColor: Color
        if isDisabled {
            indicatorColor = palette.foregroundTertiary
        } else if isFocused {
            indicatorColor = palette.accent
        } else {
            indicatorColor = palette.foregroundSecondary
        }
        let styledContent = ANSIRenderer.colorize(indicatorContent, foreground: indicatorColor)

        // Combine: [indicator] label
        let styledToggle = openBracket + styledContent + closeBracket
        let combinedLine = styledToggle + " " + label

        // Return frame buffer with the combined line
        return FrameBuffer(lines: [combinedLine])
    }
}

// MARK: - Toggle Convenience Modifiers

extension Toggle {
    /// Creates a disabled version of this toggle.
    ///
    /// - Parameter disabled: Whether the toggle is disabled.
    /// - Returns: A new toggle with the disabled state.
    public func disabled(_ disabled: Bool = true) -> Toggle {
        Toggle(
            label,
            isOn: isOn,
            style: style,
            focusID: focusID,
            isDisabled: disabled
        )
    }
}
