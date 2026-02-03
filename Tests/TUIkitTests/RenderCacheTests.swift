//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderCacheTests.swift
//
//  Created by LAYERED.work
//  CC BY-NC-SA 4.0

import Testing

@testable import TUIkit

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
}
