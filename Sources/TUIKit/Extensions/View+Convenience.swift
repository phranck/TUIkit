//
//  View+Convenience.swift
//  TUIKit
//
//  Convenience view extensions: modal, asAnyView.
//

// MARK: - Modal

extension View {
    /// Presents this view as a modal dialog over dimmed content.
    ///
    /// This is a convenience method that combines `.dimmed()` and `.overlay()`
    /// with center alignment.
    ///
    /// ## Example
    ///
    /// ```swift
    /// mainContent.modal {
    ///     Dialog(title: "Settings") {
    ///         Text("Setting 1")
    ///         Text("Setting 2")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter content: The modal content to display.
    /// - Returns: A view with the modal overlay.
    public func modal<Modal: View>(
        @ViewBuilder content: () -> Modal
    ) -> some View {
        self.dimmed()
            .overlay(alignment: .center, content: content)
    }
}

// MARK: - Type Erasure

extension View {
    /// Wraps this view in an AnyView for type erasure.
    ///
    /// Use this when you need to return different view types from
    /// conditional branches.
    public func asAnyView() -> AnyView {
        AnyView(self)
    }
}
