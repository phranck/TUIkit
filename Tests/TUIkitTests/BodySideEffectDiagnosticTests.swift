//  🖥️ TUIKit — Terminal UI Kit for Swift
//  BodySideEffectDiagnosticTests.swift
//
//  License: MIT

import Testing
import TUIkitTestSupport

@testable import TUIkit

/// Specifies the diagnostics for unsupported user side effects inside view
/// bodies (issue #58, acceptance criterion of #13): the framework cannot
/// prevent arbitrary user code from mutating state during traversal, but it
/// must DIAGNOSE it — without crashing, swallowing the invalidation, or
/// looping forever. Legitimate invalidations (committed effect actions,
/// background tasks) stay silent.
@MainActor
@Suite("Body Side-Effect Diagnostics", .serialized)
struct BodySideEffectDiagnosticTests {

    @Test("State mutation during traversal produces one diagnostic per frame")
    func stateMutationDuringTraversalIsDiagnosed() {
        let harness = FrameHarness(app: MutatingBodyApp())

        harness.renderFrame()

        let messages = harness.tuiContext.runtimeDiagnostics.messages
        #expect(messages.count == 1)
        #expect(messages.first?.contains("during view body evaluation") == true)
        // The invalidation itself is still honored — rendering continues.
        #expect(harness.tuiContext.appState.needsRender)
        #expect(!harness.terminal.writtenOutput.isEmpty)
    }

    @Test("Imperative status-bar mutation during traversal is diagnosed")
    func statusBarMutationDuringTraversalIsDiagnosed() {
        let harness = FrameHarness(app: StatusBarMutatingApp())

        harness.renderFrame()

        let messages = harness.tuiContext.runtimeDiagnostics.messages
        #expect(messages.count == 1)
        #expect(messages.first?.contains("during view body evaluation") == true)
    }

    @Test("State mutation from a committed onAppear action stays silent")
    func committedEffectMutationIsNotDiagnosed() {
        let harness = FrameHarness(app: AppearMutatingApp())
        // A sink-bound state box, mutated by the appear action at commit —
        // the legitimate invalidation path that must NOT be diagnosed.
        let key = StateStorage.StateKey(
            identity: ViewIdentity(path: "appear-cell"),
            propertyIndex: 0
        )
        let box: StateBox<Int> = harness.tuiContext.stateStorage.storage(for: key, default: 0)
        harness.app.hook.callback = { box.value += 1 }

        harness.renderFrame()

        #expect(harness.tuiContext.runtimeDiagnostics.messages.isEmpty)
        // The appear action ran and requested the follow-up frame.
        #expect(box.value == 1)
        #expect(harness.tuiContext.appState.needsRender)
    }
}

// MARK: - Fixtures

/// Mutates persistent state in the middle of its render traversal — the
/// unsupported pattern the framework must diagnose.
private struct TraversalMutatingLeaf: View, Renderable {
    var body: Never {
        fatalError("TraversalMutatingLeaf renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard context.phase == .render else {
            return FrameBuffer(text: "measuring")
        }
        let storage = context.environment.stateStorage!
        let key = StateStorage.StateKey(identity: context.identity, propertyIndex: 0)
        let box: StateBox<Int> = storage.storage(for: key, default: 0)
        box.value += 1
        return FrameBuffer(text: "mutated \(box.value)")
    }
}

private struct MutatingBodyApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            TraversalMutatingLeaf()
        }
    }
}

/// Calls the re-render-triggering imperative status-bar API from inside a
/// render traversal.
private struct StatusBarMutatingLeaf: View, Renderable {
    var body: Never {
        fatalError("StatusBarMutatingLeaf renders via Renderable")
    }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        guard context.phase == .render else {
            return FrameBuffer(text: "measuring")
        }
        context.environment.statusBar.setItems([
            StatusBarItem(shortcut: "x", label: "mutation")
        ])
        return FrameBuffer(text: "status mutated")
    }
}

private struct StatusBarMutatingApp: App {
    init() {}

    var body: some Scene {
        WindowGroup {
            StatusBarMutatingLeaf()
        }
    }
}

/// Mutable callback slot shared between a test and its app fixture.
@MainActor
private final class CallbackCell {
    var callback: (() -> Void)?
}

/// Mutates state from onAppear — a lifetime effect that runs at frame
/// commit, after traversal, and therefore must NOT be diagnosed.
private struct AppearMutatingApp: App {
    let hook = CallbackCell()

    init() {}

    var body: some Scene {
        WindowGroup {
            Text("appear")
                .onAppear { hook.callback?() }
        }
    }
}
