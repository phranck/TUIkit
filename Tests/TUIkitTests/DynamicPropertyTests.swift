//  🖥️ TUIKit — Terminal UI Kit for Swift
//  DynamicPropertyTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Foundation
import Testing

@testable import TUIkit

@MainActor
@Suite("DynamicProperty Contract")
struct DynamicPropertyTests {

    /// Creates an isolated render context.
    private func testContext(
        tuiContext: TUIContext,
        identity: String = "Root"
    ) -> RenderContext {
        RenderContext(
            availableWidth: 40,
            availableHeight: 10,
            tuiContext: tuiContext,
            identity: ViewIdentity(path: identity)
        )
    }

    // MARK: - Conformances

    @Test("The built-in property wrappers are DynamicProperty types")
    func builtInWrappersAreDynamicProperties() {
        #expect(State<Int>.self is any DynamicProperty.Type)
        #expect(Binding<Int>.self is any DynamicProperty.Type)
        #expect(Environment<Palette>.self is any DynamicProperty.Type)
        #expect(AppStorage<Int>.self is any DynamicProperty.Type)
    }

    // MARK: - Nested Hydration

    /// A user-defined dynamic property composing framework state.
    struct Counter: DynamicProperty {
        @State var count = 0
    }

    struct CounterView: View {
        let counter = Counter()

        var body: some View {
            Text("count:\(counter.count)")
        }
    }

    @Test("State nested in a custom DynamicProperty persists across re-renders")
    func nestedStatePersists() {
        let tuiContext = TUIContext()
        let context = testContext(tuiContext: tuiContext, identity: "CounterView")

        let first = CounterView()
        _ = StateRegistration.withHydration(of: first, context: context) {
            first.counter.count += 1
            return first.body
        }

        let second = CounterView()
        let body = StateRegistration.withHydration(of: second, context: context) {
            second.body
        }
        let buffer = renderToBuffer(body, context: context)

        #expect(buffer.lines.first?.stripped == "count:1")
    }

    // MARK: - Update Cycle

    /// Records every update() invocation.
    final class UpdateRecorder {
        var updates = 0
    }

    /// A dynamic property observing its own update cycle.
    struct Updating: DynamicProperty {
        let recorder: UpdateRecorder

        func update() {
            recorder.updates += 1
        }
    }

    struct UpdatingView: View {
        let property: Updating

        var body: some View {
            Text("updated")
        }
    }

    @Test("update() runs once per hydration before body evaluation")
    func updateRunsOncePerHydration() {
        let tuiContext = TUIContext()
        let context = testContext(tuiContext: tuiContext, identity: "UpdatingView")
        let recorder = UpdateRecorder()
        let view = UpdatingView(property: Updating(recorder: recorder))

        _ = StateRegistration.withHydration(of: view, context: context) {
            view.body
        }

        #expect(recorder.updates == 1)

        _ = StateRegistration.withHydration(of: view, context: context) {
            view.body
        }

        #expect(recorder.updates == 2)
    }
}
