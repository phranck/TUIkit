//  🖥️ TUIKit — Terminal UI Kit for Swift
//  View+Presentation.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

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
    /// .alert("Warning", isPresented: $showAlert) {
    ///     Button("Yes") { showAlert = false }
    ///     Button("Cancel", style: .secondary) { showAlert = false }
    /// } message: {
    ///     Text("Are you sure?")
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - isPresented: A binding to a Boolean value that determines whether
    ///     to present the alert.
    ///   - actions: A ViewBuilder returning the alert action buttons.
    ///   - message: A ViewBuilder returning the alert message content.
    /// - Returns: A view that presents an alert conditionally.
    ///
    /// ## TUIKit Extensions
    ///
    /// TUIKit adds optional styling parameters not present in SwiftUI:
    /// - `borderStyle`: Custom border style for the alert
    /// - `borderColor`: Custom border color
    /// - `titleColor`: Custom title text color
    public func alert<Actions: View, Message: View>(
        _ title: String,
        isPresented: Binding<Bool>,
        @ViewBuilder actions: @escaping () -> Actions,
        @ViewBuilder message: @escaping () -> Message,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil
    ) -> some View {
        AlertPresentationModifier<Self, Actions, Message>(
            content: self,
            isPresented: isPresented,
            title: title,
            message: message(),
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
        AlertPresentationModifier<Self, Actions, EmptyView>(
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

// MARK: - App Header

extension View {
    /// Declares the app header content for this view.
    ///
    /// The header is rendered at the top of the terminal, outside the view tree,
    /// similar to the status bar at the bottom. When no `.appHeader` modifier is
    /// present, the header is hidden and no vertical space is reserved.
    ///
    /// ## Example
    ///
    /// ```swift
    /// VStack {
    ///     Text("Page content")
    /// }
    /// .appHeader {
    ///     HStack {
    ///         Text("My App").bold().foregroundStyle(.palette.accent)
    ///         Spacer()
    ///         Text("v1.0").foregroundStyle(.palette.foregroundTertiary)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter content: A ViewBuilder returning the header content.
    /// - Returns: A view that declares the app header content.
    public func appHeader<Header: View>(
        @ViewBuilder content: () -> Header
    ) -> some View {
        AppHeaderModifier(content: self, header: content())
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

// MARK: - Notification Host

extension View {
    /// Makes this view the notification rendering host.
    ///
    /// Attach this modifier once at the root of your view tree. It reads
    /// active notifications from the environment's ``NotificationService``
    /// and renders them as a stacked overlay at the configured position.
    ///
    /// Notifications are posted via the service, not declared in the view tree:
    ///
    /// ```swift
    /// // At the root:
    /// ContentView()
    ///     .notificationHost()
    ///
    /// // Anywhere in the hierarchy:
    /// NotificationService.current.post("Saved!")
    /// ```
    ///
    /// The base content remains fully interactive — notifications do not dim
    /// or block the background.
    ///
    /// - Parameter width: Fixed width of each notification box in characters (default: 40).
    /// - Returns: A view that renders notifications from the environment service.
    public func notificationHost(
        width: Int = 40
    ) -> some View {
        NotificationHostModifier(
            content: self,
            width: width
        )
    }
}
