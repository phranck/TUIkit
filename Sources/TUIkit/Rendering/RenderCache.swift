//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderCache.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

// MARK: - Render Cache

/// A snapshot of environment values that affect rendered output.
///
/// Used by ``RenderLoop`` to detect environment changes (theme, appearance)
/// that require cache invalidation. Only tracks values that affect visual
/// output — reference-type infrastructure services are excluded.
struct EnvironmentSnapshot: Equatable {
    /// The active palette identifier.
    let paletteID: String

    /// The active appearance identifier.
    let appearanceID: String
}

/// Caches rendered ``FrameBuffer`` results for views that opt into subtree memoization.
///
/// `RenderCache` is Phase 5 of TUIKit's render pipeline optimization. It stores
/// the output of ``EquatableView`` instances keyed by their ``ViewIdentity``,
/// allowing unchanged subtrees to skip rendering entirely.
///
/// ## How It Works
///
/// When an ``EquatableView<V>`` renders, it:
/// 1. Looks up a cached entry by the current ``ViewIdentity``
/// 2. Compares the new view value with the stored snapshot (`Equatable.==`)
/// 3. Checks that the available size hasn't changed
/// 4. On hit: returns the cached ``FrameBuffer`` — **the entire subtree is skipped**
/// 5. On miss: renders normally and stores the result
///
/// ## Invalidation
///
/// The cache is **fully cleared** whenever any `@State` value changes
/// (via ``StateBox/value``'s `didSet`). This is conservative but correct:
/// state changes can propagate to any subtree through bindings or environment.
///
/// Between state changes (e.g. animation frames, pulse ticks), the cache
/// provides full memoization of unchanged subtrees.
///
/// ## Garbage Collection
///
/// Cache entries for ``ViewIdentity`` paths not seen during the current
/// render pass are removed in ``removeInactive()``, matching
/// ``StateStorage``'s existing GC pattern.
///
/// ## Thread Safety
///
/// `RenderCache` is accessed only from the main thread (TUIKit's single-threaded
/// event loop). No locking is required.
final class RenderCache: @unchecked Sendable {

    /// A cached rendering result for a single view identity.
    struct CacheEntry {
        /// The type-erased view value at the time of caching.
        ///
        /// Cast back to the concrete `Equatable` type for comparison.
        let viewSnapshot: Any

        /// The rendered output buffer.
        let buffer: FrameBuffer

        /// The available width when this entry was cached.
        let contextWidth: Int

        /// The available height when this entry was cached.
        let contextHeight: Int
    }

    /// Cached entries keyed by view identity.
    private var entries: [ViewIdentity: CacheEntry] = [:]

    /// Identities seen during the current render pass (for garbage collection).
    private var activeIdentities: Set<ViewIdentity> = []

    /// Creates an empty render cache.
    init() {}

    /// The number of cached entries (for testing/debugging).
    var count: Int { entries.count }

    /// Whether the cache is empty.
    var isEmpty: Bool { entries.isEmpty }
}

// MARK: - Internal API

extension RenderCache {
    /// Looks up a cached buffer for a view, returning it if the view and context match.
    ///
    /// The caller provides the new view value and the current context size.
    /// If a cached entry exists with an equal view and matching size, the
    /// cached buffer is returned. Otherwise returns `nil`.
    ///
    /// - Parameters:
    ///   - identity: The view's structural identity.
    ///   - view: The current view value to compare against the snapshot.
    ///   - contextWidth: The current available width.
    ///   - contextHeight: The current available height.
    /// - Returns: The cached ``FrameBuffer`` if valid, or `nil` on miss.
    func lookup<V: Equatable>(
        identity: ViewIdentity,
        view: V,
        contextWidth: Int,
        contextHeight: Int
    ) -> FrameBuffer? {
        guard let entry = entries[identity] else { return nil }
        guard let oldView = entry.viewSnapshot as? V else { return nil }
        guard entry.contextWidth == contextWidth,
              entry.contextHeight == contextHeight else { return nil }
        guard oldView == view else { return nil }
        return entry.buffer
    }

    /// Stores a rendered buffer for a view identity.
    ///
    /// Overwrites any existing entry for the same identity.
    ///
    /// - Parameters:
    ///   - identity: The view's structural identity.
    ///   - view: The view value to snapshot for future comparisons.
    ///   - buffer: The rendered output to cache.
    ///   - contextWidth: The available width during rendering.
    ///   - contextHeight: The available height during rendering.
    func store<V: Equatable>(
        identity: ViewIdentity,
        view: V,
        buffer: FrameBuffer,
        contextWidth: Int,
        contextHeight: Int
    ) {
        entries[identity] = CacheEntry(
            viewSnapshot: view,
            buffer: buffer,
            contextWidth: contextWidth,
            contextHeight: contextHeight
        )
    }

    /// Marks an identity as active during the current render pass.
    ///
    /// Identities not marked active by the end of the render pass
    /// are candidates for garbage collection.
    ///
    /// - Parameter identity: The view identity to mark as active.
    func markActive(_ identity: ViewIdentity) {
        activeIdentities.insert(identity)
    }

    /// Begins a new render pass by clearing the active identity set.
    func beginRenderPass() {
        activeIdentities.removeAll(keepingCapacity: true)
    }

    /// Removes cache entries for views no longer in the tree.
    ///
    /// Any entry whose identity was not marked active during this render pass
    /// is removed. Prevents memory leaks from permanently removed views.
    func removeInactive() {
        let staleKeys = entries.keys.filter { !activeIdentities.contains($0) }
        for key in staleKeys {
            entries.removeValue(forKey: key)
        }
    }

    /// Clears all cached entries.
    ///
    /// Called when any `@State` value changes, because state changes
    /// can propagate to any subtree through bindings or environment.
    func clearAll() {
        entries.removeAll(keepingCapacity: true)
    }

    /// Removes all cached entries and resets GC state.
    func reset() {
        entries.removeAll()
        activeIdentities.removeAll()
    }
}
