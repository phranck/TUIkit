//
//  StatePropertyTests.swift
//  TUIkit
//
//  Tests for State property wrapper: initial value, mutation, render trigger, projected binding.
//

import Testing

@testable import TUIkit

@Suite("State Property Wrapper Tests")
struct StatePropertyWrapperTests {

    @Test("State can be mutated")
    func stateMutation() {
        let state = State(wrappedValue: 0)
        state.wrappedValue = 10
        #expect(state.wrappedValue == 10)
    }

    @Test("State mutation triggers render via RenderNotifier")
    func stateTriggerRender() {
        // StateBox.didSet calls RenderNotifier.current.setNeedsRender().
        // We swap in a fresh AppState, mutate, and check immediately.
        // This is a single-expression sequence with no yield points,
        // so no parallel test can interfere between set and check.
        let appState = AppState()
        let previous = RenderNotifier.current
        RenderNotifier.current = appState
        let state = State(wrappedValue: "initial")
        state.wrappedValue = "changed"
        let triggered = appState.needsRender
        RenderNotifier.current = previous
        #expect(triggered == true)
    }

    @Test("Binding from State updates original")
    func stateBindingUpdates() {
        let state = State(wrappedValue: 0)
        let binding = state.projectedValue
        binding.wrappedValue = 77
        #expect(state.wrappedValue == 77)
    }

}
