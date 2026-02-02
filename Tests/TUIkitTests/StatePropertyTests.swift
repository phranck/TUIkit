//
//  StatePropertyTests.swift
//  TUIkit
//
//  Tests for State property wrapper: initial value, mutation, render trigger, projected binding.
//

import Testing

@testable import TUIkit

@Suite("State Property Wrapper Tests", .serialized)
struct StatePropertyWrapperTests {

    /// Creates a fresh AppState instance to isolate tests from shared global state.
    private func isolatedAppState() -> AppState {
        let fresh = AppState()
        RenderNotifier.current = fresh
        return fresh
    }

    @Test("State can be mutated")
    func stateMutation() {
        let state = State(wrappedValue: 0)
        state.wrappedValue = 10
        #expect(state.wrappedValue == 10)
    }

    @Test("State mutation triggers render")
    func stateTriggerRender() {
        let appState = isolatedAppState()
        let state = State(wrappedValue: "initial")
        state.wrappedValue = "changed"
        #expect(appState.needsRender == true)
    }

    @Test("Binding from State updates original")
    func stateBindingUpdates() {
        let state = State(wrappedValue: 0)
        let binding = state.projectedValue
        binding.wrappedValue = 77
        #expect(state.wrappedValue == 77)
    }

}
