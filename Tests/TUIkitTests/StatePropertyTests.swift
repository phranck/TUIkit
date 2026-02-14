//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatePropertyTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

#if os(Linux)
private let isLinux = true
#else
private let isLinux = false
#endif

@MainActor
@Suite(
    "State Property Wrapper Tests",
    .disabled(if: isLinux, "Skipped on Linux due to Swift runtime race condition in StateStorage")
)
struct StatePropertyWrapperTests {

    @Test("State can be mutated")
    func stateMutation() {
        let state = State(wrappedValue: 0)
        state.wrappedValue = 10
        #expect(state.wrappedValue == 10)
    }

    @Test("State mutation triggers render via AppState.shared")
    func stateTriggerRender() {
        // StateBox.didSet calls AppState.shared.setNeedsRender().
        // We mutate and check that the shared instance is marked as needing render.
        let initialNeedsRender = AppState.shared.needsRender
        let state = State(wrappedValue: "initial")
        state.wrappedValue = "changed"
        let triggered = AppState.shared.needsRender
        // Reset for other tests
        AppState.shared.didRender()
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
