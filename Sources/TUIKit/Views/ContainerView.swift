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
        let reset = "\u{1B}[0m"
        
        // Top border (with title if present)
        let topLine: String
        if let titleText = title {
            let titleStyled = colorize(" \(titleText) ", with: titleColor ?? Color.theme.accent, bold: true)
            let leftPart = colorize(
                String(borderStyle.topLeft) + String(borderStyle.horizontal),
                with: borderColor
            )
            let rightPartLength = max(0, innerWidth - 1 - titleText.count - 2)
            let rightPart = colorize(
                String(repeating: borderStyle.horizontal, count: rightPartLength) + String(borderStyle.topRight),
                with: borderColor
            )
            topLine = leftPart + titleStyled + rightPart
        } else {
            topLine = colorize(
                String(borderStyle.topLeft)
                    + String(repeating: borderStyle.horizontal, count: innerWidth)
                    + String(borderStyle.topRight),
                with: borderColor
            )
        }
        lines.append(topLine)
        
        // Vertical border characters
        let leftBorder = colorize(String(borderStyle.vertical), with: borderColor)
        let rightBorder = colorize(String(borderStyle.vertical), with: borderColor)
        
        // Body lines
        for line in bodyBuffer.lines {
            let paddedLine = line.padToVisibleWidth(innerWidth)
            lines.append(leftBorder + paddedLine + reset + rightBorder)
        }
        
        // Footer section (if present)
        if let footerBuf = footerBuffer, !footerBuf.isEmpty {
            // Footer separator
            if style.showFooterSeparator {
                let separatorLine = colorize(
                    String(borderStyle.leftT)
                        + String(repeating: borderStyle.horizontal, count: innerWidth)
                        + String(borderStyle.rightT),
                    with: borderColor
                )
                lines.append(separatorLine)
            }
            
            // Footer lines
            for line in footerBuf.lines {
                let paddedLine = line.padToVisibleWidth(innerWidth)
                lines.append(leftBorder + paddedLine + reset + rightBorder)
            }
        }
        
        // Bottom border
        let bottomLine = colorize(
            String(borderStyle.bottomLeft)
                + String(repeating: borderStyle.horizontal, count: innerWidth)
                + String(borderStyle.bottomRight),
            with: borderColor
        )
        lines.append(bottomLine)
        
        return FrameBuffer(lines: lines)
    }
    
    // MARK: - Block Style Rendering
    
    /// Renders with half-block characters for smooth visual edges.
    ///
    /// Block style uses:
    /// - `▄` (lower half) for top edge and body/footer separator
    /// - `▀` (upper half) for bottom edge and header/body separator
    /// - `█` (full block) for side borders
    ///
    /// The separator characters use special coloring for seamless transitions:
    /// - Header/Body separator: FG = header background, BG = body background (transparent)
    /// - Body/Footer separator: FG = footer background, BG = body background (transparent)
    ///
    /// Header and footer sections have a darker background color.
    /// Body section is transparent (uses theme background).
    private func renderBlockStyle(
        bodyBuffer: FrameBuffer,
        footerBuffer: FrameBuffer?,
        innerWidth: Int,
        borderStyle: BorderStyle,
        borderColor: Color,
        context: RenderContext
    ) -> FrameBuffer {
        var lines: [String] = []
        let reset = "\u{1B}[0m"
        
        // Get theme colors for block appearance
        let headerFooterBackground = Color.theme.containerHeaderBackground
        
        // Characters for block style
        let topChar: Character = "▄"      // Lower half block for top
        let bottomChar: Character = "▀"   // Upper half block for bottom
        let headerSepChar: Character = "▀"    // Upper half for header/body separator
        let footerSepChar: Character = "▄"    // Lower half for body/footer separator
        let vertical = String(borderStyle.vertical)  // Full block █
        
        // Helper to render a content line with side borders
        func renderLine(_ content: String, withBackground: Bool = false) -> String {
            let paddedContent = content.padToVisibleWidth(innerWidth)
            if withBackground {
                // With darker header/footer background
                let leftBorder = colorize(vertical, with: borderColor, backgroundColor: headerFooterBackground)
                let rightBorder = colorize(vertical, with: borderColor, backgroundColor: headerFooterBackground)
                let styledContent = applyBackground(paddedContent, background: headerFooterBackground)
                return leftBorder + styledContent + reset + rightBorder
            } else {
                // Transparent body (no extra background)
                let leftBorder = colorize(vertical, with: borderColor)
                let rightBorder = colorize(vertical, with: borderColor)
                return leftBorder + paddedContent + reset + rightBorder
            }
        }
        
        // Helper to render top/bottom border line
        func renderEdgeLine(_ char: Character, withBackground: Bool = false) -> String {
            let line = String(repeating: char, count: innerWidth + 2)
            if withBackground {
                return colorize(line, with: borderColor, backgroundColor: headerFooterBackground)
            } else {
                return colorize(line, with: borderColor)
            }
        }
        
        // Helper to render separator with special coloring for seamless transition
        // FG = section background color, BG = body background (transparent/none)
        func renderSeparator(_ char: Character, sectionBackground: Color) -> String {
            let line = String(repeating: char, count: innerWidth + 2)
            // Foreground = section's background color (creates the visual "belonging")
            // Background = transparent (body background shows through)
            return colorize(line, with: sectionBackground)
        }
        
        // === TOP BORDER ===
        // ▄▄▄▄▄▄▄▄▄▄ (foreground = header bg if header exists, otherwise border color)
        let hasHeader = title != nil
        if hasHeader {
            // Top edge colored with header background to blend with header
            lines.append(colorize(String(repeating: topChar, count: innerWidth + 2), with: headerFooterBackground))
        } else {
            lines.append(renderEdgeLine(topChar, withBackground: false))
        }
        
        // === HEADER SECTION (if title present) ===
        if let titleText = title {
            // █ TITLE █ (with darker background)
            let titleStyled = colorize(" \(titleText) ", with: titleColor ?? Color.theme.accent, bold: true)
            lines.append(renderLine(titleStyled, withBackground: true))
            
            // Header/Body separator: ▀▀▀▀▀▀▀▀▀▀
            // FG = header background, BG = transparent (body background)
            if style.showHeaderSeparator {
                lines.append(renderSeparator(headerSepChar, sectionBackground: headerFooterBackground))
            }
        }
        
        // === BODY LINES ===
        // █ Content █ (transparent - no extra background)
        for line in bodyBuffer.lines {
            lines.append(renderLine(line, withBackground: false))
        }
        
        // === FOOTER SECTION (if present) ===
        if let footerBuf = footerBuffer, !footerBuf.isEmpty {
            // Body/Footer separator: ▄▄▄▄▄▄▄▄▄▄
            // FG = footer background, BG = transparent (body background)
            if style.showFooterSeparator {
                lines.append(renderSeparator(footerSepChar, sectionBackground: headerFooterBackground))
            }
            
            // █ Footer █ (with darker background)
            for line in footerBuf.lines {
                lines.append(renderLine(line, withBackground: true))
            }
        }
        
        // === BOTTOM BORDER ===
        // ▀▀▀▀▀▀▀▀▀▀ (foreground = footer bg if footer exists, otherwise border color)
        let hasFooter = footerBuffer != nil && !(footerBuffer?.isEmpty ?? true)
        if hasFooter {
            // Bottom edge colored with footer background to blend with footer
            lines.append(colorize(String(repeating: bottomChar, count: innerWidth + 2), with: headerFooterBackground))
        } else {
            lines.append(renderEdgeLine(bottomChar, withBackground: false))
        }
        
        return FrameBuffer(lines: lines)
    }
    
    // MARK: - Helper Methods
    
    /// Colorizes a string with foreground color and optional background.
    private func colorize(
        _ string: String,
        with color: Color,
        bold: Bool = false,
        backgroundColor: Color? = nil
    ) -> String {
        var style = TextStyle()
        style.foregroundColor = color
        style.backgroundColor = backgroundColor
        style.isBold = bold
        return ANSIRenderer.render(string, with: style)
    }
    
    /// Applies background color to a string (preserving existing foreground styling).
    private func applyBackground(_ string: String, background: Color) -> String {
        // This is a simplified version - in reality we'd need to parse
        // existing ANSI codes and inject background. For now, we wrap.
        let bgCode = ANSIRenderer.backgroundCode(for: background)
        return "\u{1B}[\(bgCode)m" + string
    }
}
