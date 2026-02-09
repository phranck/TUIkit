//  TUIKit - Terminal UI Kit for Swift
//  StepperTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

@MainActor
@Suite("Stepper Tests")
struct StepperTests {

    // MARK: - Basic Rendering

    @Test("Stepper renders as single line")
    func rendersSingleLine() {
        var value = 5
        let view = Stepper("Count", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
    }

    @Test("Stepper contains left arrow")
    func containsLeftArrow() {
        var value = 5
        let view = Stepper("Count", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("◀"))
    }

    @Test("Stepper contains right arrow")
    func containsRightArrow() {
        var value = 5
        let view = Stepper("Count", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("▶"))
    }

    @Test("Stepper shows current value")
    func showsCurrentValue() {
        var value = 42
        let view = Stepper("Count", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("42"))
    }

    // MARK: - Different Values

    @Test("Stepper shows zero value")
    func showsZeroValue() {
        var value = 0
        let view = Stepper("Count", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains(" 0 "))
    }

    @Test("Stepper shows negative value")
    func showsNegativeValue() {
        var value = -5
        let view = Stepper("Count", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("-5"))
    }

    @Test("Stepper shows large value")
    func showsLargeValue() {
        var value = 999
        let view = Stepper("Count", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("999"))
    }

    // MARK: - Initializers

    @Test("Title initializer works")
    func titleInitializerWorks() {
        var value = 5
        let view = Stepper("Quantity", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].contains("5"))
    }

    @Test("Range initializer works")
    func rangeInitializerWorks() {
        var value = 5
        let view = Stepper("Rating", value: Binding(get: { value }, set: { value = $0 }), in: 1...10)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].contains("5"))
    }

    @Test("ViewBuilder label initializer works")
    func viewBuilderLabelWorks() {
        var value = 5
        let view = Stepper(value: Binding(get: { value }, set: { value = $0 })) {
            Text("Custom Label")
        }
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
    }

    @Test("Callback initializer works")
    func callbackInitializerWorks() {
        var incrementCount = 0
        var decrementCount = 0
        let view = Stepper(
            "Counter",
            onIncrement: { incrementCount += 1 },
            onDecrement: { decrementCount += 1 }
        )
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
    }

    // MARK: - Custom Step

    @Test("Custom step size initializer works")
    func customStepWorks() {
        var value = 50
        let view = Stepper("Volume", value: Binding(get: { value }, set: { value = $0 }), step: 10)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].contains("50"))
    }
}
