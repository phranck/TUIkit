//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderCache.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation

// MARK: - Render Cache

/// Caches rendered ``FrameBuffer`` results for views that opt into subtree memoization.
///
/// `RenderCache` is Phase 5 of TUIKit's render pipeline optimization. It stores
/// the output of ``EquatableView`` instances keyed by their `ViewIdentity`,
/// allowing unchanged subtrees to skip rendering entirely.
///
/// ## How It Works
///
/// When an ``EquatableView<V>`` renders, it:
/// 1. Looks up a cached entry by the current `ViewIdentity`
/// 2. Compares the new view value with the stored snapshot (`Equatable.==`)
/// 3. Checks that the available size hasn't changed
/// 4. On hit: returns the cached ``FrameBuffer`` — **the entire subtree is skipped**
/// 5. On miss: renders normally and stores the result
///
/// ## Invalidation
///
/// The cache is **fully cleared** whenever any `@State` value changes
/// (via `StateBox.value`'s `didSet`). This is conservative but correct:
/// state changes can propagate to any subtree through bindings or environment.
///
/// Between state changes (e.g. animation frames, pulse ticks), the cache
/// provides full memoization of unchanged subtrees.
///
/// ## Garbage Collection
///
/// Cache entries for `ViewIdentity` paths not seen during the current
/// render pass are removed in ``removeInactive()``, matching
/// `StateStorage`'s existing GC pattern.
///
/// ## Debug Logging
///
/// Set the environment variable `TUIKIT_DEBUG_RENDER=1` to enable per-frame
/// cache statistics logging to stderr. This logs hit/miss counts, cache size,
/// and individual identity lookups to help diagnose memoization effectiveness.
///
/// ## Thread Safety
///
/// `RenderCache` is accessed only from the main thread (TUIKit's single-threaded
/// event loop). No locking is required.
final class RenderCache: @unchecked Sendable {

    /// Aggregated cache performance statistics.
    ///
    /// Tracks hit/miss/store/clear counts. Use ``stats`` for cumulative
    /// totals, or ``frameStats`` (after ``logFrameStats()``) for the
    /// delta since the last ``beginRenderPass()``.
    struct Stats: Equatable {
        /// Number of successful cache lookups (view and size matched).
        var hits: Int = 0

        /// Number of failed cache lookups (identity missing, view changed, or size changed).
        var misses: Int = 0

        /// Number of entries stored (including overwrites).
        var stores: Int = 0

        /// Number of times ``clearAll()`` was called.
        var clears: Int = 0

        /// The total number of lookups (hits + misses).
        var lookups: Int { hits + misses }

        /// The cache hit rate as a value between 0 and 1, or 0 if no lookups occurred.
        var hitRate: Double {
            lookups > 0 ? Double(hits) / Double(lookups) : 0
        }

        /// Returns the per-element difference between this snapshot and an earlier one.
        func delta(since earlier: Self) -> Self {
            Self(
                hits: hits - earlier.hits,
                misses: misses - earlier.misses,
                stores: stores - earlier.stores,
                clears: clears - earlier.clears
            )
        }
    }

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

    /// Cumulative cache performance statistics.
    private(set) var stats = Stats()

    /// Stats snapshot taken at the start of each render pass (for per-frame deltas).
    private var statsAtFrameStart = Stats()

    /// Whether debug logging is enabled via the `TUIKIT_DEBUG_RENDER` environment variable.
    static let debugEnabled: Bool = {
        ProcessInfo.processInfo.environment["TUIKIT_DEBUG_RENDER"] == "1"
    }()

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
        guard let entry = entries[identity] else {
            stats.misses += 1
            logDebug("MISS (no entry) \(identity.path)")
            return nil
        }
        guard let oldView = entry.viewSnapshot as? V else {
            stats.misses += 1
            logDebug("MISS (type mismatch) \(identity.path)")
            return nil
        }
        guard entry.contextWidth == contextWidth,
              entry.contextHeight == contextHeight else {
            stats.misses += 1
            logDebug("MISS (size changed) \(identity.path)")
            return nil
        }
        guard oldView == view else {
            stats.misses += 1
            logDebug("MISS (view changed) \(identity.path)")
            return nil
        }
        stats.hits += 1
        logDebug("HIT \(identity.path)")
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
        stats.stores += 1
        entries[identity] = CacheEntry(
            viewSnapshot: view,
            buffer: buffer,
            contextWidth: contextWidth,
            contextHeight: contextHeight
        )
        logDebug("STORE \(identity.path)")
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

    /// Begins a new render pass by clearing the active identity set
    /// and snapshotting the current stats for per-frame delta calculation.
    func beginRenderPass() {
        activeIdentities.removeAll(keepingCapacity: true)
        statsAtFrameStart = stats
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
    /// Also called by `RenderLoop` when environment values change
    /// (theme, appearance).
    func clearAll() {
        stats.clears += 1
        logDebug("CLEAR ALL (\(entries.count) entries)")
        entries.removeAll(keepingCapacity: true)
    }

    /// Removes all cached entries, resets GC state, and clears statistics.
    func reset() {
        entries.removeAll()
        activeIdentities.removeAll()
        stats = Stats()
        statsAtFrameStart = Stats()
    }

    /// Resets the cumulative statistics counters to zero.
    func resetStats() {
        stats = Stats()
    }

    /// Logs a per-frame summary to stderr if debug logging is enabled.
    ///
    /// Call this at the end of each render pass (after ``removeInactive()``)
    /// to emit a one-line summary showing **this frame's** cache activity
    /// (delta since ``beginRenderPass()``) plus the current entry count.
    func logFrameStats() {
        guard Self.debugEnabled else { return }
        let frame = stats.delta(since: statsAtFrameStart)
        let rate = frame.lookups > 0
            ? String(format: "%.0f%%", frame.hitRate * 100)
            : "n/a"
        logDebug(
            "FRAME — hits: \(frame.hits), misses: \(frame.misses), "
                + "stores: \(frame.stores), clears: \(frame.clears), "
                + "entries: \(entries.count), hit rate: \(rate)"
        )
    }
}

// MARK: - Private Helpers

private extension RenderCache {
    /// Writes a debug message to stderr when `TUIKIT_DEBUG_RENDER=1` is set.
    ///
    /// Uses stderr so debug output never interferes with the terminal UI
    /// rendered on stdout. Redirect with `2>render.log` to capture.
    func logDebug(_ message: @autoclosure () -> String) {
        guard Self.debugEnabled else { return }
        FileHandle.standardError.write(
            Data("[RenderCache] \(message())\n".utf8)
        )
    }
}
