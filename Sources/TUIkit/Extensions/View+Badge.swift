//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+Badge.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - Badge Modifier

extension View {
    /// Adds a badge to the view displaying a count.
    ///
    /// The badge is typically rendered on list rows and shows a numeric count.
    /// A badge with a count of 0 is automatically hidden.
    ///
    /// # Example
    ///
    /// ```swift
    /// List {
    ///     Text("Notifications")
    ///         .badge(5)
    /// }
    /// ```
    ///
    /// - Parameter count: The count to display in the badge (0 hides the badge).
    /// - Returns: A view with the badge applied.
    public func badge(_ count: Int) -> some View {
        BadgeModifier(content: self, value: .int(count))
    }

    /// Adds a badge to the view with a string label.
    ///
    /// The badge is typically rendered on list rows. Passing `nil` or empty string hides the badge.
    ///
    /// # Example
    ///
    /// ```swift
    /// List {
    ///     Text("Messages")
    ///         .badge("3 unread")
    /// }
    /// ```
    ///
    /// - Parameter label: The string label to display (nil or empty hides the badge).
    /// - Returns: A view with the badge applied.
    public func badge<S>(_ label: S?) -> some View where S: StringProtocol {
        BadgeModifier(content: self, value: .string(label.map { String($0) }))
    }
}
