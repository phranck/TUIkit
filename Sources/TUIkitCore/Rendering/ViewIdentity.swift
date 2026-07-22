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
/// their child index. Leaf views append their type name. `_ConditionalContent`
/// appends a branch label (`"true"` or `"false"`).
///
/// ## Stability
///
/// The identity is **stable across render passes** as long as the view tree
/// structure does not change. If a `_ConditionalContent` switches branches, the
/// old branch's state is invalidated.
public struct ViewIdentity: Hashable, CustomStringConvertible, Sendable {
    /// The structural path from root to this view.
    ///
    /// Format: `"TypeA/TypeB.childIndex/TypeC"`
    public let path: String

    /// Creates a root identity for the given view type.
    ///
    /// - Parameter type: The type of the root view.
    public init<V>(rootType type: V.Type) {
        self.path = String(describing: type)
    }

    /// Creates an identity from a raw path string.
    ///
    /// - Parameter path: The full identity path.
    public init(path: String) {
        self.path = path
    }

    public var description: String { path }
}

// MARK: - Public API

public extension ViewIdentity {
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
    /// Used by ``_ConditionalContent`` to distinguish between the
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
    /// when a `_ConditionalContent` switches.
    ///
    /// - Parameter descendant: The path to check.
    /// - Returns: `true` if `descendant` starts with this identity's path.
    func isAncestor(of descendant: ViewIdentity) -> Bool {
        descendant.path.hasPrefix(path + "/") || descendant.path.hasPrefix(path + "#")
    }
}

// MARK: - Runtime Identity Scopes

package extension ViewIdentity {
    /// Returns an identity for a stable runtime slot below this view.
    ///
    /// Modifier and effect implementations use scopes instead of allocation-time
    /// tokens so reconstructed view values resolve to the same runtime record.
    func scoped(_ scope: String) -> ViewIdentity {
        ViewIdentity(path: "\(path)/@\(Self.encode(scope))")
    }

    /// Returns a child identity derived from an explicit collection key.
    ///
    /// Unlike positional child identities, keyed identities remain unchanged
    /// when siblings are inserted, deleted, or reordered. The key's reflected
    /// representation is encoded so separators cannot alias structural paths.
    func keyedChild<V, ID: Hashable>(type: V.Type, key: ID) -> ViewIdentity {
        let keyType = Self.encode(String(reflecting: ID.self))
        let keyValue = Self.encode(String(reflecting: key))
        return ViewIdentity(
            path: "\(path)/\(String(describing: type))[@\(keyType):\(keyValue)]"
        )
    }
}

// MARK: - Private Helpers

private extension ViewIdentity {
    static func encode(_ value: String) -> String {
        value.utf8.map { byte in
            let encoded = String(byte, radix: 16, uppercase: true)
            return encoded.count == 1 ? "0\(encoded)" : encoded
        }.joined()
    }
}
