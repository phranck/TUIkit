//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderPassCollectorTests.swift
//
//  License: MIT

import Testing
import TUIkitTestSupport

@testable import TUIkit

/// Specifies the pass-collector adoption semantics of issue #56: effects
/// that do not outlive the frame (key handlers, preference callbacks,
/// status-bar items, header buffer, focus registrations) must reach live
/// runtime state exclusively from the frame's FINAL pass. Discarded passes
/// (first-frame measurement, superseded main pass before a header
/// correction) leave no trace.
///
/// Tests assert the DESIRED behavior and carry `withKnownIssue` markers
/// until the collectors land (#56 Tasks 2-4); then the markers drop.
@MainActor
@Suite("Render Pass Collectors", .serialized)
struct RenderPassCollectorTests {

    @Test("A header declared only in the measure pass never reaches live state")
    func abandonedHeaderDoesNotReachLiveState() {
        let harness = FrameHarness(app: MeasureOnlyHeaderApp())

        harness.renderFrame()

        withKnownIssue("Issue #56: the measure pass writes the live header buffer") {
            #expect(harness.tuiContext.appHeader.hasContent == false)
            #expect(harness.tuiContext.appHeader.height == 0)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("Preference callbacks do not accumulate across passes of one frame")
    func preferenceCallbacksDoNotAccumulateAcrossPasses() {
        let harness = FrameHarness(app: CorrectionPreferenceApp())

        // Frame 1 establishes the header height estimate; growing the header
        // forces frame 2 through the correction pass.
        harness.renderFrame()
        harness.app.model.lineCount = 3
        harness.renderFrame()

        withKnownIssue("Issue #56: each pass appends its callbacks to the live storage") {
            #expect(harness.tuiContext.preferences.callbackCount == 1)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("Status-bar items from a superseded pass do not persist")
    func statusBarItemsFromSupersededPassDoNotPersist() {
        let harness = FrameHarness(app: CorrectionGatedStatusBarApp())

        harness.renderFrame()
        harness.app.model.lineCount = 3
        harness.renderFrame()

        // The gated declaration exists at content height 22 (main pass of
        // frame 2) but not at 20 (correction pass) — the final tree has no
        // user items.
        withKnownIssue("Issue #56: the superseded main pass writes live status-bar items") {
            #expect(harness.tuiContext.statusBar.hasUserItems == false)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("Focus registrations come from the final pass only")
    func focusRegistrationsComeFromFinalPass() {
        let harness = FrameHarness(app: CorrectionGatedButtonApp())

        harness.renderFrame()
        harness.app.model.lineCount = 3
        harness.renderFrame()

        // The button exists in the superseded main pass (height 22) but not
        // in the corrected final tree (height 20): nothing may stay focused.
        withKnownIssue("Issue #56: focusables from the superseded pass stay registered") {
            #expect(harness.tuiContext.focusManager.currentFocusedID == nil)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("Focus changes fire after traversal, not during it")
    func focusChangeFiresOnlyAtCommit() {
        let harness = FrameHarness(app: TraceOrderingApp())
        let trace = harness.app.trace
        let previousHandler = harness.tuiContext.focusManager.onFocusChange
        harness.tuiContext.focusManager.onFocusChange = {
            previousHandler?()
            trace.record("focusChange")
        }

        harness.renderFrame()

        let events = trace.snapshot()
        let lastRenderIndex = events.lastIndex { $0.hasPrefix("render:") }
        let firstFocusChangeIndex = events.firstIndex(of: "focusChange")

        withKnownIssue("Issue #56: auto-focus fires onFocusChange during traversal") {
            if let lastRenderIndex, let firstFocusChangeIndex {
                #expect(lastRenderIndex < firstFocusChangeIndex)
            }
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }
}

// MARK: - Shared Fixtures

/// Mutable header size shared between the test and the app fixtures.
@MainActor
final class GrowableHeaderModel {
    var lineCount = 1
}

/// Renders `content` only when the available height is at least `threshold`.
///
/// Records nothing and has no effects of its own; used to make a subtree
/// exist in one pass of a frame but not in another (measure vs. main, or
/// main vs. correction).
private struct HeightGate<Content: View>: View, Renderable {
    let threshold: Int
    let content: Content

    var body: Never {
        fatalError("HeightGate renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard context.availableHeight >= threshold else {
            return FrameBuffer(text: "below-gate")
        }
        return TUIkit.renderToBuffer(content, context: context)
    }
}

/// Grows the app header via `GrowableHeaderModel` so frame 2 runs through
/// the header-correction pass (estimate 2, actual 4 → content 22 → 20).
private struct GrowingHeader: View {
    let model: GrowableHeaderModel

    var body: some View {
        VStack {
            ForEach(Array(0..<model.lineCount), id: \.self) { line in
                Text("Header line \(line)")
            }
        }
    }
}

// MARK: - Per-Test Apps

/// Declares an app header ONLY in the measure pass (full 24 rows); the
/// visible tree at 22 rows has no header at all.
private struct MeasureOnlyHeaderApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            HeightGate(threshold: 23, content: Text("body").appHeader { Text("ghost header") })
        }
    }
}

private struct CorrectionPreferenceApp: App {
    let model = GrowableHeaderModel()

    init() {}

    var body: some Scene {
        WindowGroup {
            Text("body")
                .preference(key: NavigationTitleKey.self, value: "title")
                .onPreferenceChange(NavigationTitleKey.self) { _ in }
                .appHeader { GrowingHeader(model: model) }
        }
    }
}

/// Status-bar items gated at ≥ 21 rows: present in frame 2's superseded
/// main pass (22), absent from its corrected final tree (20).
private struct CorrectionGatedStatusBarApp: App {
    let model = GrowableHeaderModel()

    init() {}

    var body: some Scene {
        WindowGroup {
            HeightGate(
                threshold: 21,
                content: Text("body").statusBarItems {
                    StatusBarItem(shortcut: "g", label: "ghost")
                }
            )
            .appHeader { GrowingHeader(model: model) }
        }
    }
}

/// A focusable button gated at ≥ 21 rows: focused in frame 1 and in frame
/// 2's superseded main pass, absent from frame 2's corrected final tree.
private struct CorrectionGatedButtonApp: App {
    let model = GrowableHeaderModel()

    init() {}

    var body: some Scene {
        WindowGroup {
            HeightGate(
                threshold: 21,
                content: Button("Ghost") {}
            )
            .appHeader { GrowingHeader(model: model) }
        }
    }
}

/// Records the traversal order of two leaf views around a focusable button
/// so tests can assert that focus callbacks fire only after traversal.
private struct TraceOrderingApp: App {
    let trace = TraceRecorder<String>()

    init() {}

    var body: some Scene {
        WindowGroup {
            VStack {
                TraceLeaf(label: "first", trace: trace)
                Button("Focus me") {}
                TraceLeaf(label: "last", trace: trace)
            }
        }
    }
}

/// Leaf that records each output-phase render; measurement traversals are
/// intentionally silent so layout probing does not pollute the trace.
private struct TraceLeaf: View, Renderable {
    let label: String
    let trace: TraceRecorder<String>

    var body: Never {
        fatalError("TraceLeaf renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        if context.phase == .render {
            trace.record("render:\(label)")
        }
        return FrameBuffer(text: label)
    }
}
