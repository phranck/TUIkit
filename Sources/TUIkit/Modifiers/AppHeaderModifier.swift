//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppHeaderModifier.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - AppHeaderModifier

/// A modifier that declares the app header content for a view.
///
/// The header content is rendered to a ``FrameBuffer`` and stored in
/// `AppHeaderState` during the render pass. The `RenderLoop` then
/// renders it at the top of the terminal, outside the view tree.
///
/// If multiple views set `.appHeader { ... }`, the last one rendered wins.
///
/// # Example
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
struct AppHeaderModifier<Content: View, Header: View>: View {
    /// The content view.
    let content: Content

    /// The header content builder.
    let header: Header

    var body: Never {
        fatalError("AppHeaderModifier renders via Renderable")
    }
}

// MARK: - Renderable

extension AppHeaderModifier: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let appHeader = context.environment.appHeader

        // Render the header content to a buffer and store it in state.
        // The RenderLoop will pick it up and render it separately.
        let headerBuffer = TUIkit.renderToBuffer(header, context: context)
        appHeader.contentBuffer = headerBuffer

        return TUIkit.renderToBuffer(content, context: context)
    }
}
