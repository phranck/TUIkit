//
//  View+KeyPress.swift
//  TUIKit
//
//  The .onKeyPress() view extensions for handling keyboard events.
//

extension View {
    /// Adds a handler for key press events.
    ///
    /// The handler is called when any key is pressed while this view
    /// is in the view hierarchy. Return `true` to consume the event,
    /// or `false` to let it propagate to other handlers.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Press any key")
    ///     .onKeyPress { event in
    ///         if event.key == .enter {
    ///             doSomething()
    ///             return true  // Consumed
    ///         }
    ///         return false  // Let others handle it
    ///     }
    /// ```
    ///
    /// - Parameter handler: The handler to call on key press. Returns true if handled.
    /// - Returns: A view that handles key presses.
    public func onKeyPress(_ handler: @escaping (KeyEvent) -> Bool) -> some View {
        KeyPressModifier(content: self, keys: nil, handler: handler)
    }

    /// Adds a handler for specific key press events.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Use arrow keys")
    ///     .onKeyPress(keys: [.up, .down]) { event in
    ///         if event.key == .up {
    ///             moveUp()
    ///         } else {
    ///             moveDown()
    ///         }
    ///         return true
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - keys: The keys to listen for.
    ///   - handler: The handler to call on key press. Returns true if handled.
    /// - Returns: A view that handles specific key presses.
    public func onKeyPress(keys: Set<Key>, handler: @escaping (KeyEvent) -> Bool) -> KeyPressModifier<Self> {
        KeyPressModifier(content: self, keys: keys, handler: handler)
    }

    /// Adds a handler for a single key press.
    ///
    /// This handler always consumes the event when the specified key is pressed.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Press Enter to continue")
    ///     .onKeyPress(.enter) {
    ///         continueAction()
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - key: The key to listen for.
    ///   - action: The action to perform.
    /// - Returns: A view that handles the specific key press.
    public func onKeyPress(_ key: Key, action: @escaping () -> Void) -> KeyPressModifier<Self> {
        KeyPressModifier(content: self, keys: [key], handler: { _ in
            action()
            return true
        })
    }
}
