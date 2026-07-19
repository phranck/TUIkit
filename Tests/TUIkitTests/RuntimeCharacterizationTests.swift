//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RuntimeCharacterizationTests.swift
//
//  License: MIT

import Observation
import Testing
import TUIkitTestSupport

@testable import TUIkit

@MainActor
@Suite("Runtime Characterization", .serialized)
struct RuntimeCharacterizationTests {
    @Test("Trace recorder snapshots and resets events")
    func traceRecorderSnapshotsAndResets() {
        let recorder = TraceRecorder<String>()

        recorder.record("first")
        recorder.record("second")

        #expect(recorder.snapshot() == ["first", "second"])

        recorder.reset()

        #expect(recorder.snapshot().isEmpty)
    }

    @Test("Async signal resumes after a pre-signal", .timeLimit(.minutes(1)))
    func asyncSignalPreservesPreSignal() async {
        let signal = AsyncSignal()

        signal.signal()
        await signal.wait()
    }

    @Test("Async signal provides a deterministic task handshake", .timeLimit(.minutes(1)))
    func asyncSignalHandshake() async {
        let started = AsyncSignal()
        let release = AsyncSignal()
        let completed = AsyncSignal()

        let worker = Task {
            started.signal()
            await release.wait()
            completed.signal()
        }

        await started.wait()
        release.signal()
        await completed.wait()
        await worker.value
    }

    @Test("Buffer snapshots preserve exact raw and ANSI-stripped lines")
    func bufferSnapshotPreservesRepresentations() {
        let harness = RuntimeCharacterizationHarness()
        let snapshot = harness.render {
            ANSICharacterizationView()
        }

        #expect(snapshot.rawLines == ["\u{1B}[31mred\u{1B}[0m", "plain"])
        #expect(snapshot.ansiStrippedLines == ["red", "plain"])
        #expect(snapshot.width == 5)
        #expect(snapshot.height == 2)
    }

    @Test("Fresh view constructions hydrate stable State across render passes")
    func stateHydratesAcrossPasses() {
        let harness = RuntimeCharacterizationHarness()

        let first = harness.render { StatefulCharacterizationView() }
        let second = harness.render { StatefulCharacterizationView() }
        let stateEvents = harness.trace.snapshot().filter {
            $0 == .state(identity: "RuntimeCharacterizationRoot", storedValues: 1)
        }

        #expect(first.ansiStrippedLines == ["value:1"])
        #expect(second.ansiStrippedLines == ["value:1"])
        #expect(stateEvents.count == 2)
    }

    @Test("A fixed lifecycle token stays mounted until an empty pass")
    func fixedLifecycleTokenStaysMounted() {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace

        _ = harness.render {
            FixedLifecycleView(token: "stable", trace: trace)
        }
        _ = harness.render {
            FixedLifecycleView(token: "stable", trace: trace)
        }

        #expect(trace.snapshot().filter { $0 == .lifecycle("appear:stable") }.count == 1)
        #expect(trace.snapshot().contains(.lifecycle("disappear:stable")) == false)

        harness.unmount()

        #expect(trace.snapshot().filter { $0 == .lifecycle("disappear:stable") }.count == 1)
    }

    @Test("Task start is observed through an explicit signal", .timeLimit(.minutes(1)))
    func taskStartUsesExplicitSignal() async {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace
        let started = AsyncSignal()

        _ = harness.render {
            Text("task")
                .task {
                    trace.record(.task("started"))
                    started.signal()
                }
        }

        await started.wait()

        #expect(trace.snapshot().contains(.task("started")))
        harness.unmount()
    }

    @Test("Observation changes can be traced deterministically", .timeLimit(.minutes(1)))
    func observationTrace() async {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace
        let changed = AsyncSignal()
        let model = CharacterizationModel()

        let initialValue = withObservationTracking {
            model.value
        } onChange: {
            trace.record(.observation("value changed"))
            changed.signal()
        }

        #expect(initialValue == 0)

        model.value = 1
        await changed.wait()

        #expect(trace.snapshot().contains(.observation("value changed")))
    }

    @Test("Generic effects are retained in the runtime trace")
    func genericEffectTrace() {
        let harness = RuntimeCharacterizationHarness()

        harness.recordEffect("preference committed")

        #expect(harness.trace.snapshot() == [.effect("preference committed")])
    }

    @Test("ForEach output remains characterized for issue #12")
    func knownForEachOutputDefect() {
        let harness = RuntimeCharacterizationHarness()
        let actualLines = harness.render {
            VStack {
                ForEach(0..<2) { index in
                    Text("row:\(index)")
                }
            }
        }.ansiStrippedLines

        withKnownIssue("Issue #12: ForEach is not rendered outside the List-specific path") {
            #expect(actualLines == ["row:0", "row:1"])
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }

    @Test("Reconstructed lifecycle modifier keeps one mounted identity")
    func reconstructedLifecycleIdentity() {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace

        _ = harness.render {
            Text("mounted")
                .onAppear {
                    trace.record(.lifecycle("reconstructed appear"))
                }
        }
        _ = harness.render {
            Text("mounted")
                .onAppear {
                    trace.record(.lifecycle("reconstructed appear"))
                }
        }

        let appearanceCount = trace.snapshot().filter {
            $0 == .lifecycle("reconstructed appear")
        }.count

        #expect(appearanceCount == 1)
    }

    @Test("Default runtime render caches are isolated")
    func defaultRuntimeRenderCachesAreIsolated() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()

        #expect(firstContext.renderCache !== secondContext.renderCache)
    }

    @Test("Cached descendant lifecycle loss remains characterized for issue #14")
    func knownCachedDescendantLifecycleDefect() {
        let harness = RuntimeCharacterizationHarness()
        let trace = harness.trace

        _ = harness.render {
            EquatableView(
                content: FixedLifecycleView(token: "cached", trace: trace)
            )
        }
        _ = harness.render {
            EquatableView(
                content: FixedLifecycleView(token: "cached", trace: trace)
            )
        }

        let disappearanceCount = trace.snapshot().filter {
            $0 == .lifecycle("disappear:cached")
        }.count

        withKnownIssue("Issue #14: a cache hit does not keep descendant lifecycle tokens active") {
            #expect(disappearanceCount == 0)
        } matching: { issue in
            guard case .expectationFailed = issue.kind else { return false }
            return true
        }
    }
}

// MARK: - Fixtures

private struct StatefulCharacterizationView: View {
    @State private var value = 1

    var body: some View {
        Text("value:\(value)")
    }
}

private struct ANSICharacterizationView: View, Renderable {
    var body: Never {
        fatalError("ANSICharacterizationView renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        FrameBuffer(lines: ["\u{1B}[31mred\u{1B}[0m", "plain"])
    }
}

private struct FixedLifecycleView: View, Renderable, Equatable {
    let token: String
    let trace: TraceRecorder<RuntimeTraceEvent>

    var body: Never {
        fatalError("FixedLifecycleView renders via Renderable")
    }

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.token == rhs.token
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let lifecycle = context.environment.lifecycle!
        _ = lifecycle.recordAppear(token: token) {
            trace.record(.lifecycle("appear:\(token)"))
        }
        lifecycle.registerDisappear(token: token) {
            trace.record(.lifecycle("disappear:\(token)"))
        }
        return FrameBuffer(text: token)
    }
}

@Observable
private final class CharacterizationModel {
    var value = 0
}
