//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EquatableViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

/// A minimal equatable view for testing memoization behavior.
private struct LabelView: View, Equatable {
    let text: String

    var body: some View {
        Text(text)
    }
}

@MainActor
@Suite("EquatableView Tests", .serialized)
struct EquatableViewTests {

    /// Creates a test context with a fresh TUIContext.
    private func testContext(
        width: Int = 80,
        height: Int = 24,
        identity: ViewIdentity = ViewIdentity(path: "Root")
    ) -> RenderContext {
        RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext(),
            identity: identity
        )
    }

    // MARK: - First Render (Cache Miss)

    @Test("First render produces correct output and populates cache")
    func firstRenderPopulatesCache() {
        let context = testContext()
        let view = EquatableView(content: LabelView(text: "Hello"))

        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines.contains("Hello"))
        #expect(context.tuiContext.renderCache.count == 1)
    }

    // MARK: - Cache Hit

    @Test("Second render with equal content returns cached buffer")
    func cacheHitOnEqualContent() {
        let context = testContext()

        // First render
        let view1 = EquatableView(content: LabelView(text: "Static"))
        let buffer1 = renderToBuffer(view1, context: context)

        // Second render with equal view
        let view2 = EquatableView(content: LabelView(text: "Static"))
        let buffer2 = renderToBuffer(view2, context: context)

        #expect(buffer1.lines == buffer2.lines)
        #expect(context.tuiContext.renderCache.count == 1)
    }

    // MARK: - Cache Miss on Changed Content

    @Test("Changed content causes cache miss and re-render")
    func cacheMissOnChangedContent() {
        let context = testContext()

        // First render
        let view1 = EquatableView(content: LabelView(text: "Before"))
        let buffer1 = renderToBuffer(view1, context: context)

        // Second render with different content
        let view2 = EquatableView(content: LabelView(text: "After"))
        let buffer2 = renderToBuffer(view2, context: context)

        #expect(buffer1.lines != buffer2.lines)
        #expect(buffer2.lines.contains("After"))
    }

    // MARK: - Cache Miss on Size Change

    @Test("Changed context size causes cache miss")
    func cacheMissOnSizeChange() {
        let tuiContext = TUIContext()
        let identity = ViewIdentity(path: "Root")

        // First render at 80×24
        let context1 = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            tuiContext: tuiContext,
            identity: identity
        )
        let view = EquatableView(content: LabelView(text: "Size"))
        _ = renderToBuffer(view, context: context1)

        // Second render at 120×40 — should miss
        let context2 = RenderContext(
            availableWidth: 120,
            availableHeight: 40,
            tuiContext: tuiContext,
            identity: identity
        )
        let buffer2 = renderToBuffer(view, context: context2)

        #expect(buffer2.lines.contains("Size"))
        // Cache entry was overwritten with new size
        #expect(tuiContext.renderCache.count == 1)
    }

    // MARK: - Cache Invalidation on State Change

    @Test("clearAll empties the cache (simulates state-change invalidation)")
    func clearAllEmptiesCache() {
        let cache = RenderCache()

        cache.store(
            identity: ViewIdentity(path: "Root/A"),
            view: "value",
            buffer: FrameBuffer(text: "cached"),
            contextWidth: 80,
            contextHeight: 24
        )
        #expect(cache.count == 1)

        // StateBox.didSet calls renderCache.clearAll() — test the effect directly
        cache.clearAll()

        #expect(cache.isEmpty)
    }

    // MARK: - .equatable() Modifier

    @Test("equatable() modifier wraps view in EquatableView")
    func equatableModifierCreatesWrapper() {
        let label = LabelView(text: "Test")
        let wrapped = label.equatable()

        // Verify the wrapper produces correct output
        let context = testContext()
        let buffer = renderToBuffer(wrapped, context: context)
        #expect(buffer.lines.contains("Test"))
    }

    // MARK: - Integration with VStack

    @Test("EquatableView inside VStack renders correctly")
    func equatableViewInVStack() {
        let context = testContext()

        let stack = VStack {
            EquatableView(content: LabelView(text: "Top"))
            Text("Bottom")
        }

        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 2)
        // VStack pads shorter lines to max width (alignment), so check content prefix
        #expect(buffer.lines[0].hasPrefix("Top"))
        #expect(buffer.lines[1] == "Bottom")
    }

    // MARK: - GC Integration

    @Test("Cache entries for removed views are garbage collected")
    func cacheGarbageCollection() {
        let cache = RenderCache()
        let activeId = ViewIdentity(path: "Root/Active")
        let removedId = ViewIdentity(path: "Root/Removed")

        cache.store(identity: activeId, view: "a", buffer: FrameBuffer(text: "a"), contextWidth: 80, contextHeight: 24)
        cache.store(identity: removedId, view: "r", buffer: FrameBuffer(text: "r"), contextWidth: 80, contextHeight: 24)
        #expect(cache.count == 2)

        // Simulate render pass where only activeId is visited
        cache.beginRenderPass()
        cache.markActive(activeId)
        cache.removeInactive()

        #expect(cache.count == 1)
        #expect(cache.lookup(identity: activeId, view: "a", contextWidth: 80, contextHeight: 24) != nil)
        #expect(cache.lookup(identity: removedId, view: "r", contextWidth: 80, contextHeight: 24) == nil)
    }
}
