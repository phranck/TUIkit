//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StateStorage.swift
//
//  Created by LAYERED.work
//  License: MIT

import TUIkitCore

// MARK: - State Storage

/// Persistent store for `@State` values, indexed by `ViewIdentity`.
///
/// `StateStorage` is the backbone of TUIKit's state persistence across render
/// passes. It maps each `@State` property to a stable key derived from the
/// view's structural position in the tree (`ViewIdentity`) and the property's
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
public final class StateStorage: @unchecked Sendable {

    // MARK: - State Key

    /// A unique key for a single `@State` property on a specific view.
    public struct StateKey: Hashable {
        /// The view's structural identity in the render tree.
        public let identity: ViewIdentity

        /// The property's declaration index within the view (0, 1, 2, ...).
        public let propertyIndex: Int

        /// Creates a new state key.
        public init(identity: ViewIdentity, propertyIndex: Int) {
            self.identity = identity
            self.propertyIndex = propertyIndex
        }
    }

    // MARK: - Storage

    /// All persisted state values, keyed by view identity + property index.
    private var values: [StateKey: AnyObject] = [:]

    /// Tracked values for `onChange(of:)`, keyed by view identity + property index.
    ///
    /// Unlike `values` (which stores `StateBox` objects that trigger re-renders),
    /// tracked values are plain values used only for change detection. Writing to
    /// them does not trigger a re-render.
    private var trackedValues: [StateKey: Any] = [:]

    /// Per-identity counters for `onChange(of:)` index assignment.
    ///
    /// Reset at the start of each render pass. Each `OnChangeModifier` claims the
    /// next index for its identity, ensuring chained `.onChange(of:)` modifiers at
    /// the same identity get unique keys.
    private var onChangeCounters: [ViewIdentity: Int] = [:]

    /// Identities seen during the current render pass (for garbage collection).
    private var activeIdentities: Set<ViewIdentity> = []

    /// Creates an empty state storage.
    public init() {}

    /// The number of stored state entries (for testing/debugging).
    public var count: Int { values.count }
}

// MARK: - Internal API

extension StateStorage {
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
    public func storage<Value>(for key: StateKey, default defaultValue: Value) -> StateBox<Value> {
        if let existing = values[key] as? StateBox<Value> {
            existing.identity = key.identity
            return existing
        }
        let fresh = StateBox(defaultValue)
        fresh.identity = key.identity
        values[key] = fresh
        return fresh
    }

    /// Marks an identity as active during the current render pass.
    ///
    /// Called by `renderToBuffer` when hydrating a view. Identities not marked
    /// active by the end of the render pass are candidates for garbage collection.
    ///
    /// - Parameter identity: The view identity to mark as active.
    public func markActive(_ identity: ViewIdentity) {
        activeIdentities.insert(identity)
    }

    // MARK: - onChange Tracking

    /// Claims the next `onChange` property index for the given identity.
    ///
    /// Each `OnChangeModifier` at a given identity calls this to get a unique
    /// index, ensuring chained `.onChange(of:)` modifiers don't collide.
    ///
    /// - Parameter identity: The view identity requesting an index.
    /// - Returns: The next available index (starting at 0).
    public func nextOnChangeIndex(for identity: ViewIdentity) -> Int {
        let index = onChangeCounters[identity, default: 0]
        onChangeCounters[identity] = index + 1
        return index
    }

    /// Returns the previously tracked value for the given key, if any.
    ///
    /// - Parameter key: The state key (identity + property index).
    /// - Returns: The tracked value, or `nil` if no value was stored yet.
    public func trackedValue<V>(for key: StateKey) -> V? {
        trackedValues[key] as? V
    }

    /// Stores a tracked value for change detection across render passes.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The state key (identity + property index).
    public func setTrackedValue<V>(_ value: V, for key: StateKey) {
        trackedValues[key] = value
    }

    // MARK: - Render Pass Lifecycle

    /// Begins a new render pass by clearing the active identity set.
    public func beginRenderPass() {
        activeIdentities.removeAll(keepingCapacity: true)
        onChangeCounters.removeAll(keepingCapacity: true)
    }

    /// Ends a render pass by removing state for views no longer in the tree.
    ///
    /// Any state whose identity was not marked active during this render pass
    /// is removed. This prevents memory leaks from views that have been
    /// permanently removed (e.g., by navigation or conditional branches).
    public func endRenderPass() {
        let staleKeys = values.keys.filter { !activeIdentities.contains($0.identity) }
        for key in staleKeys {
            values.removeValue(forKey: key)
        }
        let staleTrackedKeys = trackedValues.keys.filter { !activeIdentities.contains($0.identity) }
        for key in staleTrackedKeys {
            trackedValues.removeValue(forKey: key)
        }
    }

    /// Removes all state for descendants of the given identity.
    ///
    /// Called by ``ConditionalView`` when switching branches to clean up
    /// state from the now-inactive branch.
    ///
    /// - Parameter ancestor: The branch identity whose descendants should be removed.
    public func invalidateDescendants(of ancestor: ViewIdentity) {
        let staleKeys = values.keys.filter { ancestor.isAncestor(of: $0.identity) }
        for key in staleKeys {
            values.removeValue(forKey: key)
        }
        let staleTrackedKeys = trackedValues.keys.filter { ancestor.isAncestor(of: $0.identity) }
        for key in staleTrackedKeys {
            trackedValues.removeValue(forKey: key)
        }
    }

    /// Removes all stored state. Used during app cleanup.
    public func reset() {
        values.removeAll()
        trackedValues.removeAll()
        onChangeCounters.removeAll()
        activeIdentities.removeAll()
    }
}

// MARK: - State Box

/// Type-erased reference container for a single state value.
///
/// `StateBox` is the persistent storage backing a `@State` property.
/// It is a reference type so that mutations are visible across all copies
/// of the `@State` struct (which uses `nonmutating set`).
///
/// On value change, signals a re-render through `AppState.shared`.
/// Cache invalidation is identity-aware: only the affected subtree is
/// cleared instead of the entire cache.
public final class StateBox<Value>: @unchecked Sendable {
    /// The identity of the view that owns this state property.
    ///
    /// Set during hydration from ``StateStorage``. Used for targeted
    /// cache invalidation via ``RenderCache/clearAffected(by:)``.
    var identity: ViewIdentity?

    /// The current value.
    public var value: Value {
        didSet {
            if let identity {
                RenderCache.shared.clearAffected(by: identity)
            } else {
                RenderCache.shared.clearAll()
            }
            AppState.shared.setNeedsRender()
        }
    }

    /// Creates a state box with an initial value.
    ///
    /// - Parameter value: The initial value.
    public init(_ value: Value) {
        self.value = value
    }
}
