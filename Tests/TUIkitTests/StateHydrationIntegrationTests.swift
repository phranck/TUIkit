//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StateHydrationIntegrationTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("State Hydration Integration Tests", .serialized)
struct StateHydrationIntegrationTests {

    @Test("State survives reconstruction through renderToBuffer")
    func stateSurvivesRenderToBuffer() {
        let tuiContext = TUIContext()
        var env = EnvironmentValues()
        env.stateStorage = tuiContext.stateStorage
        env.lifecycle = tuiContext.lifecycle
        env.keyEventDispatcher = tuiContext.keyEventDispatcher
        env.renderCache = tuiContext.renderCache
        env.preferenceStorage = tuiContext.preferences
        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: env,
            identity: ViewIdentity(path: "")
        )

        // First render: creates state with default 0, body sets it to 42
        let buffer1 = renderToBuffer(CounterView(), context: context)
        #expect(buffer1.lines.first?.contains("42") == true)

        // Second render: state should still be 42 even though CounterView is reconstructed
        let buffer2 = renderToBuffer(CounterView(), context: context)
        #expect(buffer2.lines.first?.contains("42") == true)
    }

    @Test("Nested views get independent state identities")
    func nestedViewsIndependentState() {
        let tuiContext = TUIContext()
        var env = EnvironmentValues()
        env.stateStorage = tuiContext.stateStorage
        env.lifecycle = tuiContext.lifecycle
        env.keyEventDispatcher = tuiContext.keyEventDispatcher
        env.renderCache = tuiContext.renderCache
        env.preferenceStorage = tuiContext.preferences
        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: env,
            identity: ViewIdentity(path: "")
        )

        // Render a parent with two child views that each have @State
        let buffer = renderToBuffer(ParentWithTwoCounters(), context: context)

        // Both counters should render independently
        let lines = buffer.lines.joined()
        #expect(lines.contains("A:10"))
        #expect(lines.contains("B:20"))
    }
}

// MARK: - Test Helpers

/// A view that initializes @State to 0 then immediately sets it to 42.
/// On reconstruction, the state should still be 42 (not reset to 0).
private struct CounterView: View {
    @State var countValue = 0

    var body: some View {
        if countValue == 0 {
            // First render: set to 42
            countValue = 42
        }
        return Text("Count:\(countValue)")
    }
}

/// A parent view containing two child views with independent state.
private struct ParentWithTwoCounters: View {
    var body: some View {
        VStack {
            CounterA()
            CounterB()
        }
    }
}

private struct CounterA: View {
    @State var value = 0

    var body: some View {
        if value == 0 { value = 10 }
        return Text("A:\(value)")
    }
}

private struct CounterB: View {
    @State var value = 0

    var body: some View {
        if value == 0 { value = 20 }
        return Text("B:\(value)")
    }
}
