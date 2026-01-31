//
//  ContainerView.swift
//  TUIkit
//
//  A unified container component with Header/Body/Footer architecture.
//

// MARK: - Container Config

/// Shared visual configuration for container-type views.
///
/// Groups the common appearance properties used by ``Alert``, ``Dialog``,
/// ``Panel``, and ``Card``. Each view stores a `ContainerConfig` instead
/// of repeating the same five properties.
///
/// # Example
///
/// ```swift
/// let config = ContainerConfig(
///     borderStyle: .doubleLine,
///     borderColor: .cyan,
///     titleColor: .cyan
/// )
/// ```
struct ContainerConfig: Sendable {
    /// The border style (nil uses appearance default).
    var borderStyle: BorderStyle?

    /// The border color (nil uses theme default).
    var borderColor: Color?

    /// The title color (nil uses theme accent).
    var titleColor: Color?

    /// The inner padding for the body content.
    var padding: EdgeInsets

    /// Whether to show a separator line between body and footer.
    var showFooterSeparator: Bool

    /// Creates a container configuration.
    ///
    /// - Parameters:
    ///   - borderStyle: The border style (default: appearance default).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: theme accent).
    ///   - padding: The inner padding (default: horizontal 1, vertical 0).
    ///   - showFooterSeparator: Show separator before footer (default: true).
    init(
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 1, vertical: 0),
        showFooterSeparator: Bool = true
    ) {
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.titleColor = titleColor
        self.padding = padding
        self.showFooterSeparator = showFooterSeparator
    }

    /// Default configuration.
    static let `default` = Self()
}

// MARK: - Container Style

/// Configuration options for container appearance.
///
/// Controls separators, backgrounds, and other visual aspects of containers.
struct ContainerStyle: Sendable {
    /// Whether to show a separator line between header and body.
    ///
    /// Note: Only applies to `Appearance.block`. For other appearances,
    /// the title is rendered in the top border.
    var showHeaderSeparator: Bool

    /// Whether to show a separator line between body and footer.
    var showFooterSeparator: Bool

    /// The border style (nil uses appearance default).
    var borderStyle: BorderStyle?

    /// The border color (nil uses theme default).
    var borderColor: Color?

    /// Creates a container style with the specified options.
    ///
    /// - Parameters:
    ///   - showHeaderSeparator: Show separator after header (default: true).
    ///   - showFooterSeparator: Show separator before footer (default: true).
    ///   - borderStyle: The border style (default: appearance default).
    ///   - borderColor: The border color (default: theme border).
    init(
        showHeaderSeparator: Bool = true,
        showFooterSeparator: Bool = true,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil
    ) {
        self.showHeaderSeparator = showHeaderSeparator
        self.showFooterSeparator = showFooterSeparator
        self.borderStyle = borderStyle
        self.borderColor = borderColor
    }

    /// Creates a `ContainerStyle` from a ``ContainerConfig``.
    ///
    /// - Parameter config: The container configuration to use.
    init(from config: ContainerConfig) {
        self.showHeaderSeparator = true
        self.showFooterSeparator = config.showFooterSeparator
        self.borderStyle = config.borderStyle
        self.borderColor = config.borderColor
    }

    /// Default container style.
    static let `default` = Self()
}

// MARK: - Render Helper

/// Renders a ``ContainerView`` from a ``ContainerConfig`` and content/footer views.
///
/// Eliminates the duplicated `if/else` footer pattern found in Alert, Dialog,
/// Panel, and Card.
///
/// - Parameters:
///   - title: The container title (optional).
///   - config: The shared visual configuration.
///   - content: The body content view.
///   - footer: The footer view (optional).
///   - context: The current render context.
/// - Returns: The rendered frame buffer.
internal func renderContainer<Content: View, Footer: View>(
    title: String?,
    config: ContainerConfig,
    content: Content,
    footer: Footer?,
    context: RenderContext
) -> FrameBuffer {
    let hasFooter = footer != nil
    let style = ContainerStyle(
        showHeaderSeparator: true,
        showFooterSeparator: hasFooter && config.showFooterSeparator,
        borderStyle: config.borderStyle,
        borderColor: config.borderColor
    )

    let container = ContainerView(
        title: title,
        titleColor: config.titleColor,
        style: style,
        padding: config.padding
    ) {
        content
    } footer: {
        if let footerView = footer {
            footerView
        }
    }
    return container.renderToBuffer(context: context)
}

// MARK: - Container View

/// A unified container with optional header, body, and footer sections.
///
/// `ContainerView` provides a consistent structure for all container-type views
/// like Panel, Card, Alert, and Dialog. It handles the rendering logic for
/// borders, separators, and section backgrounds.
///
/// ## Behavior by Appearance
///
/// - **Standard appearances** (line, rounded, doubleLine, heavy):
///   Title is rendered IN the top border. Footer is a separate section.
///
/// - **Block appearance**:
///   Header is a separate section with darker background.
///   Body and border share the same background color.
///   Footer has darker background like header.
///
/// ## Example
///
/// ```swift
/// ContainerView(
///     title: "Settings",
///     style: ContainerStyle(showFooterSeparator: true)
/// ) {
///     Text("Option 1")
///     Text("Option 2")
/// } footer: {
///     ButtonRow {
///         Button("Save") { }
///         Button("Cancel") { }
///     }
/// }
/// ```
struct ContainerView<Content: View, Footer: View>: View {
    /// The container title (rendered in border or header section).
    let title: String?

    /// The title color.
    let titleColor: Color?

    /// The main content.
    let content: Content

    /// The footer content (typically buttons).
    let footer: Footer?

    /// The container style configuration.
    let style: ContainerStyle

    /// The inner padding for the body.
    let padding: EdgeInsets

    /// Creates a container with all options.
    ///
    /// - Parameters:
    ///   - title: The title (optional).
    ///   - titleColor: The title color (default: theme accent).
    ///   - style: The container style configuration.
    ///   - padding: Inner padding for body content.
    ///   - content: The main content.
    ///   - footer: The footer content (optional).
    init(
        title: String? = nil,
        titleColor: Color? = nil,
        style: ContainerStyle = .default,
        padding: EdgeInsets = EdgeInsets(horizontal: 1, vertical: 0),
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.titleColor = titleColor
        self.style = style
        self.padding = padding
        self.content = content()
        self.footer = footer()
    }

    var body: Never {
        fatalError("ContainerView renders via Renderable")
    }
}

// MARK: - Convenience Initializer (no footer)

extension ContainerView where Footer == EmptyView {
    /// Creates a container without a footer.
    ///
    /// - Parameters:
    ///   - title: The title (optional).
    ///   - titleColor: The title color (default: theme accent).
    ///   - style: The container style configuration.
    ///   - padding: Inner padding for body content.
    ///   - content: The main content.
    init(
        title: String? = nil,
        titleColor: Color? = nil,
        style: ContainerStyle = .default,
        padding: EdgeInsets = EdgeInsets(horizontal: 1, vertical: 0),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.titleColor = titleColor
        self.style = style
        self.padding = padding
        self.content = content()
        self.footer = nil
    }
}

// MARK: - Rendering

extension ContainerView: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let appearance = context.environment.appearance
        let isBlockAppearance = appearance.rawId == .block
        let effectiveBorderStyle = style.borderStyle ?? appearance.borderStyle
        let palette = context.environment.palette
        let borderColor = style.borderColor?.resolve(with: palette) ?? palette.border

        // Render body content
        let paddedContent = content.padding(padding)
        let bodyBuffer = TUIkit.renderToBuffer(paddedContent, context: context)

        // Render footer if present
        let footerBuffer: FrameBuffer?
        if let footerView = footer {
            let paddedFooter = footerView.padding(EdgeInsets(horizontal: 1, vertical: 0))
            footerBuffer = TUIkit.renderToBuffer(paddedFooter, context: context)
        } else {
            footerBuffer = nil
        }

        // Calculate inner width
        let titleWidth = title.map { $0.count + 4 } ?? 0  // " Title " + borders
        let bodyWidth = bodyBuffer.width
        let footerWidth = footerBuffer?.width ?? 0
        let innerWidth = max(titleWidth, bodyWidth, footerWidth)

        if isBlockAppearance {
            return renderBlockStyle(
                bodyBuffer: bodyBuffer,
                footerBuffer: footerBuffer,
                innerWidth: innerWidth,
                borderStyle: effectiveBorderStyle,
                borderColor: borderColor,
                context: context
            )
        } else {
            return renderStandardStyle(
                bodyBuffer: bodyBuffer,
                footerBuffer: footerBuffer,
                innerWidth: innerWidth,
                borderStyle: effectiveBorderStyle,
                borderColor: borderColor,
                context: context
            )
        }
    }

    // MARK: - Standard Style Rendering

    /// Renders with title in top border (line, rounded, doubleLine, heavy).
    private func renderStandardStyle(
        bodyBuffer: FrameBuffer,
        footerBuffer: FrameBuffer?,
        innerWidth: Int,
        borderStyle: BorderStyle,
        borderColor: Color,
        context: RenderContext
    ) -> FrameBuffer {
        let palette = context.environment.palette
        var lines: [String] = []

        // Top border (with title if present)
        if let titleText = title {
            lines.append(
                BorderRenderer.standardTopBorder(
                    style: borderStyle,
                    innerWidth: innerWidth,
                    color: borderColor,
                    title: titleText,
                    titleColor: titleColor?.resolve(with: palette) ?? palette.accent
                )
            )
        } else {
            lines.append(
                BorderRenderer.standardTopBorder(
                    style: borderStyle,
                    innerWidth: innerWidth,
                    color: borderColor
                )
            )
        }

        // Body lines with theme background
        let bodyBg = context.environment.palette.blockSurfaceBackground
        for line in bodyBuffer.lines {
            lines.append(
                BorderRenderer.standardContentLine(
                    content: line,
                    innerWidth: innerWidth,
                    style: borderStyle,
                    color: borderColor,
                    backgroundColor: bodyBg
                )
            )
        }

        // Footer section (if present)
        if let footerBuf = footerBuffer, !footerBuf.isEmpty {
            if style.showFooterSeparator {
                lines.append(
                    BorderRenderer.standardDivider(
                        style: borderStyle,
                        innerWidth: innerWidth,
                        color: borderColor
                    )
                )
            }

            // Footer lines (no background - footer has its own styling)
            for line in footerBuf.lines {
                lines.append(
                    BorderRenderer.standardContentLine(
                        content: line,
                        innerWidth: innerWidth,
                        style: borderStyle,
                        color: borderColor
                    )
                )
            }
        }

        // Bottom border
        lines.append(
            BorderRenderer.standardBottomBorder(
                style: borderStyle,
                innerWidth: innerWidth,
                color: borderColor
            )
        )

        return FrameBuffer(lines: lines)
    }

    // MARK: - Block Style Rendering

    /// Renders with half-block characters for smooth visual edges.
    ///
    /// Block style design:
    /// ```
    /// ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ← Top: ▄, FG = header BG, BG = App BG (transparent)
    /// █ HEADER         █  ← Sides: █, FG = header BG, content has header BG
    /// ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀  ← Separator: ▀, FG = header BG, BG = body BG
    /// █ BODY           █  ← Body has container BG (slightly brighter)
    /// █                █
    /// ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄  ← Footer sep: ▄, FG = footer BG, BG = body BG
    /// █ FOOTER         █  ← Sides: █, FG = footer BG, content has footer BG
    /// ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀  ← Bottom: ▀, FG = footer BG, BG = App BG (transparent)
    /// ```
    private func renderBlockStyle(
        bodyBuffer: FrameBuffer,
        footerBuffer: FrameBuffer?,
        innerWidth: Int,
        borderStyle: BorderStyle,
        borderColor: Color,
        context: RenderContext
    ) -> FrameBuffer {
        let palette = context.environment.palette
        var lines: [String] = []

        // Get palette colors for block appearance
        // Header/Footer = darker background (surfaceHeaderBackground)
        // Body = lighter background (surfaceBackground)
        let headerFooterBg = palette.blockSurfaceHeaderBackground
        let bodyBg = palette.blockSurfaceBackground

        let hasHeader = title != nil
        let hasFooter = footerBuffer != nil && !(footerBuffer?.isEmpty ?? true)

        // === TOP BORDER ===
        lines.append(
            BorderRenderer.blockTopBorder(
                innerWidth: innerWidth,
                color: hasHeader ? headerFooterBg : bodyBg
            )
        )

        // === HEADER SECTION (if title present) ===
        if let titleText = title {
            let titleStyled = ANSIRenderer.colorize(" \(titleText) ", foreground: titleColor?.resolve(with: palette) ?? palette.accent, bold: true)
            lines.append(
                BorderRenderer.blockContentLine(
                    content: titleStyled,
                    innerWidth: innerWidth,
                    sectionColor: headerFooterBg
                )
            )

            if style.showHeaderSeparator {
                lines.append(
                    BorderRenderer.blockSeparator(
                        innerWidth: innerWidth,
                        foregroundColor: headerFooterBg,
                        backgroundColor: bodyBg
                    )
                )
            }
        }

        // === BODY LINES ===
        for line in bodyBuffer.lines {
            lines.append(
                BorderRenderer.blockContentLine(
                    content: line,
                    innerWidth: innerWidth,
                    sectionColor: bodyBg
                )
            )
        }

        // === FOOTER SECTION (if present) ===
        if let footerBuf = footerBuffer, !footerBuf.isEmpty {
            if style.showFooterSeparator {
                lines.append(
                    BorderRenderer.blockSeparator(
                        innerWidth: innerWidth,
                        character: BorderStyle.blockFooterSeparator,
                        foregroundColor: headerFooterBg,
                        backgroundColor: bodyBg
                    )
                )
            }

            for line in footerBuf.lines {
                lines.append(
                    BorderRenderer.blockContentLine(
                        content: line,
                        innerWidth: innerWidth,
                        sectionColor: headerFooterBg
                    )
                )
            }
        }

        // === BOTTOM BORDER ===
        lines.append(
            BorderRenderer.blockBottomBorder(
                innerWidth: innerWidth,
                color: hasFooter ? headerFooterBg : bodyBg
            )
        )

        return FrameBuffer(lines: lines)
    }
}
