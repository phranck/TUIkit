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

    @Test("State projectedValue returns a Binding")
    func stateProjectedValue() {
        let state = State(wrappedValue: 42)
        let binding = state.projectedValue
        #expect(binding.wrappedValue == 42)
    }

    @Test("Binding from State updates original")
    func stateBindingUpdates() {
        let state = State(wrappedValue: 0)
        let binding = state.projectedValue
        binding.wrappedValue = 77
        #expect(state.wrappedValue == 77)
    }

    @Test("State with optional type")
    func stateOptional() {
        let state = State<String?>(wrappedValue: nil)
        #expect(state.wrappedValue == nil)
        state.wrappedValue = "now set"
        #expect(state.wrappedValue == "now set")
        AppState.active.didRender()
    }
}
