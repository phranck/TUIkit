//  🖥️ TUIKit — Terminal UI Kit for Swift
//  List.swift
//
//  Created by LAYERED.work
//  License: MIT


// MARK: - List (Single Selection)

/// A scrollable list with keyboard navigation and single selection.
///
/// `List` displays a vertical collection of items inside a bordered container
/// with support for:
/// - Optional title in the border
/// - Optional footer (typically buttons or status text)
/// - Keyboard navigation (Up/Down/Home/End/PageUp/PageDown)
/// - Single selection via optional binding
/// - Multi-selection via Set binding
/// - Scrolling with automatic viewport management
/// - Visual states for focused and selected items
///
/// ## Usage
///
/// ```swift
/// @State var selectedID: String?
///
/// List("My Items", selection: $selectedID) {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// }
///
/// // With footer
/// List("My Items", selection: $selectedID) {
///     ForEach(items) { item in
///         Text(item.name)
///     }
/// } footer: {
///     ButtonRow {
///         Button("Add") { }
///         Button("Remove") { }
///     }
/// }
/// ```
///
/// ## Visual States
///
/// | State | Rendering |
/// |-------|-----------|
/// | Focused + Selected | Pulsing accent background, bold |
/// | Focused only | Highlight background bar |
/// | Selected only | Dimmed accent indicator |
/// | Neither | Default foreground |
///
/// ## Scroll Indicators
///
/// When content extends beyond the viewport, scroll indicators (arrows)
/// appear at the top and/or bottom edges inside the container.
public struct List<SelectionValue: Hashable & Sendable, Content: View, Footer: View>: View {
    /// The optional title displayed in the border.
    let title: String?

    /// The content of the list (typically ForEach).
    let content: Content

    /// The footer content (optional).
    let footer: Footer?

    /// Binding for single selection (optional ID).
    let singleSelection: Binding<SelectionValue?>?

    /// Binding for multi-selection (Set of IDs).
    let multiSelection: Binding<Set<SelectionValue>>?

    /// The selection mode derived from which binding is set.
    var selectionMode: SelectionMode {
        multiSelection != nil ? .multi : .single
    }

    /// The unique focus identifier for this list.
    var focusID: String?

    /// Whether the list is disabled.
    var isDisabled: Bool

    /// The placeholder text shown when the list is empty.
    var emptyPlaceholder: String

    /// Whether to show separator before footer.
    var showFooterSeparator: Bool

    public var body: some View {
        _ListCore(
            title: title,
            content: content,
            footer: footer,
            singleSelection: singleSelection,
            multiSelection: multiSelection,
            selectionMode: selectionMode,
            focusID: focusID,
            isDisabled: isDisabled,
            emptyPlaceholder: emptyPlaceholder,
            showFooterSeparator: showFooterSeparator
        )
    }
}

// MARK: - Single Selection Initializers (with Footer)

extension List {
    /// Creates a list with single selection, title, and footer.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        _ title: String,
        selection: Binding<SelectionValue?>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = true
    }

    /// Creates a list with single selection and footer, without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        selection: Binding<SelectionValue?>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = nil
        self.content = content()
        self.footer = footer()
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = true
    }
}

// MARK: - Single Selection Initializers (without Footer)

extension List where Footer == EmptyView {
    /// Creates a list with single selection and a title.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        _ title: String,
        selection: Binding<SelectionValue?>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.footer = nil
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = false
    }

    /// Creates a list with single selection without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the selected item's ID (nil = no selection).
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        selection: Binding<SelectionValue?>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.content = content()
        self.footer = nil
        self.singleSelection = selection
        self.multiSelection = nil
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = false
    }
}

// MARK: - Multi Selection Initializers (with Footer)

extension List {
    /// Creates a list with multi-selection, title, and footer.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the set of selected item IDs.
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        _ title: String,
        selection: Binding<Set<SelectionValue>>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = true
    }

    /// Creates a list with multi-selection and footer, without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the set of selected item IDs.
    ///   - content: A ViewBuilder that defines the list content.
    ///   - footer: A ViewBuilder that defines the footer content.
    public init(
        selection: Binding<Set<SelectionValue>>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = nil
        self.content = content()
        self.footer = footer()
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = true
    }
}

// MARK: - Multi Selection Initializers (without Footer)

extension List where Footer == EmptyView {
    /// Creates a list with multi-selection and a title.
    ///
    /// - Parameters:
    ///   - title: The title displayed in the border.
    ///   - selection: A binding to the set of selected item IDs.
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        _ title: String,
        selection: Binding<Set<SelectionValue>>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
        self.footer = nil
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = false
    }

    /// Creates a list with multi-selection without a title.
    ///
    /// - Parameters:
    ///   - selection: A binding to the set of selected item IDs.
    ///   - content: A ViewBuilder that defines the list content.
    public init(
        selection: Binding<Set<SelectionValue>>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = nil
        self.content = content()
        self.footer = nil
        self.singleSelection = nil
        self.multiSelection = selection
        self.focusID = nil
        self.isDisabled = false
        self.emptyPlaceholder = ViewConstants.emptyListPlaceholder
        self.showFooterSeparator = false
    }
}

// MARK: - Convenience Modifiers

extension List {
    /// Creates a disabled version of this list.
    ///
    /// - Parameter disabled: Whether the list is disabled.
    /// - Returns: A new list with the disabled state.
    public func disabled(_ disabled: Bool = true) -> List<SelectionValue, Content, Footer> {
        var copy = self
        copy.isDisabled = disabled
        return copy
    }

    /// Sets an explicit focus identifier for this list.
    ///
    /// By default, lists generate a focus identifier from their position
    /// in the view hierarchy. Use this modifier when you need a stable,
    /// explicit identifier for programmatic focus management.
    ///
    /// - Parameter id: The focus identifier.
    /// - Returns: A list with the specified focus identifier.
    public func focusID(_ id: String) -> List<SelectionValue, Content, Footer> {
        var copy = self
        copy.focusID = id
        return copy
    }

    /// Sets the placeholder text displayed when the list has no items.
    ///
    /// - Parameter placeholder: The text to show when the list is empty.
    /// - Returns: A list with the specified empty placeholder.
    public func listEmptyPlaceholder(_ placeholder: String) -> List<SelectionValue, Content, Footer> {
        var copy = self
        copy.emptyPlaceholder = placeholder
        return copy
    }

    /// Controls whether a separator line is shown before the footer.
    ///
    /// - Parameter show: Whether to show the footer separator. Defaults to `true`.
    /// - Returns: A list with the specified footer separator visibility.
    public func listFooterSeparator(_ show: Bool = true) -> List<SelectionValue, Content, Footer> {
        var copy = self
        copy.showFooterSeparator = show
        return copy
    }
}


