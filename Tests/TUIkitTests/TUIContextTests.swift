//  🖥️ TUIKit — Terminal UI Kit for Swift
//  TUIContextTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import Testing

@testable import TUIkit

@MainActor
@Suite("TUIContext Tests")
struct TUIContextTests {

    @Test("Services are independent per context")
    func independentServices() {
        let contextA = TUIContext()
        let contextB = TUIContext()
        // Each context has its own lifecycle manager
        contextA.lifecycle.recordAppear(token: "a") {}
        #expect(contextA.lifecycle.hasAppeared(token: "a") == true)
        #expect(contextB.lifecycle.hasAppeared(token: "a") == false)
    }

    @Test("reset clears all services")
    func resetClears() {
        let context = TUIContext()
        context.lifecycle.recordAppear(token: "test") {}
        context.preferences.setValue("value", forKey: TestContextStringKey.self)
        context.keyEventDispatcher.addHandler { _ in true }

        context.reset()

        #expect(context.lifecycle.hasAppeared(token: "test") == false)
        #expect(context.preferences.current[TestContextStringKey.self] == "default")
    }

    @Test("Preferences storage is functional")
    func preferencesWork() {
        let context = TUIContext()
        context.preferences.setValue("hello", forKey: TestContextStringKey.self)
        #expect(context.preferences.current[TestContextStringKey.self] == "hello")
    }

    @Test("KeyEventDispatcher is functional")
    func dispatcherWorks() {
        let context = TUIContext()
        nonisolated(unsafe) var handled = false
        context.keyEventDispatcher.addHandler { _ in
            handled = true
            return true
        }
        context.keyEventDispatcher.dispatch(KeyEvent(key: .enter))
        #expect(handled == true)
    }

    @Test("State mutation invalidates only its owning runtime")
    func stateMutationInvalidatesOnlyOwner() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()
        let key = StateStorage.StateKey(
            identity: ViewIdentity(path: "owner"),
            propertyIndex: 0
        )
        let firstBox: StateBox<Int> = firstContext.stateStorage.storage(for: key, default: 0)
        let secondBox: StateBox<Int> = secondContext.stateStorage.storage(for: key, default: 0)

        firstContext.appState.didRender()
        secondContext.appState.didRender()
        firstBox.value = 1

        #expect(firstContext.appState.needsRender)
        #expect(secondContext.appState.needsRender == false)
        #expect(secondBox.value == 0)

        firstContext.applyPendingRenderInvalidations()

        #expect(firstContext.renderCache.stats.subtreeClears == 1)
        #expect(secondContext.renderCache.stats.subtreeClears == 0)
    }

    @Test("Observation invalidates only its rendering runtime")
    func observationInvalidatesOnlyRenderingRuntime() {
        let firstContext = TUIContext()
        let secondContext = TUIContext()
        let firstModel = RuntimeObservationModel()
        let secondModel = RuntimeObservationModel()

        _ = renderToBuffer(
            RuntimeObservationView(model: firstModel),
            context: RenderContext(
                availableWidth: 20,
                availableHeight: 1,
                tuiContext: firstContext
            )
        )
        _ = renderToBuffer(
            RuntimeObservationView(model: secondModel),
            context: RenderContext(
                availableWidth: 20,
                availableHeight: 1,
                tuiContext: secondContext
            )
        )

        firstContext.appState.didRender()
        secondContext.appState.didRender()
        firstModel.value = 1

        #expect(firstContext.appState.needsRender)
        #expect(secondContext.appState.needsRender == false)

        firstContext.applyPendingRenderInvalidations()

        #expect(firstContext.renderCache.stats.clears == 1)
        #expect(secondContext.renderCache.stats.clears == 0)
    }
}

/// Test preference key for TUIContext tests.
private struct TestContextStringKey: PreferenceKey {
    static let defaultValue: String = "default"
}

@Observable
private final class RuntimeObservationModel {
    var value = 0
}

private struct RuntimeObservationView: View {
    let model: RuntimeObservationModel

    var body: some View {
        Text("value:\(model.value)")
    }
}
