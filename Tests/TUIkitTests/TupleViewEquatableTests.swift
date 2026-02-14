//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TupleViewEquatableTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("TupleView Equatable Tests", .serialized)
struct TupleViewEquatableTests {

    /// Creates a test context with a fresh environment including an isolated render cache.
    private func testContext(
        width: Int = 80,
        height: Int = 24,
        identity: ViewIdentity = ViewIdentity(path: "Root")
    ) -> RenderContext {
        // Use an isolated render cache for testing to avoid cross-test pollution
        let isolatedCache = RenderCache()
        let tuiContext = TUIContext(
            lifecycle: LifecycleManager(),
            keyEventDispatcher: KeyEventDispatcher(),
            preferences: PreferenceStorage(),
            stateStorage: StateStorage(),
            renderCache: isolatedCache
        )
        var env = EnvironmentValues()
        env.stateStorage = tuiContext.stateStorage
        env.lifecycle = tuiContext.lifecycle
        env.keyEventDispatcher = tuiContext.keyEventDispatcher
        env.renderCache = tuiContext.renderCache
        env.preferenceStorage = tuiContext.preferences
        return RenderContext(
            availableWidth: width,
            availableHeight: height,
            environment: env,
            identity: identity
        )
    }

    // MARK: - Equality

    @Test("TupleView with identical Text children compares as equal")
    func equalChildren() {
        let view1 = VStack {
            Text("Hello")
            Text("World")
        }
        let view2 = VStack {
            Text("Hello")
            Text("World")
        }

        #expect(view1 == view2)
    }

    @Test("TupleView with different Text children compares as not equal")
    func differentChildren() {
        let view1 = VStack {
            Text("Hello")
            Text("World")
        }
        let view2 = VStack {
            Text("Hello")
            Text("Changed")
        }

        #expect(view1 != view2)
    }

    @Test("TupleView with three children compares correctly")
    func threeChildren() {
        let view1 = VStack {
            Text("A")
            Text("B")
            Text("C")
        }
        let view2 = VStack {
            Text("A")
            Text("B")
            Text("C")
        }
        let view3 = VStack {
            Text("A")
            Text("X")
            Text("C")
        }

        #expect(view1 == view2)
        #expect(view1 != view3)
    }

    @Test("Single-child TupleView compares correctly")
    func singleChild() {
        let view1 = VStack { Text("Solo") }
        let view2 = VStack { Text("Solo") }
        let view3 = VStack { Text("Other") }

        #expect(view1 == view2)
        #expect(view1 != view3)
    }

    // MARK: - Cache Integration

    @Test("VStack with equatable content gets cache hit on second render")
    func cacheHitForEqualVStack() {
        let context = testContext()
        let cache = context.environment.renderCache!

        let stack1 = VStack {
            Text("Static A")
            Text("Static B")
        }
        let eq1 = EquatableView(content: stack1)
        _ = renderToBuffer(eq1, context: context)

        #expect(cache.stats.misses == 1)
        #expect(cache.stats.hits == 0)

        // Second render with equal content
        let stack2 = VStack {
            Text("Static A")
            Text("Static B")
        }
        let eq2 = EquatableView(content: stack2)
        _ = renderToBuffer(eq2, context: context)

        #expect(cache.stats.hits == 1)
    }

    @Test("VStack with changed content causes cache miss")
    func cacheMissForChangedVStack() {
        let context = testContext()
        let cache = context.environment.renderCache!

        let stack1 = VStack {
            Text("Before")
            Text("Content")
        }
        let eq1 = EquatableView(content: stack1)
        let buffer1 = renderToBuffer(eq1, context: context)

        // Second render with different content
        let stack2 = VStack {
            Text("After")
            Text("Content")
        }
        let eq2 = EquatableView(content: stack2)
        let buffer2 = renderToBuffer(eq2, context: context)

        #expect(buffer1.lines != buffer2.lines)
        #expect(cache.stats.misses == 2)
        #expect(cache.stats.hits == 0)
    }

    @Test("Nested equatable containers get independent cache hits")
    func nestedCacheHits() {
        // Use an isolated render cache for testing to avoid cross-test pollution
        let isolatedCache = RenderCache()
        let tuiContext = TUIContext(
            lifecycle: LifecycleManager(),
            keyEventDispatcher: KeyEventDispatcher(),
            preferences: PreferenceStorage(),
            stateStorage: StateStorage(),
            renderCache: isolatedCache
        )
        let cache = tuiContext.renderCache

        var env = EnvironmentValues()
        env.stateStorage = tuiContext.stateStorage
        env.lifecycle = tuiContext.lifecycle
        env.keyEventDispatcher = tuiContext.keyEventDispatcher
        env.renderCache = tuiContext.renderCache
        env.preferenceStorage = tuiContext.preferences

        let innerIdentity = ViewIdentity(path: "Root/Inner")
        let outerIdentity = ViewIdentity(path: "Root/Outer")

        // Render inner
        let innerContext = RenderContext(
            availableWidth: 80, availableHeight: 24,
            environment: env, identity: innerIdentity
        )
        let inner = EquatableView(content: HStack {
            Text("Left")
            Text("Right")
        })
        _ = renderToBuffer(inner, context: innerContext)

        // Render outer
        let outerContext = RenderContext(
            availableWidth: 80, availableHeight: 24,
            environment: env, identity: outerIdentity
        )
        let outer = EquatableView(content: VStack {
            Text("Top")
            Text("Bottom")
        })
        _ = renderToBuffer(outer, context: outerContext)

        #expect(cache.count == 2)
        #expect(cache.stats.stores == 2)
    }

    // MARK: - .equatable() Modifier on VStack

    @Test("equatable() on VStack with equatable content compiles and renders")
    func equatableModifierOnVStack() {
        let context = testContext()

        let stack = VStack {
            Text("A")
            Text("B")
        }.equatable()

        let buffer = renderToBuffer(stack, context: context)

        #expect(buffer.height == 2)
        #expect(buffer.lines[0].stripped.hasPrefix("A"))
        #expect(buffer.lines[1].stripped == "B")
    }

    @Test("equatable() on HStack with equatable content renders correctly")
    func equatableModifierOnHStack() {
        let context = testContext()

        let stack = HStack {
            Text("Left")
            Text("Right")
        }.equatable()

        let buffer = renderToBuffer(stack, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].contains("Left"))
        #expect(buffer.lines[0].contains("Right"))
    }
}
