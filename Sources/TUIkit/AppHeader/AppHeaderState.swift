//  🖥️ TUIKit — Terminal UI Kit for Swift
//  AppHeaderState.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

// MARK: - App Header State

/// Manages the app header state for the running application.
///
/// `AppHeaderState` stores the rendered content buffer that views
/// provide via the `.appHeader { ... }` modifier. The ``RenderLoop``
/// reads this buffer each frame and renders it at the top of the terminal.
///
/// When no content is set, the header is hidden and no vertical space
/// is reserved.
///
/// # Usage
///
/// Views set the header content via the `.appHeader` modifier:
///
/// ```swift
/// VStack {
///     Text("Main content")
/// }
/// .appHeader {
///     HStack {
///         Text("My App").bold()
///         Spacer()
///         Text("v1.0")
///     }
/// }
/// ```
final class AppHeaderState: @unchecked Sendable {
    /// The rendered content buffer for the current frame.
    ///
    /// Set by ``AppHeaderModifier`` during rendering. Reset to `nil`
    /// at the start of each render pass by ``RenderLoop``.
    var contentBuffer: FrameBuffer?

    /// The height from the previous render pass, used as an estimate
    /// for layout calculations before the current pass populates the buffer.
    private var previousHeight: Int = 0

    /// Whether the header has content to display.
    var hasContent: Bool {
        guard let buffer = contentBuffer else { return false }
        return !buffer.isEmpty
    }

    /// The height of the header in terminal lines.
    ///
    /// Returns the content height plus one line for the divider.
    /// Returns 0 when no content is set (header hidden).
    var height: Int {
        guard hasContent else { return 0 }
        return (contentBuffer?.height ?? 0) + 1
    }

    /// The estimated height for the current frame, based on the previous
    /// render pass. Available before the view tree is rendered.
    var estimatedHeight: Int {
        previousHeight
    }

    /// Clears the content buffer at the start of each render pass.
    ///
    /// Saves the current height as ``estimatedHeight`` before clearing,
    /// so ``RenderLoop`` can reserve the correct space before the
    /// ``AppHeaderModifier`` populates the new buffer.
    ///
    /// Called by ``RenderLoop`` before rendering the view tree.
    /// If no view sets `.appHeader { ... }` during the pass,
    /// the header remains hidden.
    func beginRenderPass() {
        previousHeight = height
        contentBuffer = nil
    }
}

// MARK: - Environment Key

/// Environment key for the app header state.
private struct AppHeaderKey: EnvironmentKey {
    static let defaultValue = AppHeaderState()
}

extension EnvironmentValues {
    /// The app header state.
    ///
    /// Used internally by ``AppHeaderModifier`` to store the header content
    /// and by ``RenderLoop`` to render it at the top of the terminal.
    var appHeader: AppHeaderState {
        get { self[AppHeaderKey.self] }
        set { self[AppHeaderKey.self] = newValue }
    }
}
