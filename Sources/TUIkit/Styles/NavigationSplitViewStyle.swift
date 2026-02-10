//  🖥️ TUIKit — Terminal UI Kit for Swift
//  NavigationSplitViewStyle.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - NavigationSplitViewVisibility

/// The visibility of the leading columns in a navigation split view.
///
/// Use a value of this type to control the visibility of the columns of a
/// ``NavigationSplitView``. Create a ``State`` property with a value of this
/// type, and pass a ``Binding`` to that state to the appropriate initializer.
///
/// ## Example
///
/// ```swift
/// @State private var visibility = NavigationSplitViewVisibility.all
///
/// NavigationSplitView(columnVisibility: $visibility) {
///     List(items, selection: $selected) { ... }
/// } detail: {
///     DetailView(item: selected)
/// }
/// ```
///
/// ## Visibility Options
///
/// - ``automatic``: Use the default visibility for the current context.
/// - ``all``: Show all columns.
/// - ``doubleColumn``: Show content and detail (hide sidebar in 3-column).
/// - ``detailOnly``: Show only the detail column.
public struct NavigationSplitViewVisibility: Equatable, Hashable, Sendable, Codable {
    /// The raw value representing the visibility state.
    private let rawValue: Int

    private init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Use the default leading column visibility for the current context.
    ///
    /// In TUIkit, this resolves to ``all`` since terminal width is typically
    /// sufficient to display all columns.
    public static var automatic: Self {
        Self(rawValue: 0)
    }

    /// Show all columns of a navigation split view.
    ///
    /// For a two-column split view, this shows sidebar and detail.
    /// For a three-column split view, this shows sidebar, content, and detail.
    public static var all: Self {
        Self(rawValue: 1)
    }

    /// Show the content column and detail area of a three-column navigation
    /// split view, or the sidebar column and detail area of a two-column
    /// navigation split view.
    ///
    /// For a two-column navigation split view, `doubleColumn` is equivalent
    /// to ``all``.
    public static var doubleColumn: Self {
        Self(rawValue: 2)
    }

    /// Hide the leading columns, showing only the detail area.
    ///
    /// For a two-column split view, this hides the sidebar.
    /// For a three-column split view, this hides both sidebar and content.
    public static var detailOnly: Self {
        Self(rawValue: 3)
    }
}

// MARK: - NavigationSplitViewColumn

/// A column in a navigation split view.
///
/// Use this type to identify which column should be displayed when the
/// navigation split view collapses or to programmatically control column
/// focus.
///
/// ## Example
///
/// ```swift
/// @State private var preferredColumn = NavigationSplitViewColumn.sidebar
///
/// NavigationSplitView(preferredCompactColumn: $preferredColumn) {
///     SidebarView()
/// } detail: {
///     DetailView()
/// }
/// ```
public struct NavigationSplitViewColumn: Equatable, Hashable, Sendable {
    /// The raw value identifying the column.
    private let rawValue: Int

    private init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The sidebar column (leftmost).
    ///
    /// This is the first column in both two-column and three-column layouts.
    public static var sidebar: Self {
        Self(rawValue: 0)
    }

    /// The content column (middle).
    ///
    /// This column only exists in three-column layouts. In a two-column
    /// layout, use ``sidebar`` or ``detail``.
    public static var content: Self {
        Self(rawValue: 1)
    }

    /// The detail column (rightmost).
    ///
    /// This is the last column in both two-column and three-column layouts.
    public static var detail: Self {
        Self(rawValue: 2)
    }
}

// MARK: - NavigationSplitViewStyle

/// A type that specifies the appearance and interaction of navigation split
/// views within a view hierarchy.
///
/// To configure the navigation split view style for a view hierarchy, use the
/// ``View/navigationSplitViewStyle(_:)`` modifier.
///
/// ## Built-in Styles
///
/// - ``AutomaticNavigationSplitViewStyle``: Resolves based on context.
/// - ``BalancedNavigationSplitViewStyle``: Columns share space proportionally.
/// - ``ProminentDetailNavigationSplitViewStyle``: Detail gets more space.
public protocol NavigationSplitViewStyle: Sendable {
    /// The proportion of width allocated to the sidebar in a two-column layout.
    ///
    /// Value between 0 and 1. For example, 0.33 means sidebar gets 1/3 of width.
    var sidebarProportion: Double { get }

    /// The proportion of width allocated to each column in a three-column layout.
    ///
    /// Returns (sidebar, content, detail) proportions that sum to 1.0.
    var threeColumnProportions: (sidebar: Double, content: Double, detail: Double) { get }
}

// MARK: - AutomaticNavigationSplitViewStyle

/// A navigation split style that resolves its appearance automatically based
/// on the current context.
///
/// In TUIkit, this style behaves identically to ``BalancedNavigationSplitViewStyle``.
///
/// Use the ``NavigationSplitViewStyle/automatic`` static property to access
/// this style.
public struct AutomaticNavigationSplitViewStyle: NavigationSplitViewStyle {
    /// Creates an automatic navigation split view style.
    public init() {}

    public var sidebarProportion: Double { 0.33 }

    public var threeColumnProportions: (sidebar: Double, content: Double, detail: Double) {
        (0.25, 0.25, 0.50)
    }
}

// MARK: - BalancedNavigationSplitViewStyle

/// A navigation split style that reduces the size of the detail content to
/// make room when showing the leading column or columns.
///
/// This style distributes space proportionally among all visible columns.
///
/// Use the ``NavigationSplitViewStyle/balanced`` static property to access
/// this style.
public struct BalancedNavigationSplitViewStyle: NavigationSplitViewStyle {
    /// Creates a balanced navigation split view style.
    public init() {}

    public var sidebarProportion: Double { 0.33 }

    public var threeColumnProportions: (sidebar: Double, content: Double, detail: Double) {
        (0.25, 0.25, 0.50)
    }
}

// MARK: - ProminentDetailNavigationSplitViewStyle

/// A navigation split style that attempts to maintain the size of the detail
/// content when hiding or showing the leading columns.
///
/// This style gives more space to the detail column, making leading columns
/// narrower.
///
/// Use the ``NavigationSplitViewStyle/prominentDetail`` static property to
/// access this style.
public struct ProminentDetailNavigationSplitViewStyle: NavigationSplitViewStyle {
    /// Creates a prominent detail navigation split view style.
    public init() {}

    public var sidebarProportion: Double { 0.25 }

    public var threeColumnProportions: (sidebar: Double, content: Double, detail: Double) {
        (0.20, 0.20, 0.60)
    }
}

// MARK: - Style Static Properties

extension NavigationSplitViewStyle where Self == AutomaticNavigationSplitViewStyle {
    /// A navigation split style that resolves its appearance automatically
    /// based on the current context.
    public static var automatic: Self {
        Self()
    }
}

extension NavigationSplitViewStyle where Self == BalancedNavigationSplitViewStyle {
    /// A navigation split style that reduces the size of the detail content
    /// to make room when showing the leading column or columns.
    public static var balanced: Self {
        Self()
    }
}

extension NavigationSplitViewStyle where Self == ProminentDetailNavigationSplitViewStyle {
    /// A navigation split style that attempts to maintain the size of the
    /// detail content when hiding or showing the leading columns.
    public static var prominentDetail: Self {
        Self()
    }
}

// MARK: - Environment Key

/// Environment key for the navigation split view style.
private struct NavigationSplitViewStyleKey: EnvironmentKey {
    static let defaultValue: any NavigationSplitViewStyle = AutomaticNavigationSplitViewStyle()
}

extension EnvironmentValues {
    /// The navigation split view style for this environment.
    public var navigationSplitViewStyle: any NavigationSplitViewStyle {
        get { self[NavigationSplitViewStyleKey.self] }
        set { self[NavigationSplitViewStyleKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Sets the style for navigation split views within this view.
    ///
    /// Use this modifier to specify how columns in a ``NavigationSplitView``
    /// should be sized and displayed.
    ///
    /// ```swift
    /// NavigationSplitView {
    ///     SidebarView()
    /// } detail: {
    ///     DetailView()
    /// }
    /// .navigationSplitViewStyle(.prominentDetail)
    /// ```
    ///
    /// ## Available Styles
    ///
    /// - ``AutomaticNavigationSplitViewStyle/automatic``: Resolves based on context.
    /// - ``BalancedNavigationSplitViewStyle/balanced``: Columns share space proportionally.
    /// - ``ProminentDetailNavigationSplitViewStyle/prominentDetail``: Detail gets more space.
    ///
    /// - Parameter style: The navigation split view style to apply.
    /// - Returns: A view with the specified navigation split view style.
    public func navigationSplitViewStyle<S: NavigationSplitViewStyle>(_ style: S) -> some View {
        environment(\.navigationSplitViewStyle, style)
    }
}
