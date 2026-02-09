//  TUIKit - Terminal UI Kit for Swift
//  SecureField.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - SecureField

/// A control for secure text entry, where the display masks the user's input.
///
/// Use `SecureField` when you need to collect sensitive data like passwords.
/// The field behaves identically to `TextField` but displays bullet characters
/// (●) instead of the actual text.
///
/// ## Rendering
///
/// The secure field renders masked text with a visible cursor when focused.
/// When empty and unfocused, it displays the prompt text in dim styling.
///
/// ```
/// Unfocused, empty:     Enter password...       (prompt in dim)
/// Unfocused, with text: ●●●●●●●●                (bullets)
/// Focused, empty:       ❙ █                   ❙ (cursor, bars pulse)
/// Focused, with text:   ❙ ●●●●█●●●            ❙ (bullets + cursor)
/// ```
///
/// ## Keyboard Controls
///
/// | Key | Action |
/// |-----|--------|
/// | Any printable | Insert character at cursor |
/// | Backspace | Delete character before cursor |
/// | Delete | Delete character at cursor |
/// | Left | Move cursor left |
/// | Right | Move cursor right |
/// | Home | Move cursor to start |
/// | End | Move cursor to end |
/// | Enter | Trigger onSubmit action |
///
/// # Basic Example
///
/// ```swift
/// @State var password = ""
///
/// SecureField("Password", text: $password)
/// ```
///
/// # With Prompt
///
/// ```swift
/// SecureField("Password", text: $password, prompt: Text("Required"))
/// ```
///
/// # With Submit Action
///
/// ```swift
/// SecureField("Password", text: $password)
///     .onSubmit {
///         authenticate()
///     }
/// ```
public struct SecureField: View {
    /// The title describing the field's purpose.
    let title: String

    /// The binding to the text content.
    let text: Binding<String>

    /// Optional prompt text shown when the field is empty.
    let prompt: Text?

    /// The unique focus identifier.
    let focusID: String

    /// Whether the secure field is disabled.
    let isDisabled: Bool

    /// Action to perform when the user submits (presses Enter).
    let onSubmitAction: (() -> Void)?

    public var body: some View {
        _SecureFieldCore(
            text: text,
            prompt: prompt,
            focusID: focusID,
            isDisabled: isDisabled,
            onSubmitAction: onSubmitAction
        )
    }
}

// MARK: - SecureField Initializers

extension SecureField {
    /// Creates a secure field with a text label generated from a title string.
    ///
    /// - Parameters:
    ///   - title: The title of the secure field, describing its purpose.
    ///   - text: The text to display and edit.
    public init(_ title: String, text: Binding<String>) {
        self.title = title
        self.text = text
        self.prompt = nil
        self.focusID = "securefield-\(title)"
        self.isDisabled = false
        self.onSubmitAction = nil
    }

    /// Creates a secure field with a prompt.
    ///
    /// - Parameters:
    ///   - title: The title of the secure field, describing its purpose.
    ///   - text: The text to display and edit.
    ///   - prompt: A Text representing the prompt which provides users with
    ///     guidance on what to type into the secure field.
    public init(_ title: String, text: Binding<String>, prompt: Text?) {
        self.title = title
        self.text = text
        self.prompt = prompt
        self.focusID = "securefield-\(title)"
        self.isDisabled = false
        self.onSubmitAction = nil
    }
}

// MARK: - SecureField Modifiers

extension SecureField {
    /// Creates a disabled version of this secure field.
    ///
    /// - Parameter disabled: Whether the secure field is disabled.
    /// - Returns: A new secure field with the disabled state.
    public func disabled(_ disabled: Bool = true) -> SecureField {
        SecureField(
            title: title,
            text: text,
            prompt: prompt,
            focusID: focusID,
            isDisabled: disabled,
            onSubmitAction: onSubmitAction
        )
    }

    /// Adds an action to perform when the user submits (presses Enter).
    ///
    /// Use this modifier to invoke an action when the user presses Enter
    /// while the secure field has focus.
    ///
    /// # Example
    ///
    /// ```swift
    /// SecureField("Password", text: $password)
    ///     .onSubmit {
    ///         authenticate()
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform on submit.
    /// - Returns: A secure field that performs the action on submit.
    public func onSubmit(_ action: @escaping () -> Void) -> SecureField {
        SecureField(
            title: title,
            text: text,
            prompt: prompt,
            focusID: focusID,
            isDisabled: isDisabled,
            onSubmitAction: action
        )
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of SecureField.
private struct _SecureFieldCore: View, Renderable {
    let text: Binding<String>
    let prompt: Text?
    let focusID: String
    let isDisabled: Bool
    let onSubmitAction: (() -> Void)?

    /// The cursor character shown when focused.
    private let cursorChar: Character = "█"

    /// The masking character for password display (U+25CF Black Circle).
    private let maskChar: Character = "●"

    /// Default visible width for the secure field content area.
    private let defaultContentWidth = 20

    var body: Never {
        fatalError("_SecureFieldCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        let stateStorage = context.tuiContext.stateStorage
        let palette = context.environment.palette

        // Determine content width: use available width if explicit frame set, otherwise default
        // Account for focus indicators (2 chars for ❙ on each side)
        let contentWidth: Int
        if context.hasExplicitWidth && context.availableWidth > 2 {
            contentWidth = context.availableWidth - 2  // Subtract space for focus indicators
        } else {
            contentWidth = defaultContentWidth
        }

        // Get or create persistent focusID from state storage.
        // focusID must be stable across renders for focus state to persist.
        let focusIDKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 1)
        let focusIDBox: StateBox<String> = stateStorage.storage(
            for: focusIDKey,
            default: focusID
        )
        let persistedFocusID = focusIDBox.value

        // Get or create persistent handler from state storage.
        // The handler maintains cursor position across renders.
        // Reuse TextFieldHandler since key handling is identical.
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let handlerBox: StateBox<TextFieldHandler> = stateStorage.storage(
            for: handlerKey,
            default: TextFieldHandler(
                focusID: persistedFocusID,
                text: text,
                canBeFocused: !isDisabled
            )
        )
        let handler = handlerBox.value

        // Keep handler in sync with current values
        handler.text = text
        handler.canBeFocused = !isDisabled
        handler.onSubmit = onSubmitAction
        handler.clampCursorPosition()

        // Register with focus manager
        focusManager.register(handler, inSection: context.activeFocusSectionID)
        stateStorage.markActive(context.identity)

        // Determine focus state
        let isFocused = focusManager.isFocused(id: persistedFocusID)

        // Build the secure field content
        let content = buildContent(
            handler: handler,
            isFocused: isFocused,
            palette: palette,
            pulsePhase: context.pulsePhase,
            contentWidth: contentWidth
        )

        return FrameBuffer(text: content)
    }

    /// Builds the rendered secure field content.
    private func buildContent(
        handler: TextFieldHandler,
        isFocused: Bool,
        palette: any Palette,
        pulsePhase: Double,
        contentWidth: Int
    ) -> String {
        let textValue = text.wrappedValue
        let isEmpty = textValue.isEmpty
        let backgroundColor = palette.focusBackground

        // Build inner content with background
        let innerContent: String
        if isEmpty && !isFocused && prompt != nil {
            // Show prompt when empty and unfocused
            innerContent = buildPromptContent(palette: palette, background: backgroundColor, width: contentWidth)
        } else if isFocused {
            // Show masked text with cursor (scrolling if needed)
            innerContent = buildMaskedTextWithCursor(
                textLength: textValue.count,
                cursorPosition: handler.cursorPosition,
                selectionRange: handler.selectionRange,
                palette: palette,
                background: backgroundColor,
                width: contentWidth
            )
        } else {
            // Show masked text without cursor (scrolling if needed)
            innerContent = buildMaskedTextContent(
                textLength: textValue.count,
                palette: palette,
                background: backgroundColor,
                width: contentWidth
            )
        }

        // Add medium vertical bars when focused (outside the content area)
        if isFocused && !isDisabled {
            // Pulse between 35% and 100% accent
            let dimAccent = palette.accent.opacity(0.35)
            let accentColor = Color.lerp(dimAccent, palette.accent, phase: pulsePhase)

            let bar = ANSIRenderer.colorize("❙", foreground: accentColor)
            return "\(bar)\(innerContent)\(bar)"
        }

        // Unfocused: add space placeholders to maintain alignment
        return " \(innerContent) "
    }

    /// Builds the prompt content (shown when empty and unfocused).
    private func buildPromptContent(palette: any Palette, background: Color, width: Int) -> String {
        let promptText: String
        if let prompt {
            let buffer = TUIkit.renderToBuffer(prompt, context: RenderContext(availableWidth: 100, availableHeight: 1))
            promptText = buffer.lines.first?.stripped ?? ""
        } else {
            promptText = ""
        }
        // Truncate or pad prompt to exact width
        let truncated = String(promptText.prefix(width))
        let paddedPrompt = truncated.padding(toLength: width, withPad: " ", startingAt: 0)
        return ANSIRenderer.colorize(paddedPrompt, foreground: palette.foregroundTertiary, background: background)
    }

    /// Builds masked text content without cursor (unfocused state).
    private func buildMaskedTextContent(textLength: Int, palette: any Palette, background: Color, width: Int) -> String {
        // Show bullets from the beginning, truncated to width
        let bulletCount = min(textLength, width)
        let maskedText = String(repeating: maskChar, count: bulletCount)
        let paddedText = maskedText.padding(toLength: width, withPad: " ", startingAt: 0)
        let foreground = isDisabled ? palette.foregroundTertiary : palette.foreground
        return ANSIRenderer.colorize(paddedText, foreground: foreground, background: background)
    }

    /// Builds masked text content with cursor at the specified position (focused state).
    /// Implements horizontal scrolling to keep cursor visible.
    /// Selection is highlighted with accent background if present.
    private func buildMaskedTextWithCursor(
        textLength: Int,
        cursorPosition: Int,
        selectionRange: Range<Int>?,
        palette: any Palette,
        background: Color,
        width: Int
    ) -> String {
        let clampedPosition = max(0, min(cursorPosition, textLength))

        // Calculate scroll offset to keep cursor visible
        // The cursor needs 1 character, so visible text area is (width - 1)
        let visibleTextWidth = width - 1  // Reserve 1 char for cursor
        let scrollOffset: Int
        if clampedPosition <= visibleTextWidth {
            // Cursor fits without scrolling
            scrollOffset = 0
        } else {
            // Scroll so cursor is at the right edge
            scrollOffset = clampedPosition - visibleTextWidth
        }

        // The visible window in the text
        let visibleStart = scrollOffset

        // Build output character by character
        var result = ""
        var outputWidth = 0

        for visibleIndex in 0..<width {
            let textIndex = visibleStart + visibleIndex

            if textIndex == clampedPosition {
                // Render cursor
                result += ANSIRenderer.colorize(String(cursorChar), foreground: palette.accent, background: background)
                outputWidth += 1
            } else if textIndex < textLength && visibleIndex < width - (textIndex >= clampedPosition ? 0 : 1) {
                // Render bullet

                // Check if this character is in the selection
                let isSelected = selectionRange.map { textIndex >= $0.lowerBound && textIndex < $0.upperBound } ?? false

                if isSelected {
                    // Selection highlight: accent background, foreground contrasts
                    result += ANSIRenderer.colorize(
                        String(maskChar),
                        foreground: palette.background,
                        background: palette.accent
                    )
                } else {
                    result += ANSIRenderer.colorize(String(maskChar), foreground: palette.foreground, background: background)
                }
                outputWidth += 1
            } else if outputWidth < width {
                // Padding
                result += ANSIRenderer.colorize(" ", foreground: palette.foreground, background: background)
                outputWidth += 1
            }

            if outputWidth >= width {
                break
            }
        }

        return result
    }
}
