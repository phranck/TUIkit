//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EquatableEffectTests.swift
//
//  License: MIT

import Testing
import TUIkitTestSupport

@testable import TUIkit

/// Characterizes effect loss across `EquatableView` cache hits (issue #14),
/// end-to-end through the `RenderLoop` pipeline.
///
/// On a cache hit only the wrapper identity and the subtree's state/
/// observation records are kept alive; everything else a skipped subtree
/// contributed — lifecycle slots, tasks, key handlers, status-bar items,
/// focus registrations, nested cache entries — is dropped by the frame's
/// GC or simply never reaches the final pass's collectors.
///
/// Two hit sources exist today: the first frame's measurement pass stores
/// entries into the live cache (effect sites are inert in `.measure`), so
/// the SAME frame's main pass already hits and never records the subtree's
/// effects; every later frame hits through unchanged `Equatable` content.
///
/// Each test asserts the DESIRED behavior inside `withKnownIssue`; the
/// markers drop as the fix tasks of issue #14 land.
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
        withKnownIssue("Issue #14: cache hits drop descendant lifecycle slots and cancel tasks") {
            #expect(events.filter { $0 == "appear" }.count == 1)
            #expect(events.contains("disappear") == false)
            #expect(harness.tuiContext.lifecycle.taskCount == 1)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }

        harness.tuiContext.lifecycle.reset()
    }

    @Test("Cache hits keep key handlers and status-bar items registered")
    func cacheHitKeepsHandlersAndStatusBar() {
        let harness = FrameHarness(app: CachedInputApp())

        harness.renderFrame()
        harness.renderFrame()

        withKnownIssue("Issue #14: a skipped subtree's key handler and status-bar declaration never reach the final collectors") {
            #expect(harness.tuiContext.keyEventDispatcher.handlerCount == 1)
            #expect(harness.tuiContext.statusBar.hasUserItems)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("Cache hits keep focus registrations alive")
    func cacheHitKeepsFocus() {
        let harness = FrameHarness(app: CachedFocusApp())

        harness.renderFrame()
        harness.renderFrame()

        withKnownIssue("Issue #14: a skipped subtree's focusable never reaches the staged focus registrations") {
            #expect(harness.tuiContext.focusManager.currentFocusedID != nil)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("Outer cache hits keep nested cache entries alive")
    func cacheHitKeepsNestedEntries() {
        let harness = FrameHarness(app: NestedCacheApp())

        harness.renderFrame()
        harness.renderFrame()

        withKnownIssue("Issue #14: nested cache entries are garbage-collected on the outer hit") {
            #expect(harness.tuiContext.renderCache.count == 2)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
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
