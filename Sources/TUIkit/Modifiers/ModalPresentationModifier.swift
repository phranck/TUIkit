//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ModalPresentationModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

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
    /// A stable section ID for modal focus sections.
    private static var modalSectionID: String { "__modal__" }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // If not presented, just return base content
        guard isPresented.wrappedValue else {
            return TUIkit.renderToBuffer(content, context: context)
        }

        let focusManager = context.environment.focusManager

        // Render dimmed base with an isolated context.
        // The base content's buttons and key handlers register into a
        // throwaway FocusManager and KeyEventDispatcher so they don't
        // interfere with the modal's interactive elements.
        let dimmedBase = DimmedModifier(content: content)
        let isolatedContext = context.isolatedForBackground()
        let dimmedBuffer = TUIkit.renderToBuffer(dimmedBase, context: isolatedContext)

        // Register a modal focus section and activate it.
        // This replaces the previous focusManager.clear() approach.
        // The modal section becomes the active section, so Tab/arrows
        // only navigate within the modal's focusable elements.
        let sectionID = Self.modalSectionID
        if !context.isMeasuring {
            focusManager.registerSection(id: sectionID)
            focusManager.activateSection(id: sectionID)
        }

        // Set the modal section in the context so child focusables
        // (buttons in the modal) register in the modal section.
        var modalContext = context
        modalContext.environment.activeFocusSectionID = sectionID

        let modalBuffer = TUIkit.renderToBuffer(modal, context: modalContext)

        guard !dimmedBuffer.isEmpty else {
            return modalBuffer
        }

        guard !modalBuffer.isEmpty else {
            return dimmedBuffer
        }

        // Center relative to the full terminal area, not the content size.
        let screenWidth = context.availableWidth
        let screenHeight = context.availableHeight
        let modalWidth = modalBuffer.width
        let modalHeight = modalBuffer.height

        let horizontalOffset = max(0, (screenWidth - modalWidth) / 2)
        let verticalOffset = max(0, (screenHeight - modalHeight) / 2 - 2)

        return dimmedBuffer.composited(
            with: modalBuffer,
            at: (x: horizontalOffset, y: verticalOffset)
        )
    }
}
