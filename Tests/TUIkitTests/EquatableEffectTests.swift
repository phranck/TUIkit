//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EquatableEffectTests.swift
//
//  License: MIT

import Testing
import TUIkitTestSupport

@testable import TUIkit

/// Specifies effect behavior across `EquatableView` cache hits (issue #14),
/// end-to-end through the `RenderLoop` pipeline.
///
/// Effect-bearing content is detected on every cache miss via the pass's
/// effect-registration probe and bypasses the cache entirely, so lifecycle
/// slots, tasks, key handlers, status-bar items, and focus registrations
/// reach the frame's collectors on every frame. Measurement passes stay
/// out of the cache so classification never measures an inert traversal
/// and the first frame's output pass cannot hit a sizing buffer. Nested
/// cache entries below an effect-free cached root survive outer hits via
/// `RenderCache.markSubtreeActive`.
@MainActor
@Suite("EquatableView Effect Characterization", .serialized)
struct EquatableEffectTests {

    @Test("Cache hits keep lifecycle slots and tasks mounted")
    func cacheHitKeepsLifecycleAndTask() {
        let app = CachedLifecycleApp()
        let harness = FrameHarness(app: app)

        harness.renderFrame()
        harness.renderFrame()

        let events = app.trace.snapshot()
        #expect(events.filter { $0 == "appear" }.count == 1)
        #expect(events.contains("disappear") == false)
        #expect(harness.tuiContext.lifecycle.taskCount == 1)

        harness.tuiContext.lifecycle.reset()
    }

    @Test("Cache hits keep key handlers and status-bar items registered")
    func cacheHitKeepsHandlersAndStatusBar() {
        let harness = FrameHarness(app: CachedInputApp())

        harness.renderFrame()
        harness.renderFrame()

        #expect(harness.tuiContext.keyEventDispatcher.handlerCount == 1)
        #expect(harness.tuiContext.statusBar.hasUserItems)
    }

    @Test("Cache hits keep focus registrations alive")
    func cacheHitKeepsFocus() {
        let harness = FrameHarness(app: CachedFocusApp())

        harness.renderFrame()
        harness.renderFrame()

        #expect(harness.tuiContext.focusManager.currentFocusedID != nil)
    }

    @Test("Cache hits keep declared focus sections registered")
    func cacheHitKeepsFocusSections() {
        let harness = FrameHarness(app: CachedSectionApp())

        harness.renderFrame()
        harness.renderFrame()

        #expect(harness.tuiContext.focusManager.sectionIDs.contains("cached-section"))
    }

    @Test("Outer cache hits keep nested cache entries alive")
    func cacheHitKeepsNestedEntries() {
        let harness = FrameHarness(app: NestedCacheApp())

        harness.renderFrame()
        harness.renderFrame()

        #expect(harness.tuiContext.renderCache.count == 2)
    }

    @Test("Foreground style changes invalidate cached content")
    func foregroundStyleChangeInvalidatesEntry() {
        let app = StyledCacheApp()
        let harness = FrameHarness(app: app)

        harness.renderFrame()
        harness.renderFrame()

        app.cell.color = .green
        let statsBeforeChange = harness.tuiContext.renderCache.stats
        harness.renderFrame()
        let changeDelta = harness.tuiContext.renderCache.stats.delta(since: statsBeforeChange)

        // The style change must miss and re-render; a hit would serve a
        // buffer rendered with the previous color.
        #expect(changeDelta.hits == 0)
        #expect(changeDelta.stores == 1)

        // With the style stable again, caching resumes.
        let statsAfterChange = harness.tuiContext.renderCache.stats
        harness.renderFrame()
        let steadyDelta = harness.tuiContext.renderCache.stats.delta(since: statsAfterChange)
        #expect(steadyDelta.hits == 1)
    }
}

// MARK: - Fixtures

/// Content whose `==` is always true, so every lookup after the first store
/// is a guaranteed cache hit regardless of captured references.
private struct CachedLifecycleContent: View, Equatable {
    let trace: TraceRecorder<String>

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { true }

    var body: some View {
        Text("cached")
            .onAppear { trace.record("appear") }
            .onDisappear { trace.record("disappear") }
            .task {
                // Runs until cancellation so `lifecycle.taskCount` observes
                // whether the mount survived the frame.
                try? await Task.sleep(nanoseconds: 60_000_000_000)
            }
    }
}

private struct CachedLifecycleApp: App {
    let trace = TraceRecorder<String>()

    init() {}

    var body: some Scene {
        WindowGroup {
            CachedLifecycleContent(trace: trace).equatable()
        }
    }
}

/// Declares a key handler and a status-bar item inside cacheable content.
private struct CachedInputContent: View, Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { true }

    var body: some View {
        Text("input")
            .onKeyPress(.enter) {}
            .statusBarItems([StatusBarItem(shortcut: "x", label: "cached")])
    }
}

private struct CachedInputApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            CachedInputContent().equatable()
        }
    }
}

/// Places a focusable control inside cacheable content.
private struct CachedFocusContent: View, Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { true }

    var body: some View {
        Button("Press") {}
    }
}

private struct CachedFocusApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            CachedFocusContent().equatable()
        }
    }
}

/// Mutable foreground color shared between a test and its app fixture.
@MainActor
private final class ColorCell {
    var color: Color = .red
}

/// Effect-free content whose parent applies a changing foreground style.
private struct StyledCachedContent: View, Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { true }

    var body: some View {
        Text("styled")
    }
}

private struct StyledCacheApp: App {
    let cell = ColorCell()

    init() {}

    var body: some Scene {
        WindowGroup {
            StyledCachedContent()
                .equatable()
                .foregroundStyle(cell.color)
        }
    }
}

/// Declares a focus section (without focusables) inside cacheable content.
private struct CachedSectionContent: View, Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { true }

    var body: some View {
        Text("sectioned").focusSection("cached-section")
    }
}

private struct CachedSectionApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            CachedSectionContent().equatable()
        }
    }
}

/// Effect-free inner content cached below an effect-free cached outer view.
private struct InnerCachedContent: View, Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { true }

    var body: some View {
        Text("inner")
    }
}

private struct OuterCachedContent: View, Equatable {
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool { true }

    var body: some View {
        VStack {
            Text("outer")
            InnerCachedContent().equatable()
        }
    }
}

private struct NestedCacheApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            OuterCachedContent().equatable()
        }
    }
}
