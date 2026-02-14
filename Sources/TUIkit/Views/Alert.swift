//  🖥️ TUIKit — Terminal UI Kit for Swift
//  Alert.swift
//
//  Created by LAYERED.work
//  License: MIT

/// A modal alert view that displays a title, message, and optional action buttons.
///
/// `Alert` is designed to be shown as an overlay on top of other content.
/// Use it together with `.overlay()` and `.dimmed()` for a modal effect.
///
/// ## Structure
///
/// - **Header**: Title (rendered in the top border)
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
    let title: String

    /// The alert message.
    let message: String

    /// The shared visual configuration.
    let config: ContainerConfig

    /// The action views (typically buttons).
    let actions: Actions

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

    public var body: some View {
        _AlertCore(
            title: title,
            message: message,
            config: config,
            actions: actions
        )
    }
}

// MARK: - Alert Core Rendering

/// Internal view that handles Alert rendering.
///
/// This separation ensures `Alert.body` returns a real `View`, allowing
/// environment modifiers like `.foregroundStyle()` to propagate correctly.
struct _AlertCore<Actions: View>: View, Renderable {
    let title: String
    let message: String
    let config: ContainerConfig
    let actions: Actions

    var body: Never {
        fatalError("_AlertCore renders via Renderable")
    }

    /// Maximum width for alerts (characters).
    private static var maxWidth: Int { 60 }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        // Limit alert width
        var alertContext = context
        alertContext.availableWidth = min(context.availableWidth, Self.maxWidth)

        // Extract buttons from actions and create horizontal layout
        let buttons = extractButtons(from: actions)
        let hasActions = !buttons.isEmpty

        let footerView: AlertButtonRow? = hasActions ? AlertButtonRow(buttons: buttons) : nil

        return renderContainer(
            title: title,
            config: config,
            content: Text(message),
            footer: footerView,
            context: alertContext
        )
    }

    /// Extracts Button instances from a view hierarchy using the `ButtonProvider` protocol.
    private func extractButtons<V: View>(from view: V) -> [Button] {
        if let provider = view as? ButtonProvider {
            return provider.extractButtons()
        }
        return []
    }
}

// MARK: - Alert Button Row

/// Internal view that renders buttons horizontally for alerts.
struct AlertButtonRow: View, Renderable {
    let buttons: [Button]

    var body: Never {
        fatalError("AlertButtonRow renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard !buttons.isEmpty else {
            return FrameBuffer(lines: [])
        }

        // Sort buttons: cancel on left, others on right
        let sortedButtons = buttons.sorted { lhs, rhs in
            let lhsIsCancel = lhs.role == .cancel
            let rhsIsCancel = rhs.role == .cancel
            if lhsIsCancel != rhsIsCancel {
                return lhsIsCancel  // Cancel comes first (left)
            }
            return false  // Keep original order otherwise
        }

        // Render each button
        var buttonBuffers: [FrameBuffer] = []
        for button in sortedButtons {
            let buffer = TUIkit.renderToBuffer(button, context: context)
            buttonBuffers.append(buffer)
        }

        // Find the maximum height
        let maxHeight = buttonBuffers.map { $0.height }.max() ?? 0

        // Calculate total width needed (buttons + spacing)
        let spacing = 1
        let totalButtonWidth = buttonBuffers.reduce(0) { $0 + $1.width }
        let totalSpacingWidth = max(0, buttonBuffers.count - 1) * spacing
        let totalNeededWidth = totalButtonWidth + totalSpacingWidth

        // Available width from context
        let availableWidth = context.availableWidth

        // Right-align: calculate left padding
        let leftPadding = max(0, availableWidth - totalNeededWidth)

        // Combine horizontally (right-aligned)
        var resultLines: [String] = Array(repeating: "", count: maxHeight)
        let spacer = String(repeating: " ", count: spacing)

        for lineIndex in 0..<maxHeight {
            // Add left padding
            resultLines[lineIndex] = String(repeating: " ", count: leftPadding)

            // Add buttons
            for (index, buffer) in buttonBuffers.enumerated() {
                let buttonWidth = buffer.width

                if index > 0 {
                    resultLines[lineIndex] += spacer
                }

                if lineIndex < buffer.height {
                    resultLines[lineIndex] += buffer.lines[lineIndex]
                } else {
                    resultLines[lineIndex] += String(repeating: " ", count: buttonWidth)
                }
            }
        }

        return FrameBuffer(lines: resultLines)
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
    /// Creates a warning-style alert with palette warning colors.
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
            titleColor: .palette.warning,
            actions: actions
        )
    }

    /// Creates an error-style alert with palette error title color.
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
            titleColor: .palette.error,
            actions: actions
        )
    }

    /// Creates an info-style alert with palette info title color.
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
            titleColor: .palette.info,
            actions: actions
        )
    }

    /// Creates a success-style alert with palette success title color.
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
            titleColor: .palette.success,
            actions: actions
        )
    }
}

// MARK: - Preset Alerts without Actions

extension Alert where Actions == EmptyView {
    /// Creates a warning-style alert without actions.
    public static func warning(title: String = "Warning", message: String) -> Alert<EmptyView> {
        Alert<EmptyView>(title: title, message: message, titleColor: .palette.warning)
    }

    /// Creates an error-style alert without actions.
    public static func error(title: String = "Error", message: String) -> Alert<EmptyView> {
        Alert<EmptyView>(title: title, message: message, titleColor: .palette.error)
    }

    /// Creates an info-style alert without actions.
    public static func info(title: String = "Info", message: String) -> Alert<EmptyView> {
        Alert<EmptyView>(title: title, message: message, titleColor: .palette.info)
    }

    /// Creates a success-style alert without actions.
    public static func success(title: String = "Success", message: String) -> Alert<EmptyView> {
        Alert<EmptyView>(title: title, message: message, titleColor: .palette.success)
    }
}

// MARK: - Button Provider Protocol

/// A protocol for views that can provide `Button` instances.
///
/// This replaces the fragile `Mirror`-based button extraction with a
/// compile-time safe, protocol-based approach. Each view type that may
/// contain buttons in an Alert's actions closure conforms to this protocol.
@MainActor
protocol ButtonProvider {
    /// Extracts all `Button` instances contained in this view.
    func extractButtons() -> [Button]
}

// MARK: - ButtonProvider Conformances

extension Button: ButtonProvider {
    func extractButtons() -> [Button] {
        [self]
    }
}

extension EmptyView: ButtonProvider {
    func extractButtons() -> [Button] {
        []
    }
}

extension TupleView: ButtonProvider {
    func extractButtons() -> [Button] {
        var buttons: [Button] = []
        func collect<T: View>(_ view: T) {
            if let provider = view as? ButtonProvider {
                buttons.append(contentsOf: provider.extractButtons())
            }
        }
        repeat collect(each children)
        return buttons
    }
}
