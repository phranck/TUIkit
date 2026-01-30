//
//  View+Modal.swift
//  TUIKit
//
//  The .modal() view extension for modal dialog presentation.
//

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
