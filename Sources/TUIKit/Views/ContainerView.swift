//
//  ContainerView.swift
//  TUIKit
//
//  A unified container component with Header/Body/Footer architecture.
//

// MARK: - Container Style

/// Configuration options for container appearance.
///
/// Controls separators, backgrounds, and other visual aspects of containers.
public struct ContainerStyle: Sendable {
    /// Whether to show a separator line between header and body.
    ///
    /// Note: Only applies to `Appearance.block`. For other appearances,
    /// the title is rendered in the top border.
    public var showHeaderSeparator: Bool
    
    /// Whether to show a separator line between body and footer.
    public var showFooterSeparator: Bool
    
    /// The border style (nil uses appearance default).
    public var borderStyle: BorderStyle?
    
    /// The border color (nil uses theme default).
    public var borderColor: Color?
    
    /// Creates a container style with the specified options.
    ///
    /// - Parameters:
    ///   - showHeaderSeparator: Show separator after header (default: true).
    ///   - showFooterSeparator: Show separator before footer (default: true).
    ///   - borderStyle: The border style (default: appearance default).
    ///   - borderColor: The border color (default: theme border).
    public init(
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
    
    /// Default container style.
    public static let `default` = ContainerStyle()
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
public struct ContainerView<Content: View, Footer: View>: View {
    /// The container title (rendered in border or header section).
    public let title: String?
    
    /// The title color.
    public let titleColor: Color?
    
    /// The main content.
    public let content: Content
    
    /// The footer content (typically buttons).
    public let footer: Footer?
    
    /// The container style configuration.
    public let style: ContainerStyle
    
    /// The inner padding for the body.
    public let padding: EdgeInsets
    
    /// Creates a container with all options.
    ///
    /// - Parameters:
    ///   - title: The title (optional).
    ///   - titleColor: The title color (default: theme accent).
    ///   - style: The container style configuration.
    ///   - padding: Inner padding for body content.
    ///   - content: The main content.
    ///   - footer: The footer content (optional).
    public init(
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
    
    public var body: Never {
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
    public init(
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
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let appearance = context.environment.appearance
        let isBlockAppearance = appearance.id == .block
        let effectiveBorderStyle = style.borderStyle ?? appearance.borderStyle
        let borderColor = style.borderColor ?? Color.theme.border
        
        // Render body content
        let paddedContent = content.padding(padding)
        let bodyBuffer = TUIKit.renderToBuffer(paddedContent, context: context)
        
        // Render footer if present
        let footerBuffer: FrameBuffer?
        if let footerView = footer {
            let paddedFooter = footerView.padding(EdgeInsets(horizontal: 1, vertical: 0))
            footerBuffer = TUIKit.renderToBuffer(paddedFooter, context: context)
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
        var lines: [String] = []
        
        // Top border (with title if present)
        let topLine: String
        if let titleText = title {
            let titleStyled = ANSIRenderer.colorize(" \(titleText) ", foreground: titleColor ?? Color.theme.accent, bold: true)
            let leftPart = ANSIRenderer.colorize(
                String(borderStyle.topLeft) + String(borderStyle.horizontal),
                foreground: borderColor
            )
            let rightPartLength = max(0, innerWidth - 1 - titleText.count - 2)
            let rightPart = ANSIRenderer.colorize(
                String(repeating: borderStyle.horizontal, count: rightPartLength) + String(borderStyle.topRight),
                foreground: borderColor
            )
            topLine = leftPart + titleStyled + rightPart
        } else {
            topLine = ANSIRenderer.colorize(
                String(borderStyle.topLeft)
                    + String(repeating: borderStyle.horizontal, count: innerWidth)
                    + String(borderStyle.topRight),
                foreground: borderColor
            )
        }
        lines.append(topLine)
        
        // Vertical border characters
        let leftBorder = ANSIRenderer.colorize(String(borderStyle.vertical), foreground: borderColor)
        let rightBorder = ANSIRenderer.colorize(String(borderStyle.vertical), foreground: borderColor)
        
        // Body lines with theme background
        let bodyBg = context.environment.theme.containerBackground
        for line in bodyBuffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let styledContent = ANSIRenderer.applyPersistentBackground(paddedLine, color: bodyBg)
            lines.append(leftBorder + styledContent + ANSIRenderer.reset + rightBorder)
        }
        
        // Footer section (if present)
        if let footerBuf = footerBuffer, !footerBuf.isEmpty {
            // Footer separator
            if style.showFooterSeparator {
                let separatorLine = ANSIRenderer.colorize(
                    String(borderStyle.leftT)
                        + String(repeating: borderStyle.horizontal, count: innerWidth)
                        + String(borderStyle.rightT),
                    foreground: borderColor
                )
                lines.append(separatorLine)
            }
            
            // Footer lines (no background - footer has its own styling)
            for line in footerBuf.lines {
                let paddedLine = line.padToVisibleWidth(innerWidth)
                lines.append(leftBorder + paddedLine + ANSIRenderer.reset + rightBorder)
            }
        }
        
        // Bottom border
        let bottomLine = ANSIRenderer.colorize(
            String(borderStyle.bottomLeft)
                + String(repeating: borderStyle.horizontal, count: innerWidth)
                + String(borderStyle.bottomRight),
            foreground: borderColor
        )
        lines.append(bottomLine)
        
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
        var lines: [String] = []
        
        // Get theme colors for block appearance
        // Header/Footer = darker background
        // Body = lighter background (containerBackground)
        let headerFooterBg = Color.theme.containerHeaderBackground
        let bodyBg = Color.theme.containerBackground
        
        let hasHeader = title != nil
        let hasFooter = footerBuffer != nil && !(footerBuffer?.isEmpty ?? true)
        
        // === TOP BORDER ===
        // ▄▄▄: FG = header/body BG, BG = transparent (App BG shows through)
        let topLine = String(repeating: "▄", count: innerWidth + 2)
        if hasHeader {
            lines.append(ANSIRenderer.colorize(topLine, foreground: headerFooterBg))
        } else {
            lines.append(ANSIRenderer.colorize(topLine, foreground: bodyBg))
        }
        
        // === HEADER SECTION (if title present) ===
        if let titleText = title {
            // █ TITLE █: FG = header BG for █, content has header BG
            let titleStyled = ANSIRenderer.colorize(" \(titleText) ", foreground: titleColor ?? Color.theme.accent, bold: true)
            let paddedTitle = titleStyled.padToVisibleWidth(innerWidth)
            let sideBorder = ANSIRenderer.colorize("█", foreground: headerFooterBg)
            let styledContent = ANSIRenderer.applyPersistentBackground(paddedTitle, color: headerFooterBg)
            lines.append(sideBorder + styledContent + ANSIRenderer.reset + sideBorder)
            
            // Header/Body separator: ▀▀▀
            // FG = header BG, BG = body BG (creates smooth transition)
            if style.showHeaderSeparator {
                let sepLine = String(repeating: "▀", count: innerWidth + 2)
                lines.append(ANSIRenderer.colorize(sepLine, foreground: headerFooterBg, background: bodyBg))
            }
        }
        
        // === BODY LINES ===
        // █ Content █: FG = body BG for █, content has body BG
        for line in bodyBuffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            let sideBorder = ANSIRenderer.colorize("█", foreground: bodyBg)
            let styledContent = ANSIRenderer.applyPersistentBackground(paddedLine, color: bodyBg)
            lines.append(sideBorder + styledContent + ANSIRenderer.reset + sideBorder)
        }
        
        // === FOOTER SECTION (if present) ===
        if let footerBuf = footerBuffer, !footerBuf.isEmpty {
            // Body/Footer separator: ▄▄▄
            // FG = footer BG, BG = body BG (creates smooth transition)
            if style.showFooterSeparator {
                let sepLine = String(repeating: "▄", count: innerWidth + 2)
                lines.append(ANSIRenderer.colorize(sepLine, foreground: headerFooterBg, background: bodyBg))
            }
            
            // █ Footer █: FG = footer BG for █, content has footer BG
            for line in footerBuf.lines {
                let paddedLine = line.padToVisibleWidth(innerWidth)
                let sideBorder = ANSIRenderer.colorize("█", foreground: headerFooterBg)
                let styledContent = ANSIRenderer.applyPersistentBackground(paddedLine, color: headerFooterBg)
                lines.append(sideBorder + styledContent + ANSIRenderer.reset + sideBorder)
            }
        }
        
        // === BOTTOM BORDER ===
        // ▀▀▀: FG = footer/body BG, BG = transparent (App BG shows through)
        let bottomLine = String(repeating: "▀", count: innerWidth + 2)
        if hasFooter {
            lines.append(ANSIRenderer.colorize(bottomLine, foreground: headerFooterBg))
        } else {
            lines.append(ANSIRenderer.colorize(bottomLine, foreground: bodyBg))
        }
        
        return FrameBuffer(lines: lines)
    }
}
