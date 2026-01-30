//
//  Card.swift
//  TUIKit
//
//  A styled container view with optional header, content, and footer.
//

/// A container view that displays content in a card-like appearance.
///
/// `Card` combines border, background, and padding into a single
/// convenient container. It supports optional title (header) and footer.
///
/// ## Structure
///
/// - **Header**: Optional title (in border for standard appearances, separate section for block)
/// - **Body**: Main content
/// - **Footer**: Optional, typically buttons
///
/// ## Examples
///
/// ```swift
/// // Simple card (no title)
/// Card {
///     Text("Card content goes here")
/// }
///
/// // Card with title
/// Card(title: "Card Title") {
///     Text("Card content")
/// }
///
/// // Card with title and footer
/// Card(title: "User Info") {
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
    public let title: String?
    
    /// The content of the card.
    public let content: Content
    
    /// The footer content (optional).
    public let footer: Footer?

    /// The shared visual configuration.
    public let config: ContainerConfig

    /// The background color (nil for transparent).
    public let backgroundColor: Color?

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

    public var body: Never {
        fatalError("Card renders via Renderable")
    }
}

// MARK: - Rendering

extension Card: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
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
