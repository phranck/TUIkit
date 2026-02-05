//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Dialog.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

/// A modal dialog view with a title, customizable content, and optional footer.
///
/// `Dialog` is more flexible than `Alert` — it accepts any content,
/// making it suitable for forms, selections, or complex interactions.
///
/// ## Structure
///
/// - **Header**: Title (rendered in the top border)
/// - **Body**: Custom content
/// - **Footer**: Optional, typically buttons (separated by optional separator line)
///
/// ## Examples
///
/// ```swift
/// // Simple dialog
/// Dialog(title: "Settings") {
///     Text("Option 1: Enabled")
///     Text("Option 2: Disabled")
/// }
///
/// // Dialog with footer buttons
/// Dialog(title: "User Profile") {
///     Text("Name: John Doe")
///     Text("Email: john@example.com")
/// } footer: {
///     ButtonRow {
///         Button("Edit") { }
///         Button("Close") { }
///     }
/// }
///
/// // Modal overlay pattern
/// mainContent
///     .dimmed()
///     .overlay {
///         Dialog(title: "Confirm Action") {
///             Text("Are you sure you want to proceed?")
///         } footer: {
///             ButtonRow {
///                 Button("Yes") { }
///                 Button("No") { }
///             }
///         }
///     }
/// ```
public struct Dialog<Content: View, Footer: View>: View {
    /// The dialog title.
    let title: String

    /// The dialog content.
    let content: Content

    /// The footer content (typically buttons).
    let footer: Footer?

    /// The shared visual configuration.
    let config: ContainerConfig

    /// Creates a dialog with content and footer.
    ///
    /// - Parameters:
    ///   - title: The dialog title.
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: theme foreground).
    ///   - padding: The inner padding (default: horizontal 2, vertical 1).
    ///   - showFooterSeparator: Whether to show separator before footer (default: true).
    ///   - content: The dialog content.
    ///   - footer: The footer content.
    public init(
        title: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 2, vertical: 1),
        showFooterSeparator: Bool = true,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.config = ContainerConfig(
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            padding: padding,
            showFooterSeparator: showFooterSeparator
        )
        self.content = content()
        self.footer = footer()
    }

    public var body: Never {
        fatalError("Dialog renders via Renderable")
    }
}

// MARK: - Equatable Conformance

extension Dialog: Equatable where Content: Equatable, Footer: Equatable {}

// MARK: - Rendering

extension Dialog: Renderable {
    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        renderContainer(
            title: title,
            config: config,
            content: content,
            footer: footer,
            context: context
        )
    }
}

// MARK: - Convenience Initializer (no footer)

extension Dialog where Footer == EmptyView {
    /// Creates a dialog without a footer.
    ///
    /// - Parameters:
    ///   - title: The dialog title.
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: theme foreground).
    ///   - padding: The inner padding (default: horizontal 2, vertical 1).
    ///   - content: The dialog content.
    public init(
        title: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 2, vertical: 1),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.config = ContainerConfig(
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            padding: padding,
            showFooterSeparator: false
        )
        self.content = content()
        self.footer = nil
    }
}

// MARK: - Convenience Extensions

extension Dialog where Footer == EmptyView {
    /// Creates a dialog with a double-line border style.
    ///
    /// - Parameters:
    ///   - title: The dialog title.
    ///   - borderColor: The border color (default: nil).
    ///   - titleColor: The title color (default: nil).
    ///   - content: The dialog content.
    /// - Returns: A dialog with double-line borders.
    public static func doubleLine<C: View>(
        title: String,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        @ViewBuilder content: () -> C
    ) -> Dialog<C, EmptyView> {
        Dialog<C, EmptyView>(
            title: title,
            borderStyle: .doubleLine,
            borderColor: borderColor,
            titleColor: titleColor,
            content: content
        )
    }

    /// Creates a dialog with a heavy border style.
    ///
    /// - Parameters:
    ///   - title: The dialog title.
    ///   - borderColor: The border color (default: nil).
    ///   - titleColor: The title color (default: nil).
    ///   - content: The dialog content.
    /// - Returns: A dialog with heavy borders.
    public static func heavy<C: View>(
        title: String,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        @ViewBuilder content: () -> C
    ) -> Dialog<C, EmptyView> {
        Dialog<C, EmptyView>(
            title: title,
            borderStyle: .heavy,
            borderColor: borderColor,
            titleColor: titleColor,
            content: content
        )
    }
}
