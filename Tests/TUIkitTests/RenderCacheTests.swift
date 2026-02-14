//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderCacheTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("RenderCache Tests")
struct RenderCacheTests {

    // MARK: - Store and Lookup

    @Test("Lookup returns cached buffer when view and size match")
    func lookupHitOnEqualViewAndSize() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/MyView")
        let view = "Hello"
        let buffer = FrameBuffer(text: "rendered")

        cache.store(identity: identity, view: view, buffer: buffer, contextWidth: 80, contextHeight: 24)

        let result = cache.lookup(identity: identity, view: view, contextWidth: 80, contextHeight: 24)
        #expect(result != nil)
        #expect(result?.lines == ["rendered"])
    }

    @Test("Lookup returns nil when view value differs")
    func lookupMissOnDifferentView() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/MyView")
        let buffer = FrameBuffer(text: "old")

        cache.store(identity: identity, view: "Hello", buffer: buffer, contextWidth: 80, contextHeight: 24)

        let result = cache.lookup(identity: identity, view: "World", contextWidth: 80, contextHeight: 24)
        #expect(result == nil)
    }

    @Test("Lookup returns nil when context width differs")
    func lookupMissOnDifferentWidth() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/MyView")
        let view = "same"
        let buffer = FrameBuffer(text: "content")

        cache.store(identity: identity, view: view, buffer: buffer, contextWidth: 80, contextHeight: 24)

        let result = cache.lookup(identity: identity, view: view, contextWidth: 120, contextHeight: 24)
        #expect(result == nil)
    }

    @Test("Lookup returns nil when context height differs")
    func lookupMissOnDifferentHeight() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/MyView")
        let view = "same"
        let buffer = FrameBuffer(text: "content")

        cache.store(identity: identity, view: view, buffer: buffer, contextWidth: 80, contextHeight: 24)

        let result = cache.lookup(identity: identity, view: view, contextWidth: 80, contextHeight: 40)
        #expect(result == nil)
    }

    @Test("Lookup returns nil for unknown identity")
    func lookupMissOnUnknownIdentity() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/Unknown")

        let result = cache.lookup(identity: identity, view: "any", contextWidth: 80, contextHeight: 24)
        #expect(result == nil)
    }

    @Test("Store overwrites existing entry for same identity")
    func storeOverwritesExisting() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/MyView")

        cache.store(identity: identity, view: "old", buffer: FrameBuffer(text: "first"), contextWidth: 80, contextHeight: 24)
        cache.store(identity: identity, view: "new", buffer: FrameBuffer(text: "second"), contextWidth: 80, contextHeight: 24)

        #expect(cache.count == 1)
        let result = cache.lookup(identity: identity, view: "new", contextWidth: 80, contextHeight: 24)
        #expect(result?.lines == ["second"])
    }

    // MARK: - clearAll

    @Test("clearAll removes all entries")
    func clearAllRemovesEverything() {
        let cache = RenderCache()
        cache.store(identity: ViewIdentity(path: "A"), view: 1, buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)
        cache.store(identity: ViewIdentity(path: "B"), view: 2, buffer: FrameBuffer(text: "b"), contextWidth: 80, contextHeight: 24)

        #expect(cache.count == 2)
        cache.clearAll()
        #expect(cache.isEmpty)
    }

    // MARK: - Garbage Collection

    @Test("removeInactive removes entries not marked active")
    func removeInactiveGarbageCollects() {
        let cache = RenderCache()
        let activeIdentity = ViewIdentity(path: "Root/Active")
        let staleIdentity = ViewIdentity(path: "Root/Stale")

        cache.store(identity: activeIdentity, view: "a", buffer: FrameBuffer(text: "active"), contextWidth: 80, contextHeight: 24)
        cache.store(identity: staleIdentity, view: "s", buffer: FrameBuffer(text: "stale"), contextWidth: 80, contextHeight: 24)

        cache.beginRenderPass()
        cache.markActive(activeIdentity)
        cache.removeInactive()

        #expect(cache.count == 1)
        #expect(cache.lookup(identity: activeIdentity, view: "a", contextWidth: 80, contextHeight: 24) != nil)
        #expect(cache.lookup(identity: staleIdentity, view: "s", contextWidth: 80, contextHeight: 24) == nil)
    }

    @Test("beginRenderPass clears active set for fresh GC tracking")
    func beginRenderPassClearsActiveSet() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")

        cache.store(identity: identity, view: "v", buffer: FrameBuffer(text: "content"), contextWidth: 80, contextHeight: 24)

        // First pass: mark active
        cache.beginRenderPass()
        cache.markActive(identity)
        cache.removeInactive()
        #expect(cache.count == 1)

        // Second pass: don't mark active — entry should be removed
        cache.beginRenderPass()
        cache.removeInactive()
        #expect(cache.isEmpty)
    }

    // MARK: - Type Safety

    @Test("Lookup returns nil when snapshot type does not match")
    func lookupMissOnTypeMismatch() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")

        cache.store(identity: identity, view: 42, buffer: FrameBuffer(text: "int"), contextWidth: 80, contextHeight: 24)

        // Try to look up with String type — should fail
        let result = cache.lookup(identity: identity, view: "42", contextWidth: 80, contextHeight: 24)
        #expect(result == nil)
    }

    // MARK: - Stats

    @Test("Stats start at zero")
    func statsInitiallyZero() {
        let cache = RenderCache()
        #expect(cache.stats == RenderCache.Stats())
        #expect(cache.stats.hits == 0)
        #expect(cache.stats.misses == 0)
        #expect(cache.stats.stores == 0)
        #expect(cache.stats.clears == 0)
    }

    @Test("Cache hit increments hits counter")
    func statsCountHits() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")
        cache.store(identity: identity, view: "A", buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)

        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)

        #expect(cache.stats.hits == 2)
        #expect(cache.stats.misses == 0)
    }

    @Test("Cache miss increments misses counter")
    func statsCountMisses() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")
        cache.store(identity: identity, view: "A", buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)

        // Miss: different view value
        _ = cache.lookup(identity: identity, view: "B", contextWidth: 80, contextHeight: 24)
        // Miss: unknown identity
        _ = cache.lookup(identity: ViewIdentity(path: "Root/Other"), view: "A", contextWidth: 80, contextHeight: 24)
        // Miss: different size
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 120, contextHeight: 24)

        #expect(cache.stats.misses == 3)
        #expect(cache.stats.hits == 0)
    }

    @Test("Store increments stores counter")
    func statsCountStores() {
        let cache = RenderCache()
        cache.store(identity: ViewIdentity(path: "A"), view: 1, buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)
        cache.store(identity: ViewIdentity(path: "B"), view: 2, buffer: FrameBuffer(text: "b"), contextWidth: 80, contextHeight: 24)
        // Overwrite existing entry
        cache.store(identity: ViewIdentity(path: "A"), view: 3, buffer: FrameBuffer(text: "c"), contextWidth: 80, contextHeight: 24)

        #expect(cache.stats.stores == 3)
    }

    @Test("clearAll increments clears counter")
    func statsCountClears() {
        let cache = RenderCache()
        cache.store(identity: ViewIdentity(path: "A"), view: 1, buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)

        cache.clearAll()
        cache.clearAll()

        #expect(cache.stats.clears == 2)
    }

    @Test("Stats accumulate across multiple operations")
    func statsAccumulateAcrossOperations() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")

        // 1 store
        cache.store(identity: identity, view: "A", buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)
        // 1 hit
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)
        // 1 miss (view changed)
        _ = cache.lookup(identity: identity, view: "B", contextWidth: 80, contextHeight: 24)
        // 1 clear
        cache.clearAll()
        // 1 miss (cache empty)
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)

        #expect(cache.stats.hits == 1)
        #expect(cache.stats.misses == 2)
        #expect(cache.stats.stores == 1)
        #expect(cache.stats.clears == 1)
        #expect(cache.stats.lookups == 3)
    }

    @Test("Hit rate is calculated correctly")
    func statsHitRate() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")
        cache.store(identity: identity, view: "A", buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)

        // 3 hits
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)
        // 1 miss
        _ = cache.lookup(identity: identity, view: "B", contextWidth: 80, contextHeight: 24)

        #expect(cache.stats.hitRate == 0.75)
    }

    @Test("Hit rate is zero when no lookups occurred")
    func statsHitRateZeroWithoutLookups() {
        let cache = RenderCache()
        #expect(cache.stats.hitRate == 0)
    }

    @Test("resetStats clears all counters")
    func resetStatsClearsCounters() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")
        cache.store(identity: identity, view: "A", buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)
        cache.clearAll()

        #expect(cache.stats.hits > 0)
        cache.resetStats()
        #expect(cache.stats == RenderCache.Stats())
    }

    @Test("reset() also clears statistics")
    func resetClearsStats() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/View")
        cache.store(identity: identity, view: "A", buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)
        _ = cache.lookup(identity: identity, view: "A", contextWidth: 80, contextHeight: 24)
        cache.clearAll()

        #expect(cache.stats.hits > 0)
        cache.reset()
        #expect(cache.stats == RenderCache.Stats())
        #expect(cache.isEmpty)
    }

    @Test("Stats delta computes per-frame difference")
    func statsDelta() {
        let earlier = RenderCache.Stats(hits: 10, misses: 5, stores: 8, clears: 2, subtreeClears: 1)
        let current = RenderCache.Stats(hits: 13, misses: 7, stores: 9, clears: 3, subtreeClears: 4)

        let delta = current.delta(since: earlier)

        #expect(delta.hits == 3)
        #expect(delta.misses == 2)
        #expect(delta.stores == 1)
        #expect(delta.clears == 1)
        #expect(delta.subtreeClears == 3)
        #expect(delta.lookups == 5)
    }

    // MARK: - clearAffected(by:)

    @Test("clearAffected clears ancestor cache entries")
    func clearAffectedClearsAncestor() {
        let cache = RenderCache()
        let parent = ViewIdentity(path: "Root/VStack")
        let child = ViewIdentity(path: "Root/VStack/Button")

        cache.store(identity: parent, view: "parent", buffer: FrameBuffer(text: "p"), contextWidth: 80, contextHeight: 24)

        cache.clearAffected(by: child)

        let result = cache.lookup(identity: parent, view: "parent", contextWidth: 80, contextHeight: 24)
        #expect(result == nil)
        #expect(cache.stats.subtreeClears == 1)
    }

    @Test("clearAffected clears descendant cache entries")
    func clearAffectedClearsDescendant() {
        let cache = RenderCache()
        let parent = ViewIdentity(path: "Root/VStack")
        let child = ViewIdentity(path: "Root/VStack/Text")

        cache.store(identity: child, view: "child", buffer: FrameBuffer(text: "c"), contextWidth: 80, contextHeight: 24)

        cache.clearAffected(by: parent)

        let result = cache.lookup(identity: child, view: "child", contextWidth: 80, contextHeight: 24)
        #expect(result == nil)
    }

    @Test("clearAffected preserves sibling cache entries")
    func clearAffectedPreservesSibling() {
        let cache = RenderCache()
        let sidebarID = ViewIdentity(path: "Root/Sidebar")
        let contentID = ViewIdentity(path: "Root/Content")
        let toggleID = ViewIdentity(path: "Root/Sidebar/Toggle")

        cache.store(identity: sidebarID, view: "sidebar", buffer: FrameBuffer(text: "s"), contextWidth: 80, contextHeight: 24)
        cache.store(identity: contentID, view: "content", buffer: FrameBuffer(text: "c"), contextWidth: 80, contextHeight: 24)

        // State change in Sidebar/Toggle should NOT affect Content
        cache.clearAffected(by: toggleID)

        let sidebarResult = cache.lookup(identity: sidebarID, view: "sidebar", contextWidth: 80, contextHeight: 24)
        let contentResult = cache.lookup(identity: contentID, view: "content", contextWidth: 80, contextHeight: 24)

        #expect(sidebarResult == nil, "Sidebar is ancestor of Toggle, should be cleared")
        #expect(contentResult != nil, "Content is sibling, should survive")
    }

    @Test("clearAffected clears exact identity match")
    func clearAffectedClearsExactMatch() {
        let cache = RenderCache()
        let identity = ViewIdentity(path: "Root/MyView")

        cache.store(identity: identity, view: 42, buffer: FrameBuffer(text: "x"), contextWidth: 80, contextHeight: 24)

        cache.clearAffected(by: identity)

        let result = cache.lookup(identity: identity, view: 42, contextWidth: 80, contextHeight: 24)
        #expect(result == nil)
    }

    @Test("clearAffected on empty cache is a no-op")
    func clearAffectedOnEmptyCacheIsNoop() {
        let cache = RenderCache()

        cache.clearAffected(by: ViewIdentity(path: "Root/Anything"))

        #expect(cache.isEmpty)
        #expect(cache.stats.subtreeClears == 1)
    }
}
