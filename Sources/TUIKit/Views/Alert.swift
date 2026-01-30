//
//  Alert.swift
//  TUIKit
//
//  A modal alert view with title, message, and optional action buttons.
//

/// A modal alert view that displays a title, message, and optional action buttons.
///
/// `Alert` is designed to be shown as an overlay on top of other content.
/// Use it together with `.overlay()` and `.dimmed()` for a modal effect.
///
/// ## Structure
///
/// - **Header**: Title (in border for standard appearances, separate section for block)
/// - **Body**: Message
/// - **Footer**: Action buttons (separated by optional separator line)
///
/// ## Examples
///
/// ```swift
/// // Simple alert
/// Alert(title: "Warning", message: "Are you sure?")
///
/// // Alert with action buttons
/// Alert(title: "Confirm", message: "Delete this item?") {
///     Button("Yes") { }
///     Button("No") { }
/// }
///
/// // Modal overlay pattern
/// mainContent
///     .dimmed()
///     .overlay {
///         Alert(title: "Notice", message: "Operation complete!")
///     }
/// ```
public struct Alert<Actions: View>: View {
    /// The alert title.
    public let title: String

    /// The alert message.
    public let message: String

    /// The shared visual configuration.
    public let config: ContainerConfig

    /// The action views (typically buttons).
    public let actions: Actions

    /// Creates an alert with custom action views.
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - message: The alert message.
    ///   - borderStyle: The border style (default: appearance borderStyle).
    ///   - borderColor: The border color (default: theme border).
    ///   - titleColor: The title color (default: theme foreground).
    ///   - showFooterSeparator: Whether to show separator before actions (default: true).
    ///   - actions: The action views to display in the footer.
    public init(
        title: String,
        message: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        showFooterSeparator: Bool = true,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.config = ContainerConfig(
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            padding: EdgeInsets(horizontal: 2, vertical: 1),
            showFooterSeparator: showFooterSeparator
        )
        self.actions = actions()
    }

    public var body: Never {
        fatalError("Alert renders via Renderable")
    }
}

// MARK: - Rendering

extension Alert: Renderable {
    public func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let hasActions = !(actions is EmptyView)
        return renderContainer(
            title: title,
            config: config,
            content: Text(message),
            footer: hasActions ? actions : nil,
            context: context
        )
    }
}

// MARK: - Convenience Initializer (no actions)

extension Alert where Actions == EmptyView {
    /// Creates an alert without action buttons.
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - message: The alert message.
    ///   - borderStyle: The border style (default: appearance default).
    ///   - borderColor: The border color (default: nil).
    ///   - titleColor: The title color (default: nil).
    public init(
        title: String,
        message: String,
        borderStyle: BorderStyle? = nil,
        borderColor: Color? = nil,
        titleColor: Color? = nil
    ) {
        self.title = title
        self.message = message
        self.config = ContainerConfig(
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            padding: EdgeInsets(horizontal: 2, vertical: 1),
            showFooterSeparator: false
        )
        self.actions = EmptyView()
    }
}

// MARK: - Preset Alert Styles

extension Alert {
    /// Creates a warning-style alert with yellow border.
    ///
    /// - Parameters:
    ///   - title: The alert title (default: "Warning").
    ///   - message: The alert message.
    ///   - actions: The action views.
    /// - Returns: A warning-styled alert.
    public static func warning<A: View>(
        title: String = "Warning",
        message: String,
        @ViewBuilder actions: () -> A
    ) -> Alert<A> {
        Alert<A>(
            title: title,
            message: message,
            borderColor: .yellow,
            titleColor: .yellow,
            actions: actions
        )
    }

    /// Creates an error-style alert with red border.
    ///
    /// - Parameters:
    ///   - title: The alert title (default: "Error").
    ///   - message: The alert message.
    ///   - actions: The action views.
    /// - Returns: An error-styled alert.
    public static func error<A: View>(
        title: String = "Error",
        message: String,
        @ViewBuilder actions: () -> A
    ) -> Alert<A> {
        Alert<A>(
            title: title,
            message: message,
            borderColor: .red,
            titleColor: .red,
            actions: actions
        )
    }

    /// Creates an info-style alert with cyan border.
    ///
    /// - Parameters:
    ///   - title: The alert title (default: "Info").
    ///   - message: The alert message.
    ///   - actions: The action views.
    /// - Returns: An info-styled alert.
    public static func info<A: View>(
        title: String = "Info",
        message: String,
        @ViewBuilder actions: () -> A
    ) -> Alert<A> {
        Alert<A>(
            title: title,
            message: message,
            borderColor: .cyan,
            titleColor: .cyan,
            actions: actions
        )
    }

    /// Creates a success-style alert with green border.
    ///
    /// - Parameters:
    ///   - title: The alert title (default: "Success").
    ///   - message: The alert message.
    ///   - actions: The action views.
    /// - Returns: A success-styled alert.
    public static func success<A: View>(
        title: String = "Success",
        message: String,
        @ViewBuilder actions: () -> A
    ) -> Alert<A> {
        Alert<A>(
            title: title,
            message: message,
            borderColor: .green,
            titleColor: .green,
            actions: actions
        )
    }
}

// MARK: - Preset Alerts without Actions

extension Alert where Actions == EmptyView {
    /// Creates a warning-style alert without actions.
    public static func warning(title: String = "Warning", message: String) -> Alert<EmptyView> {
        Alert.warning(title: title, message: message) { EmptyView() }
    }

    /// Creates an error-style alert without actions.
    public static func error(title: String = "Error", message: String) -> Alert<EmptyView> {
        Alert.error(title: title, message: message) { EmptyView() }
    }

    /// Creates an info-style alert without actions.
    public static func info(title: String = "Info", message: String) -> Alert<EmptyView> {
        Alert.info(title: title, message: message) { EmptyView() }
    }

    /// Creates a success-style alert without actions.
    public static func success(title: String = "Success", message: String) -> Alert<EmptyView> {
        Alert.success(title: title, message: message) { EmptyView() }
    }
}
