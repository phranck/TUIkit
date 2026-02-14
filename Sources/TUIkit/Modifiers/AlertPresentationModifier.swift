//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AlertPresentationModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modifier that presents an alert dialog when a binding is true.
///
/// This modifier mirrors SwiftUI's `.alert(isPresented:)` API. When `isPresented`
/// is `true`, the base content is dimmed and the alert is shown centered on top.
/// When `false`, only the base content is rendered.
///
/// ## Example
///
/// ```swift
/// VStack {
///     Text("Main content")
/// }
/// .alert("Warning", isPresented: $showAlert) {
///     Button("Yes") { showAlert = false }
///     Button("No") { showAlert = false }
/// } message: {
///     Text("Are you sure?")
/// }
/// ```
public struct AlertPresentationModifier<Content: View, Actions: View, Message: View>: View {
    /// The base content to render.
    let content: Content

    /// Binding to control alert visibility.
    let isPresented: Binding<Bool>

    /// The alert title.
    let title: String

    /// The alert message content (optional).
    let message: Message?

    /// The alert action buttons.
    let actions: Actions

    /// Alert border style (optional).
    let borderStyle: BorderStyle?

    /// Alert border color (optional).
    let borderColor: Color?

    /// Alert title color (optional).
    let titleColor: Color?

    public var body: Never {
        fatalError("AlertPresentationModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension AlertPresentationModifier: Renderable {
    /// A stable section ID for alert focus sections.
    private static var alertSectionID: String { "__alert__" }

    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // If not presented, just return base content
        guard isPresented.wrappedValue else {
            return TUIkit.renderToBuffer(content, context: context)
        }

        // Render message content to string if provided
        let messageString: String
        if let message {
            let messageBuffer = TUIkit.renderToBuffer(message, context: context)
            messageString = messageBuffer.lines.joined(separator: "\n").stripped
        } else {
            messageString = ""
        }

        // Build the alert view
        let alert = Alert(
            title: title,
            message: messageString,
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            actions: { actions }
        )

        let focusManager = context.environment.focusManager

        // Render dimmed base with an isolated context.
        // The base content's buttons and key handlers register into a
        // throwaway FocusManager and KeyEventDispatcher so they don't
        // interfere with the alert's interactive elements.
        let dimmedBase = DimmedModifier(content: content)
        let isolatedContext = context.isolatedForBackground()
        let dimmedBuffer = TUIkit.renderToBuffer(dimmedBase, context: isolatedContext)

        // Register an alert focus section and activate it.
        // The alert section becomes the active section, so Tab/arrows
        // only navigate within the alert's focusable elements (buttons).
        let sectionID = Self.alertSectionID
        if !context.isMeasuring {
            focusManager.registerSection(id: sectionID)
            focusManager.activateSection(id: sectionID)
        }

        // Register ESC handler to dismiss the alert
        let isPresentedBinding = isPresented
        context.environment.keyEventDispatcher!.addHandler { event in
            if event.key == .escape {
                isPresentedBinding.wrappedValue = false
                return true
            }
            return false
        }

        // Set the alert section in the context so child focusables
        // (buttons in the alert) register in the alert section.
        var alertContext = context
        alertContext.environment.activeFocusSectionID = sectionID

        let alertBuffer = TUIkit.renderToBuffer(alert, context: alertContext)

        guard !dimmedBuffer.isEmpty else {
            return alertBuffer
        }

        guard !alertBuffer.isEmpty else {
            return dimmedBuffer
        }

        // Center relative to the full terminal area, not the content size.
        let screenWidth = context.availableWidth
        let screenHeight = context.availableHeight
        let alertWidth = alertBuffer.width
        let alertHeight = alertBuffer.height

        let horizontalOffset = max(0, (screenWidth - alertWidth) / 2)
        let verticalOffset = max(0, (screenHeight - alertHeight) / 2 - 2)

        return dimmedBuffer.composited(
            with: alertBuffer,
            at: (x: horizontalOffset, y: verticalOffset)
        )
    }
}
