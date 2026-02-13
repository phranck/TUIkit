//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewIdentity.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - View Identity

/// A stable identifier for a view based on its position in the view tree.
///
/// `ViewIdentity` enables the `StateStorage` to persist `@State` values
/// across render passes. Each view gets a unique identity derived from its
/// **structural position** — the path of type names and child indices from
/// the root to the view.
///
/// ## How It Works
///
/// During rendering, `renderToBuffer` builds the identity path incrementally:
///
/// ```
/// "ContentView"                          → root view
/// "ContentView/VStack.0"                 → first child of VStack
/// "ContentView/VStack.1"                 → second child of VStack
/// "ContentView/VStack.1/Menu"            → Menu inside second child
/// ```
///
/// Container views (`VStack`, `HStack`, `TupleView`, `ViewArray`) append
/// their child index. Leaf views append their type name. `ConditionalView`
/// appends a branch label (`"true"` or `"false"`).
///
/// ## Stability
///
/// The identity is **stable across render passes** as long as the view tree
/// structure does not change. If a `ConditionalView` switches branches, the
/// old branch's state is invalidated.
struct ViewIdentity: Hashable, CustomStringConvertible {
    /// The structural path from root to this view.
    ///
    /// Format: `"TypeA/TypeB.childIndex/TypeC"`
    let path: String

    /// Creates a root identity for the given view type.
    ///
    /// - Parameter type: The type of the root view.
    init<V>(rootType type: V.Type) {
        self.path = String(describing: type)
    }

    /// Creates an identity from a raw path string.
    ///
    /// - Parameter path: The full identity path.
    init(path: String) {
        self.path = path
    }

    var description: String { path }
}

// MARK: - Internal API

extension ViewIdentity {
    /// Returns a child identity by appending a type name and child index.
    ///
    /// Used by container views (`TupleView`, `ViewArray`) to assign
    /// identities to their children.
    ///
    /// - Parameters:
    ///   - type: The child view's type.
    ///   - index: The child's position within the container.
    /// - Returns: A new `ViewIdentity` for the child.
    func child<V>(type: V.Type, index: Int) -> ViewIdentity {
        ViewIdentity(path: "\(path)/\(String(describing: type)).\(index)")
    }

    /// Returns a child identity by appending a type name without an index.
    ///
    /// Used when traversing into a composite view's `body` where there
    /// is exactly one child (no sibling disambiguation needed).
    ///
    /// - Parameter type: The child view's type.
    /// - Returns: A new `ViewIdentity` for the child.
    func child<V>(type: V.Type) -> ViewIdentity {
        ViewIdentity(path: "\(path)/\(String(describing: type))")
    }

    /// Returns a child identity by appending a branch label.
    ///
    /// Used by ``ConditionalView`` to distinguish between the
    /// `true` and `false` branches of an `if-else`.
    ///
    /// - Parameter label: The branch label (`"true"` or `"false"`).
    /// - Returns: A new `ViewIdentity` for the branch.
    func branch(_ label: String) -> ViewIdentity {
        ViewIdentity(path: "\(path)#\(label)")
    }

    /// Whether the given path is a descendant of this identity.
    ///
    /// Used by `StateStorage` to invalidate all state under a branch
    /// when a `ConditionalView` switches.
    ///
    /// - Parameter descendant: The path to check.
    /// - Returns: `true` if `descendant` starts with this identity's path.
    func isAncestor(of descendant: ViewIdentity) -> Bool {
        descendant.path.hasPrefix(path + "/") || descendant.path.hasPrefix(path + "#")
    }
}
