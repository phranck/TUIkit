//
//  Panel.swift
//  TUIKit
//
//  A titled container view with optional footer.
//

/// A bordered container with a title and optional footer.
///
/// `Panel` is useful for grouping content with a visible label,
/// similar to a fieldset in HTML or a group box in desktop UIs.
///
/// ## Behavior by Appearance
///
/// - **Standard appearances** (line, rounded, doubleLine, heavy):
///   Title is rendered IN the top border.
///
/// - **Block appearance**:
///   Title becomes a separate header section with darker background.
///
/// ## Examples
///
/// ```swift
/// // Simple panel
/// Panel("Settings") {
///     Text("Option 1")
///     Text("Option 2")
/// }
///
/// // Panel with footer
/// Panel("User Info") {
///     Text("Name: John")
///     Text("Age: 30")
/// } footer: {
///     ButtonRow {
///         Button("Save") { }
///         Button("Cancel") { }
///     }
/// }
///
/// // Customized panel
/// Panel("Settings", borderStyle: .doubleLine, titleColor: .cyan) {
///     Text("Content")
/// }
/// ```
public struct Panel<Content: View, Footer: View>: View {
    /// The title displayed in the header/border.
    public let title: String

    /// The content of the panel.
    public let content: Content
    
    /// The footer content (typically buttons).
    public let footer: Footer?

    /// The shared visual configuration.
    public let config: ContainerConfig

    /// Creates a panel with content and footer.
    ///
    /// - Parameters:
    ///   - title: The title to display.
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: theme accent).
    ///   - padding: The inner padding (default: horizontal 1, vertical 0).
    ///   - showFooterSeparator: Whether to show separator before footer (default: true).
    ///   - content: The main content of the panel.
    ///   - footer: The footer content.
    public init(
        _ title: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 1, vertical: 0),
        showFooterSeparator: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
        self.config = ContainerConfig(
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            padding: padding,
            showFooterSeparator: showFooterSeparator
        )
    }

    public var body: Never {
        fatalError("Panel renders via Renderable")
    }
}

// MARK: - Convenience Initializer (no footer)

extension Panel where Footer == EmptyView {
    /// Creates a panel without a footer.
    ///
    /// - Parameters:
    ///   - title: The title to display in the top border.
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: same as border).
    ///   - padding: The inner padding (default: horizontal 1, vertical 0).
    ///   - content: The content of the panel.
    public init(
        _ title: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 1, vertical: 0),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.footer = nil
        self.config = ContainerConfig(
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            padding: padding,
            showFooterSeparator: true
        )
    }
}

// MARK: - Panel Rendering

extension Panel: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        renderContainer(
            title: title,
            config: config,
            content: content,
            footer: footer,
            context: context
        )
    }
}
