//  🖥️ TUIKit — Terminal UI Kit for Swift
//  PendingEffectCommitTests.swift
//
//  License: MIT

import Observation
import Testing
import TUIkitTestSupport

@testable import TUIkit

/// Specifies the pending-diff commit semantics of issue #57: effects that
/// OUTLIVE the frame (`onAppear`/`onDisappear` actions, `.task` mounts,
/// observation trackings, GC liveness) are only recorded during traversal
/// and applied exactly once at frame commit, diffed against persistent
/// runtime state. Discarded passes contribute nothing.
///
/// Tests assert the DESIRED behavior and carry `withKnownIssue` markers
/// until the pending diff lands (#57 Tasks 2-4); then the markers drop.
@MainActor
@Suite("Pending Effect Commit", .serialized)
struct PendingEffectCommitTests {

    @Test("A superseded pass fires no onAppear and mounts no task")
    func supersededPassLeavesNoLifetimeEffects() {
        let harness = FrameHarness(app: SupersededEffectsApp())

        // Frame 1: the gated subtree is visible (content height 22 ≥ 21),
        // so its effects legitimately belong to the committed tree.
        harness.renderFrame()
        harness.app.trace.reset()

        // Frame 2 (correction): the main pass at height 22 still contains
        // the gated subtree with a FRESH identity (the gate re-keys its
        // child by frame), but the corrected final tree at height 20 does
        // not. Its appear action must never fire.
        harness.app.model.lineCount = 3
        harness.app.gateGeneration.value += 1
        harness.renderFrame()

        #expect(!harness.app.trace.snapshot().contains("appear:superseded"))
        #expect(harness.tuiContext.lifecycle.taskCount == 0)
    }

    @Test("onAppear fires after the frame is written to the terminal")
    func onAppearFiresAfterWriteFrame() {
        let terminalWrites = TraceRecorder<Int>()
        let harness = FrameHarness(app: AppearTimingApp())
        harness.app.hook.callback = { [weak terminal = harness.terminal] in
            terminalWrites.record(terminal?.writtenOutput.count ?? -1)
        }

        harness.renderFrame()

        // The appear action must observe a non-empty terminal output:
        // commit order is collectors → writeFrame → lifetime effects.
        let writeCounts = terminalWrites.snapshot()
        #expect(!writeCounts.isEmpty)
        #expect(writeCounts.allSatisfy { $0 > 0 })
    }

    @Test("Observation trackings from the measure pass do not survive the frame")
    func measurePassObservationDoesNotSurvive() {
        let harness = FrameHarness(app: MeasureOnlyObservationApp())

        harness.renderFrame()
        harness.tuiContext.appState.didRender()

        // Mutating the model that ONLY the measure-pass tree observed must
        // not invalidate the committed frame.
        harness.app.model.value += 1

        withKnownIssue("Issue #57: measure-pass observation trackings stay current") {
            #expect(harness.tuiContext.appState.needsRender == false)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("State storage keeps records for the committed tree only")
    func gcRunsOnCommittedTreeOnly() {
        let harness = FrameHarness(app: MeasureOnlyStateApp())

        harness.renderFrame()

        let ghostPaths = harness.tuiContext.stateStorage.storedIdentities
            .map(\.path)
            .filter { $0.contains("MeasureOnlyStatefulLeaf") }

        withKnownIssue("Issue #57: GC liveness is the union of all passes") {
            #expect(ghostPaths.isEmpty)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("onPreferenceChange fires once per change, even across a correction frame")
    func onPreferenceChangeFiresOncePerChange() {
        let harness = FrameHarness(app: PreferenceActionApp())

        // First frame: the value appears → exactly one initial fire.
        harness.renderFrame()
        #expect(harness.app.trace.snapshot() == ["preference:one"])

        // Unchanged value → no fire, regardless of re-rendering.
        harness.app.trace.reset()
        harness.renderFrame()
        #expect(harness.app.trace.snapshot() == [])

        // Changed value in a frame that traverses twice (main + correction):
        // the action fires exactly once, for the committed tree.
        harness.app.title.value = "two"
        harness.app.model.lineCount = 3
        harness.renderFrame()
        #expect(harness.app.trace.snapshot() == ["preference:two"])
    }

    @Test("A stable subtree fires appear exactly once across a correction frame")
    func stableSubtreeAppearsOnceAcrossCorrection() {
        let harness = FrameHarness(app: StableAcrossCorrectionApp())

        harness.renderFrame()
        harness.app.model.lineCount = 3
        harness.renderFrame()

        let appearCount = harness.app.trace.snapshot().filter { $0 == "appear:stable" }.count
        #expect(appearCount == 1)
        #expect(harness.tuiContext.lifecycle.taskCount == 1)
    }
}

// MARK: - Fixtures

/// Reference cell so fixtures can re-key subtrees between frames.
@MainActor
private final class GenerationCell {
    var value = 0
}

/// Gated subtree whose lifecycle identity changes each generation, so its
/// appear record is fresh in every frame that contains it.
private struct SupersededEffectsApp: App {
    let model = GrowableHeaderModel()
    let gateGeneration = GenerationCell()
    let trace = TraceRecorder<String>()

    init() {}

    var body: some Scene {
        WindowGroup {
            HeightGate(
                threshold: 21,
                content: Text("ghost \(gateGeneration.value)")
                    .onAppear { trace.record("appear:superseded") }
                    .task {}
                    .id(generation: gateGeneration.value)
            )
            .appHeader { GrowingHeader(model: model) }
        }
    }
}

extension View {
    /// Re-bases the view under a generation-keyed branch identity so
    /// lifecycle slots differ between generations.
    fileprivate func id(generation: Int) -> some View {
        GenerationBranch(generation: generation, content: self)
    }
}

private struct GenerationBranch<Content: View>: View, Renderable {
    let generation: Int
    let content: Content

    var body: Never {
        fatalError("GenerationBranch renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        TUIkit.renderToBuffer(content, context: context.withBranchIdentity("gen-\(generation)"))
    }
}

/// Mutable callback slot shared between a test and its app fixture.
@MainActor
private final class CallbackCell {
    var callback: (() -> Void)?
}

/// Records the terminal write count at the moment its appear action runs.
private struct AppearTimingApp: App {
    let hook = CallbackCell()

    init() {}

    var body: some Scene {
        WindowGroup {
            Text("timing").onAppear { hook.callback?() }
        }
    }
}

@Observable
private final class ObservedModel {
    var value = 0
}

/// Observes a model in a composite body that exists ONLY in the measure
/// pass (phase-gated).
private struct MeasureOnlyObservationApp: App {
    let model = ObservedModel()

    init() {}

    var body: some Scene {
        WindowGroup {
            MeasurePhaseGate(content: ObservingLeaf(model: model))
        }
    }
}

/// Composite view whose body reads the observable model.
private struct ObservingLeaf: View {
    let model: ObservedModel

    var body: some View {
        Text("value: \(model.value)")
    }
}

/// Renders its content only during the measurement phase.
private struct MeasurePhaseGate<Content: View>: View, Renderable {
    let content: Content

    var body: Never {
        fatalError("MeasurePhaseGate renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard context.phase == .measure else {
            return FrameBuffer(text: "committed body")
        }
        return TUIkit.renderToBuffer(content, context: context)
    }
}

/// Holds @State in a leaf that exists ONLY in the measure pass.
private struct MeasureOnlyStateApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            MeasurePhaseGate(content: MeasureOnlyStatefulLeaf())
        }
    }
}

private struct MeasureOnlyStatefulLeaf: View {
    @State private var counter = 7

    var body: some View {
        Text("counter: \(counter)")
    }
}

/// Mutable string cell shared between a test and its app fixture.
@MainActor
private final class StringCell {
    var value = "one"
}

/// Declares a preference and observes it; the change action must fire once
/// per VALUE CHANGE (SwiftUI semantics), regardless of how many passes a
/// frame needed.
private struct PreferenceActionApp: App {
    let model = GrowableHeaderModel()
    let title = StringCell()
    let trace = TraceRecorder<String>()

    init() {}

    var body: some Scene {
        WindowGroup {
            Text("body")
                .preference(key: NavigationTitleKey.self, value: title.value)
                .onPreferenceChange(NavigationTitleKey.self) { value in
                    trace.record("preference:\(value)")
                }
                .appHeader { GrowingHeader(model: model) }
        }
    }
}

/// A subtree present in every pass of every frame: its lifetime effects
/// must behave identically for single-pass and correction frames.
private struct StableAcrossCorrectionApp: App {
    let model = GrowableHeaderModel()
    let trace = TraceRecorder<String>()

    init() {}

    var body: some Scene {
        WindowGroup {
            Text("stable")
                .onAppear { trace.record("appear:stable") }
                .task {}
                .appHeader { GrowingHeader(model: model) }
        }
    }
}
