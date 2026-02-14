//  🖥️ TUIKit — Terminal UI Kit for Swift
//  KeyEvent.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - Key Event Handler

/// Global key event handler.
///
/// Views can register handlers that are called when keys are pressed.
/// Handlers are processed in reverse order (most recent first).
final class KeyEventDispatcher: @unchecked Sendable {
    /// Registered key handlers.
    private var handlers: [(KeyEvent) -> Bool] = []

    /// Creates a new key event dispatcher.
    init() {}
}

// MARK: - Internal API

extension KeyEventDispatcher {
    /// Registers a key handler.
    ///
    /// - Parameter handler: A closure that returns true if the key was handled.
    func addHandler(_ handler: @escaping (KeyEvent) -> Bool) {
        handlers.append(handler)
    }

    /// Clears all handlers.
    func clearHandlers() {
        handlers.removeAll()
    }

    /// Dispatches a key event to handlers.
    ///
    /// - Parameter event: The key event to dispatch.
    /// - Returns: True if any handler consumed the event.
    @discardableResult
    func dispatch(_ event: KeyEvent) -> Bool {
        // Process in reverse order (most recent handlers first)
        for handler in handlers.reversed() where handler(event) {
            return true
        }
        return false
    }
}
