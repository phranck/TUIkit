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
public struct SecureField<Label: View>: View {
    /// The label view describing the field's purpose.
    let label: Label

    /// The binding to the text content.
    let text: Binding<String>

    /// Optional prompt text shown when the field is empty.
    let prompt: Text?

    /// The unique focus identifier.
    var focusID: String?

    /// Whether the secure field is disabled.
    var isDisabled: Bool

    /// Action to perform when the user submits (presses Enter).
    var onSubmitAction: (() -> Void)?

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

// MARK: - SecureField Initializers (String Label)

extension SecureField where Label == Text {
    /// Creates a secure field with a text label generated from a title string.
    ///
    /// - Parameters:
    ///   - title: The title of the secure field, describing its purpose.
    ///   - text: The text to display and edit.
    public init(_ title: String, text: Binding<String>) {
        self.label = Text(title)
        self.text = text
        self.prompt = nil
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
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
        self.label = Text(title)
        self.text = text
        self.prompt = prompt
        // Auto-generated focusID from view identity (collision-free)
        self.focusID = nil
        self.isDisabled = false
        self.onSubmitAction = nil
    }
}

// MARK: - SecureField Initializers (ViewBuilder Label)

extension SecureField {
    /// Creates a secure field with a custom label.
    ///
    /// Use this initializer when you need a custom label view instead of a simple string.
    ///
    /// # Example
    ///
    /// ```swift
    /// SecureField(text: $password, prompt: Text("Required")) {
    ///     HStack {
    ///         Text("Password").bold()
    ///         Text("*").foregroundStyle(.red)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - text: The text to display and edit.
    ///   - prompt: A Text representing the prompt which provides users with
    ///     guidance on what to type into the secure field.
    ///   - label: A view that describes the purpose of the secure field.
    public init(
        text: Binding<String>,
        prompt: Text? = nil,
        @ViewBuilder label: () -> Label
    ) {
        self.label = label()
        self.text = text
        self.prompt = prompt
        self.focusID = nil
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
        var copy = self
        copy.isDisabled = disabled
        return copy
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
        var copy = self
        copy.onSubmitAction = action
        return copy
    }

    /// Sets a custom focus identifier for this secure field.
    ///
    /// - Parameter id: The unique focus identifier.
    /// - Returns: A secure field with the specified focus identifier.
    public func focusID(_ id: String) -> SecureField {
        var copy = self
        copy.focusID = id
        return copy
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of SecureField.
private struct _SecureFieldCore: View, Renderable, Layoutable {
    let text: Binding<String>
    let prompt: Text?
    let focusID: String?
    let isDisabled: Bool
    let onSubmitAction: (() -> Void)?

    /// Minimum width for the secure field content area.
    private let minContentWidth = 10

    /// Default visible width for the secure field content area when no proposal is given.
    private let defaultContentWidth = 20

    var body: Never {
        fatalError("_SecureFieldCore renders via Renderable")
    }

    /// Returns the size this secure field needs.
    ///
    /// SecureField is width-flexible: it has a minimum width but expands
    /// to fill available horizontal space in HStack.
    func sizeThatFits(proposal: ProposedSize, context: RenderContext) -> ViewSize {
        let width = proposal.width ?? defaultContentWidth
        return ViewSize(
            width: max(minContentWidth, width),
            height: 1,
            isWidthFlexible: true,
            isHeightFlexible: false
        )
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let stateStorage = context.tuiContext.stateStorage
        let palette = context.environment.palette
        let cursorStyle = context.environment.textCursorStyle

        // SecureField expands to fill available width (reserve 2 chars for caps)
        let contentWidth = max(minContentWidth, context.availableWidth - 2)

        let persistedFocusID = FocusRegistration.persistFocusID(
            context: context,
            explicitFocusID: focusID,
            defaultPrefix: "securefield",
            propertyIndex: 1  // focusID
        )

        // Get or create persistent handler from state storage.
        // Reuses TextFieldHandler since key handling is identical.
        let handlerKey = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)  // handler
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

        FocusRegistration.register(context: context, handler: handler)
        let isFocused = FocusRegistration.isFocused(context: context, focusID: persistedFocusID)

        // Build the secure field content using shared renderer
        let renderer = TextFieldContentRenderer(
            prompt: prompt,
            isDisabled: isDisabled,
            displayCharacter: { _, _ in TerminalSymbols.maskBullet }
        )

        let fieldContent = renderer.buildContent(
            text: text.wrappedValue,
            cursorPosition: handler.cursorPosition,
            selectionRange: handler.selectionRange,
            isFocused: isFocused,
            palette: palette,
            cursorStyle: cursorStyle,
            cursorTimer: context.cursorTimer,
            contentWidth: contentWidth
        )

        // Wrap with half-block caps
        let capColor = palette.accent.opacity(0.2)
        let openCap = ANSIRenderer.colorize(String(TerminalSymbols.openCap), foreground: capColor)
        let closeCap = ANSIRenderer.colorize(String(TerminalSymbols.closeCap), foreground: capColor)
        return FrameBuffer(text: openCap + fieldContent + closeCap)
    }

}
