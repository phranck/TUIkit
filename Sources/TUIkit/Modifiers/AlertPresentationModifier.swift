//
//  AlertPresentationModifier.swift
//  TUIkit
//
//  A modifier that presents an alert dialog conditionally based on a binding.
//

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
/// .alert("Warning", isPresented: $showAlert, message: "Are you sure?") {
///     Button("Yes") { showAlert = false }
///     Button("No") { showAlert = false }
/// }
/// ```
public struct AlertPresentationModifier<Content: View, Actions: View>: View {
    /// The base content to render.
    let content: Content

    /// Binding to control alert visibility.
    let isPresented: Binding<Bool>

    /// The alert title.
    let title: String

    /// The alert message (optional).
    let message: String?

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
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // If not presented, just return base content
        guard isPresented.wrappedValue else {
            return TUIkit.renderToBuffer(content, context: context)
        }

        // Build the alert view
        let alert: Alert<Actions>
        if let message = message {
            alert = Alert(
                title: title,
                message: message,
                borderStyle: borderStyle,
                borderColor: borderColor,
                titleColor: titleColor,
                actions: { actions }
            )
        } else {
            alert = Alert(
                title: title,
                message: "",
                borderStyle: borderStyle,
                borderColor: borderColor,
                titleColor: titleColor,
                actions: { actions }
            )
        }

        // Render dimmed base with centered alert overlay
        let dimmedBase = DimmedModifier(content: content)
        let dimmedBuffer = TUIkit.renderToBuffer(dimmedBase, context: context)

        let alertBuffer = TUIkit.renderToBuffer(alert, context: context)

        guard !dimmedBuffer.isEmpty else {
            return alertBuffer
        }

        guard !alertBuffer.isEmpty else {
            return dimmedBuffer
        }

        // Calculate center position
        let baseWidth = dimmedBuffer.width
        let baseHeight = dimmedBuffer.height
        let alertWidth = alertBuffer.width
        let alertHeight = alertBuffer.height

        let horizontalOffset = max(0, (baseWidth - alertWidth) / 2)
        let verticalOffset = max(0, (baseHeight - alertHeight) / 2)

        return dimmedBuffer.composited(
            with: alertBuffer,
            at: (x: horizontalOffset, y: verticalOffset)
        )
    }
}
