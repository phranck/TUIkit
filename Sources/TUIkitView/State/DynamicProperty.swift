//  🖥️ TUIKit — Terminal UI Kit for Swift
//  DynamicProperty.swift
//
//  Created by LAYERED.work
//  License: MIT

// MARK: - DynamicProperty

/// An interface for a stored variable that updates an external property of a
/// view.
///
/// Matches SwiftUI's contract: the renderer binds every dynamic property of a
/// view (including properties nested inside user-defined `DynamicProperty`
/// types) to the view's committed structural identity, then calls
/// ``update()`` before evaluating `body`.
///
/// ## Composing framework wrappers
///
/// User-defined dynamic properties can embed framework wrappers; the nested
/// wrappers hydrate exactly like directly declared ones:
///
/// ```swift
/// struct Counter: DynamicProperty {
///     @State private var count = 0
///
///     var value: Int { count }
///     func increment() { count += 1 }
/// }
/// ```
///
/// > Note: `update()` is invoked on a copy of the property value obtained by
/// > reflection. Framework wrappers use reference-backed storage, so their
/// > effects persist; custom implementations should route side effects
/// > through reference-typed storage as well.
public protocol DynamicProperty {
    /// Updates the underlying value of the stored property.
    ///
    /// The renderer calls this function before evaluating the owning view's
    /// `body`, once per hydration.
    mutating func update()
}

extension DynamicProperty {
    /// Default: dynamic properties without external resources do nothing.
    public mutating func update() {}
}
