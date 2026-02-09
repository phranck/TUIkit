//  TUIKit - Terminal UI Kit for Swift
//  TextField.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Text Input Autocapitalization

/// The autocapitalization behavior for text input.
///
/// In a terminal environment, autocapitalization affects how typed text
/// is transformed before being stored in the text binding.
public enum TextInputAutocapitalization: Sendable {
    /// No autocapitalization is applied.
    case never

    /// The first letter of each word is capitalized.
    case words

    /// The first letter of each sentence is capitalized.
    case sentences

    /// All letters are capitalized.
    case characters
}

// MARK: - TextField

/// A control that displays an editable text interface.
///
/// You create a text field with a label and a binding to a string value.
/// The text field updates this value continuously as the user types.
///
/// ## Rendering
///
/// The text field renders as `[ text content ]` with a visible cursor when focused.
/// When empty and unfocused, it displays the prompt text in dim styling.
///
/// ```
/// Unfocused, empty:     [ Enter username... ]    (prompt in dim)
/// Unfocused, with text: [ john.doe           ]   (text in normal)
/// Focused, empty:       [ █                  ]   (cursor, brackets pulse)
/// Focused, with text:   [ john.d█e           ]   (cursor in text)
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
/// @State var username = ""
///
/// TextField("Username", text: $username)
/// ```
///
/// # With Prompt
///
/// ```swift
/// TextField("Email", text: $email, prompt: Text("you@example.com"))
/// ```
///
/// # With ViewBuilder Label
///
/// ```swift
/// TextField(text: $username, prompt: Text("Required")) {
///     Text("Username").bold()
/// }
/// ```
///
/// # With Submit Action
///
/// ```swift
/// TextField("Search", text: $query)
///     .onSubmit {
///         performSearch()
///     }
/// ```
public struct TextField<Label: View>: View {
    /// The label view describing the field's purpose.
    let label: Label

    /// The binding to the text content.
    let text: Binding<String>

    /// Optional prompt text shown when the field is empty.
    let prompt: Text?

    /// The unique focus identifier.
    let focusID: String

    /// Whether the text field is disabled.
    let isDisabled: Bool

    /// Action to perform when the user submits (presses Enter).
    let onSubmitAction: (() -> Void)?

    /// The autocapitalization behavior.
    let autocapitalization: TextInputAutocapitalization

    public var body: some View {
        _TextFieldCore(
            label: label,
            text: text,
            prompt: prompt,
            focusID: focusID,
            isDisabled: isDisabled,
            onSubmitAction: onSubmitAction,
            autocapitalization: autocapitalization
        )
    }
}

// MARK: - TextField Initializers (Label == Text)

extension TextField where Label == Text {
    /// Creates a text field with a text label generated from a title string.
    ///
    /// - Parameters:
    ///   - title: The title of the text field, describing its purpose.
    ///   - text: The text to display and edit.
    public init(_ title: String, text: Binding<String>) {
        self.label = Text(title)
        self.text = text
        self.prompt = nil
        self.focusID = "textfield-\(title)"
        self.isDisabled = false
        self.onSubmitAction = nil
        self.autocapitalization = .never
    }

    /// Creates a text field with a prompt.
    ///
    /// - Parameters:
    ///   - title: The title of the text field, describing its purpose.
    ///   - text: The text to display and edit.
    ///   - prompt: A Text representing the prompt which provides users with
    ///     guidance on what to type into the text field.
    public init(_ title: String, text: Binding<String>, prompt: Text?) {
        self.label = Text(title)
        self.text = text
        self.prompt = prompt
        self.focusID = "textfield-\(title)"
        self.isDisabled = false
        self.onSubmitAction = nil
        self.autocapitalization = .never
    }
}

// MARK: - TextField Initializers (Generic Label)

extension TextField {
    /// Creates a text field with a prompt generated from a `Text` and a custom label.
    ///
    /// Use this initializer when you need a custom label view instead of a simple string.
    ///
    /// # Example
    ///
    /// ```swift
    /// TextField(text: $username, prompt: Text("Required")) {
    ///     HStack {
    ///         Text("Username").bold()
    ///         Text("*").foregroundStyle(.red)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text to display and edit.
    ///   - prompt: A Text representing the prompt which provides users with
    ///     guidance on what to type into the text field.
    ///   - label: A view that describes the purpose of the text field.
    public init(
        text: Binding<String>,
        prompt: Text? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.text = text
        self.prompt = prompt
        self.focusID = "textfield-\(UUID().uuidString)"
        self.isDisabled = false
        self.onSubmitAction = nil
        self.autocapitalization = .never
    }
}

// MARK: - TextField Modifiers

extension TextField {
    /// Creates a disabled version of this text field.
    ///
    /// - Parameter disabled: Whether the text field is disabled.
    /// - Returns: A new text field with the disabled state.
    public func disabled(_ disabled: Bool = true) -> TextField {
        TextField(
            label: label,
            text: text,
            prompt: prompt,
            focusID: focusID,
            isDisabled: disabled,
            onSubmitAction: onSubmitAction,
            autocapitalization: autocapitalization
        )
    }

    /// Adds an action to perform when the user submits (presses Enter).
    ///
    /// Use this modifier to invoke an action when the user presses Enter
    /// while the text field has focus.
    ///
    /// # Example
    ///
    /// ```swift
    /// TextField("Search", text: $query)
    ///     .onSubmit {
    ///         performSearch()
    ///     }
    /// ```
    ///
    /// - Parameter action: The action to perform on submit.
    /// - Returns: A text field that performs the action on submit.
    public func onSubmit(_ action: @escaping () -> Void) -> TextField {
        TextField(
            label: label,
            text: text,
            prompt: prompt,
            focusID: focusID,
            isDisabled: isDisabled,
            onSubmitAction: action,
            autocapitalization: autocapitalization
        )
    }

    /// Sets the autocapitalization behavior for this text field.
    ///
    /// Use this modifier to control how text is automatically capitalized
    /// as the user types.
    ///
    /// # Example
    ///
    /// ```swift
    /// TextField("Name", text: $name)
    ///     .textInputAutocapitalization(.words)
    /// ```
    ///
    /// - Parameter autocapitalization: The autocapitalization behavior.
    /// - Returns: A text field with the specified autocapitalization.
    public func textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization) -> TextField {
        TextField(
            label: label,
            text: text,
            prompt: prompt,
            focusID: focusID,
            isDisabled: isDisabled,
            onSubmitAction: onSubmitAction,
            autocapitalization: autocapitalization
        )
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of TextField.
private struct _TextFieldCore<Label: View>: View, Renderable {
    let label: Label
    let text: Binding<String>
    let prompt: Text?
    let focusID: String
    let isDisabled: Bool
    let onSubmitAction: (() -> Void)?
    let autocapitalization: TextInputAutocapitalization

    /// The cursor character shown when focused.
    private let cursorChar: Character = "█"

    /// Minimum visible width for the text field content area.
    private let minContentWidth = 20

    var body: Never {
        fatalError("_TextFieldCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let focusManager = context.environment.focusManager
        let stateStorage = context.tuiContext.stateStorage
        let palette = context.environment.palette

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
        handler.autocapitalization = autocapitalization
        handler.clampCursorPosition()

        // Register with focus manager
        focusManager.register(handler, inSection: context.activeFocusSectionID)
        stateStorage.markActive(context.identity)

        // Determine focus state
        let isFocused = focusManager.isFocused(id: persistedFocusID)

        // Build the text field content
        let content = buildContent(
            handler: handler,
            isFocused: isFocused,
            palette: palette,
            pulsePhase: context.pulsePhase
        )

        return FrameBuffer(text: content)
    }

    /// Builds the rendered text field content.
    private func buildContent(
        handler: TextFieldHandler,
        isFocused: Bool,
        palette: any Palette,
        pulsePhase: Double
    ) -> String {
        let textValue = text.wrappedValue
        let isEmpty = textValue.isEmpty

        // Determine bracket color
        let bracketColor: Color
        if isDisabled {
            bracketColor = palette.foregroundTertiary
        } else if isFocused {
            // Pulse between 35% and 100% accent
            let dimAccent = palette.accent.opacity(0.35)
            bracketColor = Color.lerp(dimAccent, palette.accent, phase: pulsePhase)
        } else {
            bracketColor = palette.border
        }

        // Render brackets
        let openBracket = ANSIRenderer.colorize("[", foreground: bracketColor, bold: isFocused && !isDisabled)
        let closeBracket = ANSIRenderer.colorize("]", foreground: bracketColor, bold: isFocused && !isDisabled)

        // Build inner content
        let innerContent: String
        if isEmpty && !isFocused && prompt != nil {
            // Show prompt when empty and unfocused
            innerContent = buildPromptContent(palette: palette)
        } else if isFocused {
            // Show text with cursor
            innerContent = buildTextWithCursor(
                text: textValue,
                cursorPosition: handler.cursorPosition,
                palette: palette
            )
        } else {
            // Show text without cursor
            innerContent = buildTextContent(text: textValue, palette: palette)
        }

        return "\(openBracket) \(innerContent) \(closeBracket)"
    }

    /// Builds the prompt content (shown when empty and unfocused).
    private func buildPromptContent(palette: any Palette) -> String {
        // Use the prompt text if available, rendered via its own render path
        // For now, use a simple placeholder approach
        let promptText: String
        if let prompt {
            // Render the prompt Text view to extract its string content
            let buffer = TUIkit.renderToBuffer(prompt, context: RenderContext(availableWidth: 100, availableHeight: 1))
            promptText = buffer.lines.first?.stripped ?? ""
        } else {
            promptText = ""
        }
        let paddedPrompt = promptText.padding(toLength: minContentWidth, withPad: " ", startingAt: 0)
        return ANSIRenderer.colorize(paddedPrompt, foreground: palette.foregroundTertiary)
    }

    /// Builds text content without cursor.
    private func buildTextContent(text: String, palette: any Palette) -> String {
        let paddedText = text.padding(toLength: max(minContentWidth, text.count), withPad: " ", startingAt: 0)
        if isDisabled {
            return ANSIRenderer.colorize(paddedText, foreground: palette.foregroundTertiary)
        }
        return paddedText
    }

    /// Builds text content with cursor at the specified position.
    private func buildTextWithCursor(
        text: String,
        cursorPosition: Int,
        palette: any Palette
    ) -> String {
        let clampedPosition = max(0, min(cursorPosition, text.count))

        // Split text at cursor position
        let beforeCursor = String(text.prefix(clampedPosition))
        let afterCursor = String(text.suffix(from: text.index(text.startIndex, offsetBy: clampedPosition)))

        // Render cursor with accent color
        let cursor = ANSIRenderer.colorize(String(cursorChar), foreground: palette.accent)

        // Combine: [before][cursor][after]
        let combined = beforeCursor + cursor + afterCursor

        // Pad to minimum width (accounting for cursor taking 1 visual space)
        let visibleLength = text.count + 1  // text + cursor
        let paddingNeeded = max(0, minContentWidth - visibleLength)
        let padding = String(repeating: " ", count: paddingNeeded)

        return combined + padding
    }
}
