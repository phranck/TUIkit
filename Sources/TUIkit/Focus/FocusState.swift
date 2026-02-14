//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FocusState.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Focus State for Views

/// Tracks focus state for a specific element.
///
/// `FocusState` is a lightweight wrapper around a `FocusManager` that
/// provides a simple focused/unfocused API for a single element.
///
/// Create a `FocusState` with a reference to the focus manager
/// (typically obtained from `context.environment.focusManager`):
///
/// ```swift
/// let focus = FocusState(focusManager: context.environment.focusManager)
/// if focus.isFocused { /* render focused style */ }
/// ```
public class FocusState {
    /// The focus ID.
    public let id: String

    /// The focus manager that tracks focus state.
    private let focusManager: FocusManager

    /// Creates a focus state with the given ID and focus manager.
    ///
    /// - Parameters:
    ///   - id: The unique focus ID. Defaults to a new UUID.
    ///   - focusManager: The focus manager to query and mutate.
    public init(id: String = UUID().uuidString, focusManager: FocusManager) {
        self.id = id
        self.focusManager = focusManager
    }

    /// Whether this element is currently focused.
    public var isFocused: Bool {
        focusManager.isFocused(id: id)
    }
}

// MARK: - Public API

public extension FocusState {
    /// Requests focus for this element.
    func requestFocus() {
        focusManager.focus(id: id)
    }
}
