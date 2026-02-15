//  🖥️ TUIKit — Terminal UI Kit for Swift
//  OnChangeTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Tests

@MainActor
@Suite("onChange Modifier Tests")
struct OnChangeTests {

    // MARK: - Helpers

    /// Renders a view with the given value and returns the buffer.
    private func render<V: View>(_ view: V, width: Int = 40, height: Int = 10) -> FrameBuffer {
        let context = RenderContext(
            availableWidth: width,
            availableHeight: height,
            tuiContext: TUIContext()
        )
        return renderToBuffer(view, context: context)
    }

    /// Creates a render context with shared state storage for multi-pass tests.
    private func makeContext(storage: StateStorage) -> RenderContext {
        var env = EnvironmentValues()
        env.stateStorage = storage
        return RenderContext(
            availableWidth: 40,
            availableHeight: 10,
            environment: env,
            identity: ViewIdentity(rootType: OnChangeTests.self)
        )
    }

    // MARK: - Basic Change Detection

    @Test("onChange fires when value changes between render passes")
    func firesOnChange() {
        let storage = StateStorage()
        var fired = false

        let view1 = Text("A").onChange(of: 1) { _, _ in fired = true }
        let context = makeContext(storage: storage)

        storage.beginRenderPass()
        _ = renderToBuffer(view1, context: context)
        storage.endRenderPass()
        #expect(!fired)

        // Second render with different value
        let view2 = Text("A").onChange(of: 2) { _, _ in fired = true }
        storage.beginRenderPass()
        _ = renderToBuffer(view2, context: context)
        storage.endRenderPass()
        #expect(fired)
    }

    @Test("onChange provides correct old and new values")
    func providesOldAndNewValues() {
        let storage = StateStorage()
        var capturedOld = 0
        var capturedNew = 0

        let view1 = Text("A").onChange(of: 10) { old, new in
            capturedOld = old
            capturedNew = new
        }
        let context = makeContext(storage: storage)

        storage.beginRenderPass()
        _ = renderToBuffer(view1, context: context)
        storage.endRenderPass()

        let view2 = Text("A").onChange(of: 42) { old, new in
            capturedOld = old
            capturedNew = new
        }
        storage.beginRenderPass()
        _ = renderToBuffer(view2, context: context)
        storage.endRenderPass()

        #expect(capturedOld == 10)
        #expect(capturedNew == 42)
    }

    @Test("onChange does not fire when value is unchanged")
    func doesNotFireWhenUnchanged() {
        let storage = StateStorage()
        var fireCount = 0

        let view = Text("A").onChange(of: 5) { _, _ in fireCount += 1 }
        let context = makeContext(storage: storage)

        // Render twice with same value
        storage.beginRenderPass()
        _ = renderToBuffer(view, context: context)
        storage.endRenderPass()

        storage.beginRenderPass()
        _ = renderToBuffer(view, context: context)
        storage.endRenderPass()

        #expect(fireCount == 0)
    }

    // MARK: - Initial Parameter

    @Test("onChange with initial: true fires on first render")
    func initialFiresOnFirstRender() {
        let storage = StateStorage()
        var fired = false
        var capturedOld = -1
        var capturedNew = -1

        let view = Text("A").onChange(of: 7, initial: true) { old, new in
            fired = true
            capturedOld = old
            capturedNew = new
        }
        let context = makeContext(storage: storage)

        storage.beginRenderPass()
        _ = renderToBuffer(view, context: context)
        storage.endRenderPass()

        #expect(fired)
        #expect(capturedOld == 7)
        #expect(capturedNew == 7)
    }

    @Test("onChange with initial: false (default) skips first render")
    func initialFalseSkipsFirstRender() {
        let storage = StateStorage()
        var fired = false

        let view = Text("A").onChange(of: 7) { _, _ in fired = true }
        let context = makeContext(storage: storage)

        storage.beginRenderPass()
        _ = renderToBuffer(view, context: context)
        storage.endRenderPass()

        #expect(!fired)
    }

    // MARK: - Zero-Parameter Variant

    @Test("onChange zero-parameter variant fires on change")
    func zeroParameterVariant() {
        let storage = StateStorage()
        var fired = false

        let view1 = Text("A").onChange(of: "hello") { fired = true }
        let context = makeContext(storage: storage)

        storage.beginRenderPass()
        _ = renderToBuffer(view1, context: context)
        storage.endRenderPass()

        let view2 = Text("A").onChange(of: "world") { fired = true }
        storage.beginRenderPass()
        _ = renderToBuffer(view2, context: context)
        storage.endRenderPass()

        #expect(fired)
    }

    // MARK: - Multiple onChange

    @Test("Multiple onChange on same view track independently")
    func multipleOnChangeSameView() {
        let storage = StateStorage()
        var intFired = false
        var stringFired = false

        let view1 = Text("A")
            .onChange(of: 1) { _, _ in intFired = true }
            .onChange(of: "a") { _, _ in stringFired = true }
        let context = makeContext(storage: storage)

        storage.beginRenderPass()
        _ = renderToBuffer(view1, context: context)
        storage.endRenderPass()

        // Change only the int value
        let view2 = Text("A")
            .onChange(of: 2) { _, _ in intFired = true }
            .onChange(of: "a") { _, _ in stringFired = true }
        storage.beginRenderPass()
        _ = renderToBuffer(view2, context: context)
        storage.endRenderPass()

        #expect(intFired)
        #expect(!stringFired)
    }
}
