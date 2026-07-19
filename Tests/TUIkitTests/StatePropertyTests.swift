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

    @Test("State box mutation triggers its injected runtime")
    func stateTriggerRender() {
        let appState = AppState()
        let box = StateBox(
            "initial",
            identity: ViewIdentity(path: "state"),
            invalidationSink: appState
        )

        box.value = "changed"

        #expect(appState.needsRender)
    }

    @Test("Binding from State updates original")
    func stateBindingUpdates() {
        let state = State(wrappedValue: 0)
        let binding = state.projectedValue
        binding.wrappedValue = 77
        #expect(state.wrappedValue == 77)
    }
}
