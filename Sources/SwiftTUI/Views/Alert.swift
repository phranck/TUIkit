//
//  Alert.swift
//  SwiftTUI
//
//  A modal alert view with title, message, and optional actions.
//

/// A modal alert view that displays a title, message, and optional action buttons.
///
/// `Alert` is designed to be shown as an overlay on top of other content.
/// Use it together with `.overlay()` and `.dimmed()` for a modal effect.
///
/// # Example
///
/// ```swift
/// // Simple alert
/// Alert(title: "Warning", message: "Are you sure?")
///
/// // Alert with custom actions
/// Alert(title: "Confirm", message: "Delete this item?") {
///     Text("[Yes]")
///     Text("[No]")
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

    /// The border style for the alert box.
    public let borderStyle: BorderStyle

    /// The border color.
    public let borderColor: Color?

    /// The title color.
    public let titleColor: Color?

    /// The action views (typically buttons or styled text).
    public let actions: Actions

    /// Creates an alert with custom action views.
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - message: The alert message.
    ///   - borderStyle: The border style (default: .rounded).
    ///   - borderColor: The border color (default: nil).
    ///   - titleColor: The title color (default: nil).
    ///   - actions: The action views to display below the message.
    public init(
        title: String,
        message: String,
        borderStyle: BorderStyle = .rounded,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.message = message
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.titleColor = titleColor
        self.actions = actions()
    }

    public var body: some View {
        VStack(spacing: 1) {
            // Title
            if let color = titleColor {
                Text(title)
                    .bold()
                    .foregroundColor(color)
            } else {
                Text(title)
                    .bold()
            }

            // Message
            Text(message)

            // Empty line between message and actions
            Text("")

            // Actions (if any)
            actions
        }
        .padding(EdgeInsets(horizontal: 2, vertical: 1))
        .border(borderStyle, color: borderColor)
    }
}

// MARK: - Convenience Initializer (no actions)

extension Alert where Actions == EmptyView {
    /// Creates an alert without action buttons.
    ///
    /// - Parameters:
    ///   - title: The alert title.
    ///   - message: The alert message.
    ///   - borderStyle: The border style (default: .rounded).
    ///   - borderColor: The border color (default: nil).
    ///   - titleColor: The title color (default: nil).
    public init(
        title: String,
        message: String,
        borderStyle: BorderStyle = .rounded,
        borderColor: Color? = nil,
        titleColor: Color? = nil
    ) {
        self.title = title
        self.message = message
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.titleColor = titleColor
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
            borderStyle: .rounded,
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
            borderStyle: .rounded,
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
            borderStyle: .rounded,
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
            borderStyle: .rounded,
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
        Alert<EmptyView>(
            title: title,
            message: message,
            borderStyle: .rounded,
            borderColor: .yellow,
            titleColor: .yellow
        )
    }

    /// Creates an error-style alert without actions.
    public static func error(title: String = "Error", message: String) -> Alert<EmptyView> {
        Alert<EmptyView>(
            title: title,
            message: message,
            borderStyle: .rounded,
            borderColor: .red,
            titleColor: .red
        )
    }

    /// Creates an info-style alert without actions.
    public static func info(title: String = "Info", message: String) -> Alert<EmptyView> {
        Alert<EmptyView>(
            title: title,
            message: message,
            borderStyle: .rounded,
            borderColor: .cyan,
            titleColor: .cyan
        )
    }

    /// Creates a success-style alert without actions.
    public static func success(title: String = "Success", message: String) -> Alert<EmptyView> {
        Alert<EmptyView>(
            title: title,
            message: message,
            borderStyle: .rounded,
            borderColor: .green,
            titleColor: .green
        )
    }
}
