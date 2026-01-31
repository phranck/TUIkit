//
//  Panel.swift
//  TUIkit
//
//  A titled container view with optional footer.
//

/// A labeled container — always has a title, optionally a footer.
///
/// `Panel` groups content under a visible heading. The title is mandatory,
/// which makes it the right choice when the user needs to know *what* a
/// section contains at a glance. Think of it as an HTML `<fieldset>` or
/// a desktop "group box".
///
/// ## How Panel Differs from Box and Card
///
/// | Feature | Box | Card | Panel |
/// |---------|-----|------|-------|
/// | Border | Yes | Yes | Yes |
/// | Padding | No | Yes (default: 1 all sides) | **Yes (default: horizontal 1)** |
/// | Background color | No | Optional | **No** |
/// | Title | No | Optional | **Required** |
/// | Footer | No | Optional | **Optional** |
/// | Rendering | Composite (`body`) | Primitive (`Renderable`) | Primitive (`Renderable`) |
///
/// Use `Panel` when the section **must have a label**. A ``Box`` has no
/// title at all, and a ``Card`` makes it optional — so if you skip the
/// title on a Card, there's nothing telling the user what they're looking
/// at. Panel enforces that every instance has a visible heading.
///
/// Note that Panel has **less default padding** than Card (horizontal 1
/// only, no vertical) and does **not** support background colors. This
/// keeps it lightweight — if you need a background or generous padding,
/// use ``Card`` instead.
///
/// ## Typical Use Cases
///
/// - Settings or configuration sections ("Network", "Display", "Audio")
/// - Grouping related form fields under a heading
/// - Sidebar sections with a labeled header
/// - Any place where a named region helps orientation
///
/// ## Behavior by Appearance
///
/// - **Standard appearances** (line, rounded, doubleLine, heavy):
///   Title is rendered **in the top border** (e.g. `┤ Settings ├`).
///
/// - **Block appearance**:
///   Title becomes a separate header section with darker background.
///
/// ## Examples
///
/// ```swift
/// // Simple panel — title is the first argument
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
            showFooterSeparator: false
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
