//
//  KeyPressModifier.swift
//  SwiftTUI
//
//  A modifier for handling keyboard events.
//

/// A modifier that adds a key press handler to a view.
public struct KeyPressModifier<Content: TView>: TView {
    /// The content view.
    let content: Content

    /// The keys to listen for (nil = all keys).
    let keys: Set<Key>?

    /// The handler to call when a matching key is pressed.
    let handler: (KeyEvent) -> Void

    public var body: Never {
        fatalError("KeyPressModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension KeyPressModifier: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Register the key handler
        KeyEventDispatcher.shared.addHandler { [keys, handler] event in
            // Check if we should handle this key
            if let allowedKeys = keys {
                guard allowedKeys.contains(event.key) else {
                    return false
                }
            }

            handler(event)
            return true
        }

        // Render the content
        return SwiftTUI.renderToBuffer(content, context: context)
    }
}

// MARK: - TView Extension

extension TView {
    /// Adds a handler for key press events.
    ///
    /// The handler is called when any key is pressed while this view
    /// is in the view hierarchy.
    ///
    /// # Example
    ///
    /// ```swift
    /// Text("Press any key")
    ///     .onKeyPress { event in
    ///         print("Key pressed: \(event.key)")
    ///     }
    /// ```
    ///
    /// - Parameter handler: The handler to call on key press.
    /// - Returns: A view that handles key presses.
    public func onKeyPress(_ handler: @escaping (KeyEvent) -> Void) -> some TView {
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
    ///     }
    /// ```
    ///
    /// - Parameters:
    ///   - keys: The keys to listen for.
    ///   - handler: The handler to call on key press.
    /// - Returns: A view that handles specific key presses.
    public func onKeyPress(keys: Set<Key>, handler: @escaping (KeyEvent) -> Void) -> KeyPressModifier<Self> {
        KeyPressModifier(content: self, keys: keys, handler: handler)
    }

    /// Adds a handler for a single key press.
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
        KeyPressModifier(content: self, keys: [key], handler: { _ in action() })
    }
}
