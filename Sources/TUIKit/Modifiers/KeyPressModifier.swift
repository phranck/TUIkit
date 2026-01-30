//
//  KeyPressModifier.swift
//  TUIKit
//
//  A modifier for handling keyboard events.
//

/// A modifier that adds a key press handler to a view.
///
/// The handler returns a Bool indicating whether the event was consumed.
/// If false is returned, the event continues to propagate to other handlers.
public struct KeyPressModifier<Content: View>: View {
    /// The content view.
    let content: Content

    /// The keys to listen for (nil = all keys).
    let keys: Set<Key>?

    /// The handler to call when a matching key is pressed.
    /// Returns true if the event was handled, false to let it propagate.
    let handler: (KeyEvent) -> Bool

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

            // Call handler and return whether it consumed the event
            return handler(event)
        }

        // Render the content
        return TUIKit.renderToBuffer(content, context: context)
    }
}


