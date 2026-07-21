//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RenderPhaseCharacterizationTests.swift
//
//  License: MIT

import Testing
import TUIkitTestSupport

@testable import TUIkit

/// Characterizes effect leaks across the render passes of a single frame.
///
/// A frame can traverse the view tree up to three times (first-frame header
/// measurement, main pass, header-correction pass). These tests pin the
/// current misbehavior where effects escape from passes whose trees are
/// discarded. Tests that assert the DESIRED behavior are wrapped in
/// `withKnownIssue` until the corresponding fix lands (issue #13, sub-issues
/// #56/#57); once fixed, the marker must be removed. The measure-pass tests
/// are already hard expectations since the first-frame sizing traversal runs
/// in `RenderPhase.measure` (#55).
@MainActor
@Suite("Render Phase Characterization", .serialized)
struct RenderPhaseCharacterizationTests {

    @Test("Measure pass does not fire onAppear for views absent from the final tree")
    func measurePassDoesNotFireOnAppear() {
        let harness = FrameHarness(app: MeasureGateApp())

        harness.renderFrame()

        #expect(!harness.app.trace.snapshot().contains("appear:measure-only"))
    }

    @Test("Measure pass does not mount tasks for views absent from the final tree")
    func measurePassDoesNotMountTasks() {
        let harness = FrameHarness(app: MeasureGateApp())

        harness.renderFrame()

        #expect(harness.tuiContext.lifecycle.taskCount == 0)
    }

    @Test("A frame with a correction pass registers key handlers exactly once")
    func correctionPassRegistersHandlersOnce() {
        let harness = FrameHarness(app: CorrectionHeaderApp())

        // Frame 1 establishes the header height estimate.
        harness.renderFrame()
        // Growing the header invalidates the estimate, forcing frame 2
        // through the header-correction pass (main pass + corrected pass).
        harness.app.model.lineCount = 3
        harness.renderFrame()

        withKnownIssue("Issue #56: main and correction pass both register handlers") {
            #expect(harness.tuiContext.keyEventDispatcher.handlerCount == 1)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("onChange(initial:) fires exactly once in the first frame")
    func onChangeInitialFiresOncePerFrame() {
        let harness = FrameHarness(app: OnChangeApp())

        harness.renderFrame()

        withKnownIssue("Issue #57: each pass claims a fresh onChange index and re-fires") {
            #expect(harness.app.counter.value == 1)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }
}

// MARK: - Measure-Only Gating

/// Content height in the main pass: 24 (terminal) − 0 (status bar hidden)
/// − 2 (header: one line + divider). The measure pass runs with the full
/// 24 lines because the header height is not yet known, so a child gated
/// at ≥ 23 lines exists ONLY in the measure pass.
private let measureOnlyHeightThreshold = 23

/// Renders an effectful child only when the available height is at least
/// ``measureOnlyHeightThreshold`` — i.e. only during the first-frame
/// measurement pass, never in the final tree.
private struct MeasureOnlyGateView: View, Renderable {
    let trace: TraceRecorder<String>

    var body: Never {
        fatalError("MeasureOnlyGateView renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard context.availableHeight >= measureOnlyHeightThreshold else {
            return FrameBuffer(text: "short")
        }
        let measureOnlyChild = Text("tall")
            .onAppear { trace.record("appear:measure-only") }
            .task {}
        return TUIkit.renderToBuffer(measureOnlyChild, context: context)
    }
}

private struct MeasureGateApp: App {
    let trace = TraceRecorder<String>()

    init() {}

    var body: some Scene {
        WindowGroup {
            MeasureOnlyGateView(trace: trace)
                .appHeader { Text("Header") }
        }
    }
}

// MARK: - Correction-Pass Fixtures

/// Mutable header size shared between the test and the app fixture.
private final class HeaderModel {
    var lineCount = 1
}

private struct CorrectionHeaderApp: App {
    let model = HeaderModel()

    init() {}

    var body: some Scene {
        WindowGroup {
            Text("Body")
                .onKeyPress(.enter) {}
                .appHeader {
                    VStack {
                        ForEach(Array(0..<model.lineCount), id: \.self) { line in
                            Text("Header line \(line)")
                        }
                    }
                }
        }
    }
}

// MARK: - onChange Fixture

/// Reference-typed counter observable from outside the view tree.
private final class InvocationCounter {
    var value = 0
}

private struct OnChangeApp: App {
    let counter = InvocationCounter()

    init() {}

    var body: some Scene {
        WindowGroup {
            Text("Body")
                .onChange(of: 0, initial: true) { counter.value += 1 }
        }
    }
}
