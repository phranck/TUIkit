//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Focusable.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Focusable Protocol

/// A protocol for views that can receive focus.
///
/// Focusable views can receive keyboard input when focused.
/// The focus system manages which view currently has focus and
/// routes keyboard events accordingly.
public protocol Focusable: AnyObject {
    /// The unique identifier for this focusable element.
    var focusID: String { get }

    /// Whether this element can currently receive focus.
    var canBeFocused: Bool { get }

    /// Called when this element receives focus.
    func onFocusReceived()

    /// Called when this element loses focus.
    func onFocusLost()

    /// Handles a key event when focused.
    ///
    /// - Parameter event: The key event to handle.
    /// - Returns: True if the event was consumed, false to propagate.
    func handleKeyEvent(_ event: KeyEvent) -> Bool
}

// Default implementations
extension Focusable {
    public var canBeFocused: Bool { true }
    public func onFocusReceived() {}
    public func onFocusLost() {}
}
