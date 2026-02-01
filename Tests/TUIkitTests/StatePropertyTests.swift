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

    @Test("State mutation triggers render")
    func stateTriggerRender() {
        AppState.active.didRender()
        let state = State(wrappedValue: "initial")
        state.wrappedValue = "changed"
        #expect(AppState.active.needsRender == true)
        AppState.active.didRender()
    }

    @Test("Binding from State updates original")
    func stateBindingUpdates() {
        let state = State(wrappedValue: 0)
        let binding = state.projectedValue
        binding.wrappedValue = 77
        #expect(state.wrappedValue == 77)
    }

}
