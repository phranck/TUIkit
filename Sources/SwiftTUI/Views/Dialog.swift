//
//  Dialog.swift
//  SwiftTUI
//
//  A modal dialog view with title and custom content.
//

/// A modal dialog view with a title and customizable content.
///
/// `Dialog` is more flexible than `Alert` — it accepts any content,
/// making it suitable for forms, selections, or complex interactions.
///
/// # Example
///
/// ```swift
/// // Simple dialog
/// Dialog(title: "Settings") {
///     Text("Option 1: Enabled")
///     Text("Option 2: Disabled")
/// }
///
/// // Dialog with custom styling
/// Dialog(title: "User Profile", borderStyle: .doubleLine, titleColor: .cyan) {
///     Text("Name: John Doe")
///     Text("Email: john@example.com")
///     Divider()
///     Text("[Edit] [Close]")
/// }
///
/// // Modal overlay pattern
/// mainContent
///     .dimmed()
///     .overlay {
///         Dialog(title: "Confirm Action") {
///             Text("Are you sure you want to proceed?")
///             HStack {
///                 Text("[Yes]").foregroundColor(.green)
///                 Spacer()
///                 Text("[No]").foregroundColor(.red)
///             }
///         }
///     }
/// ```
public struct Dialog<Content: View>: View {
    /// The dialog title.
    public let title: String

    /// The dialog content.
    public let content: Content

    /// The border style.
    public let borderStyle: BorderStyle

    /// The border color.
    public let borderColor: Color?

    /// The title color.
    public let titleColor: Color?

    /// The inner padding.
    public let padding: EdgeInsets

    /// Creates a dialog with the specified options.
    ///
    /// - Parameters:
    ///   - title: The dialog title.
    ///   - borderStyle: The border style (default: .rounded).
    ///   - borderColor: The border color (default: nil).
    ///   - titleColor: The title color (default: nil).
    ///   - padding: The inner padding (default: horizontal 2, vertical 1).
    ///   - content: The dialog content.
    public init(
        title: String,
        borderStyle: BorderStyle = .rounded,
        borderColor: Color? = nil,
        titleColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(horizontal: 2, vertical: 1),
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.titleColor = titleColor
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        Panel(
            title,
            borderStyle: borderStyle,
            borderColor: borderColor,
            titleColor: titleColor,
            padding: padding
        ) {
            content
        }
    }
}

// MARK: - Convenience Extensions

extension Dialog {
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
    ) -> Dialog<C> {
        Dialog<C>(
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
    ) -> Dialog<C> {
        Dialog<C>(
            title: title,
            borderStyle: .heavy,
            borderColor: borderColor,
            titleColor: titleColor,
            content: content
        )
    }
}

// MARK: - Modal Presentation Helper

extension View {
    /// Presents this view as a modal dialog over dimmed content.
    ///
    /// This is a convenience method that combines `.dimmed()` and `.overlay()`
    /// with center alignment.
    ///
    /// # Example
    ///
    /// ```swift
    /// mainContent.modal {
    ///     Dialog(title: "Settings") {
    ///         Text("Setting 1")
    ///         Text("Setting 2")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter content: The modal content to display.
    /// - Returns: A view with the modal overlay.
    public func modal<Modal: View>(
        @ViewBuilder content: () -> Modal
    ) -> some View {
        self.dimmed()
            .overlay(alignment: .center, content: content)
    }
}
