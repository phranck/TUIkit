//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Card.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A padded, optionally titled container with background support.
///
/// `Card` is the most feature-rich of the simple containers. It combines
/// border, inner padding, optional background color, optional title, and
/// optional footer into one view. Everything is optional — a bare `Card`
/// with no title or footer still adds padding (default: 1 on all sides),
/// giving content room to breathe inside the border.
///
/// ## How Card Differs from Box and Panel
///
/// | Feature | Box | Card | Panel |
/// |---------|-----|------|-------|
/// | Border | Yes | Yes | Yes |
/// | Padding | No | **Yes (default: 1 all sides)** | Yes (default: horizontal 1) |
/// | Background color | No | **Optional** | No |
/// | Title | No | **Optional** | Required |
/// | Footer | No | **Optional** | Optional |
/// | Rendering | Composite (`body`) | Primitive (`Renderable`) | Primitive (`Renderable`) |
///
/// Use `Card` when content needs **visual padding and optional structure**.
/// A simple bordered view is too tight (no padding), and a ``Panel`` forces you to
/// provide a title. `Card` sits in between: comfortable defaults, with the
/// option to add a title, footer, and background as needed.
///
/// ## Typical Use Cases
///
/// - Displaying a block of information (user profile, system status)
/// - Self-contained content sections in a dashboard layout
/// - Forms or detail views with an action footer (Save / Cancel)
/// - Highlighted content with a distinct background color
///
/// ## Structure
///
/// - **Header**: Optional title (rendered in the top border for standard
///   appearances)
/// - **Body**: Main content, wrapped in configurable padding
/// - **Footer**: Optional, typically ``Button`` or ``ButtonRow``
///
/// ## Examples
///
/// ```swift
/// // Simple card — padding, border, no title
/// Card {
///     Text("Card content goes here")
/// }
///
/// // Card with title
/// Card(title: "Card Title") {
///     Text("Card content")
/// }
///
/// // Card with title, footer, and background
/// Card(title: "User Info", backgroundColor: .palette.background) {
///     Text("Name: John")
///     Text("Email: john@example.com")
/// } footer: {
///     Button("Edit") { }
/// }
///
/// // Styled card
/// Card(borderStyle: .doubleLine, borderColor: .cyan) {
///     Text("Styled Card")
/// }
/// ```
public struct Card<Content: View, Footer: View>: View {
    /// The card title (optional).
    let title: String?

    /// The content of the card.
    let content: Content

    /// The footer content (optional).
    let footer: Footer?

    /// The shared visual configuration.
    let config: ContainerConfig

    /// The background color (nil for transparent).
    let backgroundColor: Color?

    /// Creates a card with all options including footer.
    ///
    /// - Parameters:
    ///   - title: The title (optional).
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: theme accent).
    ///   - backgroundColor: The background color (default: nil).
    ///   - padding: The inner padding (default: 1 on all sides).
    ///   - showFooterSeparator: Whether to show separator before footer (default: true).
    ///   - content: The content of the card.
    ///   - footer: The footer content.
    public init(
        title: String? = nil,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        backgroundColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(all: 1),
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
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        _CardCore(
            title: title,
            content: content,
            footer: footer,
            config: config,
            backgroundColor: backgroundColor
        )
    }
}

// MARK: - Equatable Conformance

extension Card: @preconcurrency Equatable where Content: Equatable, Footer: Equatable {
    public static func == (lhs: Card<Content, Footer>, rhs: Card<Content, Footer>) -> Bool {
        lhs.title == rhs.title &&
        lhs.content == rhs.content &&
        lhs.footer == rhs.footer &&
        lhs.config == rhs.config &&
        lhs.backgroundColor == rhs.backgroundColor
    }
}

// MARK: - Internal Core View

/// Internal view that handles the actual rendering of Card.
private struct _CardCore<Content: View, Footer: View>: View, Renderable {
    let title: String?
    let content: Content
    let footer: Footer?
    let config: ContainerConfig
    let backgroundColor: Color?

    var body: Never {
        fatalError("_CardCore renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Wrap content with background if specified
        let bodyContent: AnyView
        if let bgColor = backgroundColor {
            bodyContent = AnyView(content.background(bgColor))
        } else {
            bodyContent = AnyView(content)
        }

        return renderContainer(
            title: title,
            config: config,
            content: bodyContent,
            footer: footer,
            context: context
        )
    }
}

// MARK: - Convenience Initializer (no footer)

extension Card where Footer == EmptyView {
    /// Creates a card without a footer.
    ///
    /// - Parameters:
    ///   - title: The title (optional).
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: theme accent).
    ///   - backgroundColor: The background color (default: nil).
    ///   - padding: The inner padding (default: 1 on all sides).
    ///   - content: The content of the card.
    public init(
        title: String? = nil,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        backgroundColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(all: 1),
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
        self.backgroundColor = backgroundColor
    }
}

// MARK: - Convenience Initializer (no title, no footer - backward compatible)

extension Card where Footer == EmptyView {
    /// Creates a simple card without title or footer.
    ///
    /// This is the most basic card form, just wrapping content in a border.
    ///
    /// - Parameters:
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - backgroundColor: The background color (default: nil).
    ///   - padding: The inner padding (default: 1 on all sides).
    ///   - content: The content of the card.
    public init(
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        backgroundColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(all: 1),
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.content = content()
        self.footer = nil
        self.config = ContainerConfig(
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: nil,
            padding: padding,
            showFooterSeparator: false
        )
        self.backgroundColor = backgroundColor
    }
}
