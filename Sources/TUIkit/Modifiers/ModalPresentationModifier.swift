//
//  ModalPresentationModifier.swift
//  TUIkit
//
//  A modifier that presents arbitrary content as a modal overlay.
//

/// A modifier that presents content as a centered modal overlay when a binding is true.
///
/// This is a generic presentation modifier that dims the base content and shows
/// the provided content centered on top. Unlike `AlertPresentationModifier`, this
/// accepts any view content.
///
/// ## Example
///
/// ```swift
/// VStack {
///     Text("Main content")
/// }
/// .modal(isPresented: $showModal) {
///     Dialog(title: "Settings") {
///         Text("Setting 1")
///         Text("Setting 2")
///     }
/// }
/// ```
public struct ModalPresentationModifier<Content: View, Modal: View>: View {
    /// The base content to render.
    let content: Content

    /// Binding to control modal visibility.
    let isPresented: Binding<Bool>

    /// The modal content to present.
    let modal: Modal

    public var body: Never {
        fatalError("ModalPresentationModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension ModalPresentationModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let baseBuffer = TUIkit.renderToBuffer(content, context: context)

        // If not presented, just return base content
        guard isPresented.wrappedValue else {
            return baseBuffer
        }

        // Render dimmed base with centered modal overlay
        let dimmedBase = DimmedModifier(content: content)
        let dimmedBuffer = TUIkit.renderToBuffer(dimmedBase, context: context)

        let modalBuffer = TUIkit.renderToBuffer(modal, context: context)

        guard !dimmedBuffer.isEmpty else {
            return modalBuffer
        }

        guard !modalBuffer.isEmpty else {
            return dimmedBuffer
        }

        // Calculate center position
        let baseWidth = dimmedBuffer.width
        let baseHeight = dimmedBuffer.height
        let modalWidth = modalBuffer.width
        let modalHeight = modalBuffer.height

        let horizontalOffset = max(0, (baseWidth - modalWidth) / 2)
        let verticalOffset = max(0, (baseHeight - modalHeight) / 2)

        return dimmedBuffer.composited(
            with: modalBuffer,
            at: (x: horizontalOffset, y: verticalOffset)
        )
    }
}
