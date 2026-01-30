//
//  Renderable.swift
//  TUIKit
//
//  Protocol for views that can render themselves directly.
//

/// A protocol for views that can render themselves into a `FrameBuffer`.
///
/// Primitive views implement this protocol to produce their text output
/// as a buffer. Layout containers then combine child buffers to produce
/// the final output.
public protocol Renderable {
    /// Renders this view into a `FrameBuffer`.
    ///
    /// - Parameter context: The rendering context with available size info.
    /// - Returns: A buffer containing the rendered output.
    func renderToBuffer(context: RenderContext) -> FrameBuffer
}

/// The context for rendering a view.
///
/// Contains layout constraints, terminal information, environment values,
/// and the central ``TUIContext`` that views need to determine their size,
/// content, and access framework services.
public struct RenderContext {
    /// The target terminal.
    public let terminal: Terminal

    /// The available width in characters.
    public var availableWidth: Int

    /// The available height in lines.
    public var availableHeight: Int

    /// The environment values for this render pass.
    public var environment: EnvironmentValues

    /// The central dependency container for framework services.
    ///
    /// Provides access to lifecycle tracking, key event dispatch,
    /// and preference storage without relying on singletons.
    public let tuiContext: TUIContext

    /// Creates a new RenderContext.
    ///
    /// - Parameters:
    ///   - terminal: The target terminal.
    ///   - availableWidth: The available width (defaults to terminal width).
    ///   - availableHeight: The available height (defaults to terminal height).
    ///   - environment: The environment values (defaults to empty).
    ///   - tuiContext: The TUI context (defaults to a fresh instance).
    public init(
        terminal: Terminal = .shared,
        availableWidth: Int? = nil,
        availableHeight: Int? = nil,
        environment: EnvironmentValues = EnvironmentValues(),
        tuiContext: TUIContext = TUIContext()
    ) {
        self.terminal = terminal
        self.availableWidth = availableWidth ?? terminal.width
        self.availableHeight = availableHeight ?? terminal.height
        self.environment = environment
        self.tuiContext = tuiContext
    }

    /// Creates a new context with the same terminal and size but different environment.
    ///
    /// - Parameter environment: The new environment values.
    /// - Returns: A new RenderContext with the updated environment.
    public func withEnvironment(_ environment: EnvironmentValues) -> Self {
        Self(
            terminal: terminal,
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            environment: environment,
            tuiContext: tuiContext
        )
    }
}

// MARK: - Rendering Helper

/// Renders any View into a FrameBuffer by checking for Renderable conformance
/// or recursively rendering the body.
///
/// - Parameters:
///   - view: The view to render.
///   - context: The rendering context.
/// - Returns: A FrameBuffer with the rendered content.
public func renderToBuffer<V: View>(_ view: V, context: RenderContext) -> FrameBuffer {
    if let renderable = view as? Renderable {
        return renderable.renderToBuffer(context: context)
    }

    // Composite view: render its body
    if V.Body.self != Never.self {
        return renderToBuffer(view.body, context: context)
    }

    return FrameBuffer()
}
