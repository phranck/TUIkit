//
//  Focus.swift
//  TUIKit
//
//  Focus management system for interactive views.
//

import Foundation

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
public extension Focusable {
    var canBeFocused: Bool { true }
    func onFocusReceived() {}
    func onFocusLost() {}
}

// MARK: - Focus Manager

/// Manages focus state across the application.
///
/// The focus manager tracks which element currently has focus and
/// provides methods to move focus between elements.
///
/// FocusManager is injected via the Environment system, not as a singleton.
/// Each app instance gets its own FocusManager, allowing for proper test isolation.
///
/// # Usage
///
/// ```swift
/// // Access via Environment in views
/// let focusManager = context.environment.focusManager
///
/// // Register a focusable element
/// focusManager.register(button)
///
/// // Move focus
/// focusManager.focusNext()
/// focusManager.focusPrevious()
///
/// // Check focus
/// if focusManager.isFocused(button) {
///     // render focused style
/// }
/// ```
public final class FocusManager: @unchecked Sendable {
    /// Registered focusable elements in order.
    private var focusables: [Focusable] = []

    /// The currently focused element's ID.
    private var focusedID: String?

    /// Callback triggered when focus changes.
    public var onFocusChange: (() -> Void)?

    /// Creates a new focus manager instance.
    public init() {}

    // MARK: - Registration

    /// Registers a focusable element.
    ///
    /// - Parameter element: The element to register.
    public func register(_ element: Focusable) {
        // Avoid duplicates
        if !focusables.contains(where: { $0.focusID == element.focusID }) {
            focusables.append(element)

            // Auto-focus first element if nothing is focused
            if focusedID == nil && element.canBeFocused {
                focus(element)
            }
        }
    }

    /// Unregisters a focusable element.
    ///
    /// - Parameter element: The element to unregister.
    public func unregister(_ element: Focusable) {
        focusables.removeAll { $0.focusID == element.focusID }

        // If the removed element was focused, focus the next available
        if focusedID == element.focusID {
            focusedID = nil
            focusNext()
        }
    }

    /// Clears all registered focusables.
    public func clear() {
        focusables.removeAll()
        focusedID = nil
    }

    // MARK: - Focus Control

    /// Focuses a specific element.
    ///
    /// - Parameter element: The element to focus.
    public func focus(_ element: Focusable) {
        guard element.canBeFocused else { return }

        // Notify previous focused element
        if let currentID = focusedID,
           let current = focusables.first(where: { $0.focusID == currentID }) {
            current.onFocusLost()
        }

        focusedID = element.focusID
        element.onFocusReceived()
        onFocusChange?()
    }

    /// Focuses an element by ID.
    ///
    /// - Parameter id: The focus ID of the element to focus.
    public func focus(id: String) {
        if let element = focusables.first(where: { $0.focusID == id && $0.canBeFocused }) {
            focus(element)
        }
    }

    /// Moves focus to the next focusable element.
    public func focusNext() {
        guard !focusables.isEmpty else { return }

        let availableFocusables = focusables.filter { $0.canBeFocused }
        guard !availableFocusables.isEmpty else { return }

        if let currentID = focusedID,
           let currentIndex = availableFocusables.firstIndex(where: { $0.focusID == currentID }) {
            // Move to next (wrap around)
            let nextIndex = (currentIndex + 1) % availableFocusables.count
            focus(availableFocusables[nextIndex])
        } else {
            // Focus first available
            focus(availableFocusables[0])
        }
    }

    /// Moves focus to the previous focusable element.
    public func focusPrevious() {
        guard !focusables.isEmpty else { return }

        let availableFocusables = focusables.filter { $0.canBeFocused }
        guard !availableFocusables.isEmpty else { return }

        if let currentID = focusedID,
           let currentIndex = availableFocusables.firstIndex(where: { $0.focusID == currentID }) {
            // Move to previous (wrap around)
            let prevIndex = currentIndex == 0 ? availableFocusables.count - 1 : currentIndex - 1
            focus(availableFocusables[prevIndex])
        } else {
            // Focus last available
            focus(availableFocusables[availableFocusables.count - 1])
        }
    }

    // MARK: - Focus State

    /// Returns whether the given element is currently focused.
    ///
    /// - Parameter element: The element to check.
    /// - Returns: True if the element is focused.
    public func isFocused(_ element: Focusable) -> Bool {
        focusedID == element.focusID
    }

    /// Returns whether an element with the given ID is currently focused.
    ///
    /// - Parameter id: The focus ID to check.
    /// - Returns: True if the element is focused.
    public func isFocused(id: String) -> Bool {
        focusedID == id
    }

    /// The currently focused element, if any.
    public var currentFocused: Focusable? {
        guard let id = focusedID else { return nil }
        return focusables.first { $0.focusID == id }
    }

    /// The ID of the currently focused element, if any.
    public var currentFocusedID: String? {
        focusedID
    }

    // MARK: - Event Dispatch

    /// Dispatches a key event to the currently focused element.
    ///
    /// If Tab is pressed, focus moves to the next element.
    /// If Shift+Tab is pressed, focus moves to the previous element.
    ///
    /// - Parameter event: The key event to dispatch.
    /// - Returns: True if the event was handled.
    @discardableResult
    public func dispatchKeyEvent(_ event: KeyEvent) -> Bool {
        // Tab navigation
        if event.key == .tab {
            if event.shift {
                focusPrevious()
            } else {
                focusNext()
            }
            return true
        }

        // Dispatch to focused element
        if let focused = currentFocused {
            return focused.handleKeyEvent(event)
        }

        return false
    }
}

// MARK: - Focus Manager Environment Key

/// Environment key for the focus manager.
private struct FocusManagerKey: EnvironmentKey {
    static let defaultValue: FocusManager = FocusManager()
}

extension EnvironmentValues {
    /// The focus manager for managing keyboard focus.
    ///
    /// Access via `@Environment(\.focusManager)` or `context.environment.focusManager`.
    public var focusManager: FocusManager {
        get { self[FocusManagerKey.self] }
        set { self[FocusManagerKey.self] = newValue }
    }
}

// MARK: - Focus State for Views

/// Tracks focus state for a specific element.
///
/// This is a lightweight wrapper that can be embedded in views
/// to track whether they are focused. It accesses the FocusManager
/// via the Environment system.
public class FocusState {
    /// The focus ID.
    public let id: String

    /// Creates a focus state with the given ID.
    ///
    /// - Parameter id: The unique focus ID.
    public init(id: String = UUID().uuidString) {
        self.id = id
    }

    /// Whether this element is currently focused.
    ///
    /// Reads from the current environment's focus manager.
    public var isFocused: Bool {
        EnvironmentStorage.shared.environment.focusManager.isFocused(id: id)
    }

    /// Requests focus for this element.
    ///
    /// Uses the current environment's focus manager.
    public func requestFocus() {
        EnvironmentStorage.shared.environment.focusManager.focus(id: id)
    }
}
