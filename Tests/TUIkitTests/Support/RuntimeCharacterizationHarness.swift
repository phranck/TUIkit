//  🖥️ TUIKit — Terminal UI Kit for Swift
//  RuntimeCharacterizationHarness.swift
//
//  License: MIT

import TUIkitTestSupport

@testable import TUIkit

/// Deterministic events emitted by runtime characterization fixtures.
enum RuntimeTraceEvent: Sendable, Equatable {
    case buffer(BufferSnapshot)
    case state(identity: String, storedValues: Int)
    case lifecycle(String)
    case task(String)
    case observation(String)
    case effect(String)
}

/// Isolated render-pass driver shared by runtime characterization tests.
@MainActor
final class RuntimeCharacterizationHarness {
    let trace = TraceRecorder<RuntimeTraceEvent>()

    var storedStateCount: Int {
        stateStorage.count
    }

    var storedStateIdentityPaths: [String] {
        stateStorage.storedIdentities.map(\.path).sorted()
    }

    var currentDiagnosticMessages: [String] {
        tuiContext.runtimeDiagnostics.messages
    }

    var mountedLifecycleCallbackCount: Int {
        lifecycle.disappearCallbackCount
    }

    var mountedTaskCount: Int {
        lifecycle.taskCount
    }

    var observationRegistrationCount: Int {
        tuiContext.observationRegistry.count
    }

    var currentFocusedID: String? {
        tuiContext.focusManager.currentFocusedID
    }

    private let availableWidth: Int
    private let availableHeight: Int
    private let rootIdentity = ViewIdentity(path: "RuntimeCharacterizationRoot")

    private let lifecycle: LifecycleManager
    private let stateStorage: StateStorage
    private let tuiContext: TUIContext

    init(availableWidth: Int = 80, availableHeight: Int = 24) {
        self.availableWidth = availableWidth
        self.availableHeight = availableHeight

        let lifecycle = LifecycleManager()
        let stateStorage = StateStorage()

        self.lifecycle = lifecycle
        self.stateStorage = stateStorage
        self.tuiContext = TUIContext(
            lifecycle: lifecycle,
            stateStorage: stateStorage
        )
    }

    @discardableResult
    func withRenderPass<Result>(
        _ operation: (RenderContext) throws -> Result
    ) rethrows -> Result {
        tuiContext.beginRenderPass()

        defer {
            tuiContext.focusManager.endRenderPass()
            tuiContext.endRenderPass()
        }

        let context = RenderContext(
            availableWidth: availableWidth,
            availableHeight: availableHeight,
            tuiContext: tuiContext,
            identity: rootIdentity
        )
        return try operation(context)
    }

    @discardableResult
    func render<Root: View>(
        @ViewBuilder build: () -> Root
    ) -> BufferSnapshot {
        withRenderPass { context in
            let root = StateRegistration.withHydration(context: context) {
                build()
            }
            stateStorage.markActive(rootIdentity)

            let buffer = renderToBuffer(root, context: context)
            let snapshot = BufferSnapshot(
                rawLines: buffer.lines,
                ansiStrippedLines: buffer.lines.map(\.stripped),
                width: buffer.width,
                height: buffer.height
            )

            trace.record(.buffer(snapshot))
            trace.record(
                .state(
                    identity: rootIdentity.path,
                    storedValues: stateStorage.count
                )
            )
            return snapshot
        }
    }

    func pass(_ operation: (RenderContext) -> Void = { _ in }) {
        withRenderPass(operation)
    }

    func unmount() {
        pass()
    }

    @discardableResult
    func dispatchFocusEvent(_ event: KeyEvent) -> Bool {
        tuiContext.focusManager.dispatchKeyEvent(event)
    }

    func consumePendingRenderInvalidations() -> [RenderInvalidation] {
        tuiContext.appState.consumePendingCacheInvalidations()
    }

    func recordEffect(_ description: String) {
        trace.record(.effect(description))
    }
}
