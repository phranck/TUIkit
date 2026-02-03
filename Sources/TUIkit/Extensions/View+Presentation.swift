//
//  View+Presentation.swift
//  TUIkit
//
//  SwiftUI-style presentation modifiers for alerts and modals.
//

// MARK: - Alert Presentation

extension View {
    /// Presents an alert when a binding to a Boolean value is true.
    ///
    /// This modifier mirrors SwiftUI's `.alert(isPresented:)` pattern. When
    /// `isPresented` is `true`, the base content is dimmed and the alert is
    /// displayed centered on top.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @State var showAlert = false
    ///
    /// VStack {
    ///     Button("Show Alert") { showAlert = true }
    /// }
    /// .alert("Warning", isPresented: $showAlert, message: "Are you sure?") {
    ///     Button("Yes") { showAlert = false }
    ///     Button("Cancel", style: .secondary) { showAlert = false }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the alert.
    ///   - actions: A ViewBuilder returning the alert action buttons.
    ///   - message: The alert message text.
    ///   - borderStyle: Optional border style (default: uses theme default).
    ///   - borderColor: Optional border color (default: uses theme border).
    ///   - titleColor: Optional title color (default: uses theme foreground).
    /// - Returns: A view that presents an alert conditionally.
    public func alert<Actions: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions,
        message: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil
    ) -> some View {
        AlertPresentationModifier(
            content: self,
            isPresented: isPresented,
            title: title,
            message: message,
            actions: actions(),
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor
        )
    }

    /// Presents an alert with title and actions only (no message).
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the alert.
    ///   - actions: A ViewBuilder returning the alert action buttons.
    ///   - borderStyle: Optional border style.
    ///   - borderColor: Optional border color.
    ///   - titleColor: Optional title color.
    /// - Returns: A view that presents an alert conditionally.
    public func alert<Actions: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil
    ) -> some View {
        AlertPresentationModifier(
            content: self,
            isPresented: isPresented,
            title: title,
            message: nil,
            actions: actions(),
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor
        )
    }
}

// MARK: - Modal Presentation

extension View {
    /// Presents a modal overlay when a binding to a Boolean value is true.
    ///
    /// This modifier dims the base content and displays the provided content
    /// centered on top when `isPresented` is `true`. Use this for custom modal
    /// content that doesn't fit the alert pattern.
    ///
    /// ## Example
    ///
    /// ```swift
    /// @State var showSettings = false
    ///
    /// VStack {
    ///     Button("Settings") { showSettings = true }
    /// }
    /// .modal(isPresented: $showSettings) {
    ///     Dialog(title: "Settings") {
    ///         Text("Option 1")
    ///         Text("Option 2")
    ///         Button("Close") { showSettings = false }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the modal.
    ///   - content: A ViewBuilder returning the modal content.
    /// - Returns: A view that presents a modal overlay conditionally.
    public func modal<Modal: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Modal
    ) -> some View {
        ModalPresentationModifier(
            content: self,
            isPresented: isPresented,
            modal: content()
        )
    }
}
