//
//  StateStorage.swift
//  TUIkit
//
//  Persistent storage for @State values indexed by view identity.
//

import Foundation

// MARK: - State Storage

/// Persistent store for `@State` values, indexed by ``ViewIdentity``.
///
/// `StateStorage` is the backbone of TUIKit's state persistence across render
/// passes. It maps each `@State` property to a stable key derived from the
/// view's structural position in the tree (``ViewIdentity``) and the property's
/// declaration order within that view.
///
/// ## Lifecycle
///
/// - **Created** by `TUIContext` (one per application).
/// - **Populated** during rendering: when `renderToBuffer` hydrates a view's
///   `@State` properties, it looks up or creates `Storage` objects here.
/// - **Pruned** at the end of each render pass: identities not seen during
///   the current frame are removed (coordinated with `LifecycleManager`).
///
/// ## Thread Safety
///
/// `StateStorage` is accessed only from the main thread (TUIKit's single-threaded
/// event loop). No locking is required.
final class StateStorage: @unchecked Sendable {

    // MARK: - State Key

    /// A unique key for a single `@State` property on a specific view.
    struct StateKey: Hashable {
        /// The view's structural identity in the render tree.
        let identity: ViewIdentity

        /// The property's declaration index within the view (0, 1, 2, ...).
        let propertyIndex: Int
    }

    // MARK: - Storage

    /// All persisted state values, keyed by view identity + property index.
    private var values: [StateKey: AnyObject] = [:]

    /// Identities seen during the current render pass (for garbage collection).
    private var activeIdentities: Set<ViewIdentity> = []

    /// Creates an empty state storage.
    init() {}

    // MARK: - Lookup & Create

    /// Returns the persistent storage for a `@State` property, creating it if needed.
    ///
    /// If a storage object already exists for the given key, it is returned as-is
    /// (preserving the current value across render passes). Otherwise, a new storage
    /// is created with the provided default value.
    ///
    /// - Parameters:
    ///   - key: The state key (identity + property index).
    ///   - defaultValue: The initial value for newly created storage.
    /// - Returns: The persistent `Storage` object for this property.
    func storage<Value>(for key: StateKey, default defaultValue: Value) -> StateBox<Value> {
        if let existing = values[key] as? StateBox<Value> {
            return existing
        }
        let fresh = StateBox(defaultValue)
        values[key] = fresh
        return fresh
    }

    // MARK: - Identity Tracking

    /// Marks an identity as active during the current render pass.
    ///
    /// Called by `renderToBuffer` when hydrating a view. Identities not marked
    /// active by the end of the render pass are candidates for garbage collection.
    ///
    /// - Parameter identity: The view identity to mark as active.
    func markActive(_ identity: ViewIdentity) {
        activeIdentities.insert(identity)
    }

    /// Begins a new render pass by clearing the active identity set.
    func beginRenderPass() {
        activeIdentities.removeAll(keepingCapacity: true)
    }

    /// Ends a render pass by removing state for views no longer in the tree.
    ///
    /// Any state whose identity was not marked active during this render pass
    /// is removed. This prevents memory leaks from views that have been
    /// permanently removed (e.g., by navigation or conditional branches).
    func endRenderPass() {
        let staleKeys = values.keys.filter { !activeIdentities.contains($0.identity) }
        for key in staleKeys {
            values.removeValue(forKey: key)
        }
    }

    // MARK: - Branch Invalidation

    /// Removes all state for descendants of the given identity.
    ///
    /// Called by ``ConditionalView`` when switching branches to clean up
    /// state from the now-inactive branch.
    ///
    /// - Parameter ancestor: The branch identity whose descendants should be removed.
    func invalidateDescendants(of ancestor: ViewIdentity) {
        let staleKeys = values.keys.filter { ancestor.isAncestor(of: $0.identity) }
        for key in staleKeys {
            values.removeValue(forKey: key)
        }
    }

    // MARK: - Reset

    /// Removes all stored state. Used during app cleanup.
    func reset() {
        values.removeAll()
        activeIdentities.removeAll()
    }

    /// The number of stored state entries (for testing/debugging).
    var count: Int { values.count }
}

// MARK: - State Box

/// Type-erased reference container for a single state value.
///
/// `StateBox` is the persistent storage backing a `@State` property.
/// It is a reference type so that mutations are visible across all copies
/// of the `@State` struct (which uses `nonmutating set`).
///
/// On value change, signals a re-render through ``RenderNotifier``.
final class StateBox<Value>: @unchecked Sendable {
    /// The current value.
    var value: Value {
        didSet {
            RenderNotifier.current.setNeedsRender()
        }
    }

    /// Creates a state box with an initial value.
    ///
    /// - Parameter value: The initial value.
    init(_ value: Value) {
        self.value = value
    }
}
