//  TUIKit - Terminal UI Kit for Swift
//  StepperHandlerTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("StepperHandler Tests")
struct StepperHandlerTests {

    // MARK: - Initialization

    @Test("Handler initializes with correct values")
    func initializesCorrectly() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        #expect(handler.focusID == "test")
        #expect(handler.value.wrappedValue == 5)
        #expect(handler.bounds == 0...10)
        #expect(handler.step == 1)
        #expect(handler.canBeFocused == true)
    }

    // MARK: - Increment/Decrement

    @Test("Right arrow increments value by step")
    func rightArrowIncrements() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .right))

        #expect(handled == true)
        #expect(value == 6)
    }

    @Test("Left arrow decrements value by step")
    func leftArrowDecrements() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .left))

        #expect(handled == true)
        #expect(value == 4)
    }

    @Test("Plus key increments value")
    func plusKeyIncrements() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("+")))

        #expect(handled == true)
        #expect(value == 6)
    }

    @Test("Minus key decrements value")
    func minusKeyDecrements() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("-")))

        #expect(handled == true)
        #expect(value == 4)
    }

    // MARK: - Bounds Clamping

    @Test("Increment clamps at upper bound")
    func incrementClampsAtUpperBound() {
        var value = 9
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 2
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .right))

        #expect(value == 10)
    }

    @Test("Decrement clamps at lower bound")
    func decrementClampsAtLowerBound() {
        var value = 1
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 2
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .left))

        #expect(value == 0)
    }

    // MARK: - Home/End Keys

    @Test("Home key jumps to minimum")
    func homeKeyJumpsToMinimum() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .home))

        #expect(handled == true)
        #expect(value == 0)
    }

    @Test("End key jumps to maximum")
    func endKeyJumpsToMaximum() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .end))

        #expect(handled == true)
        #expect(value == 10)
    }

    @Test("Home key does nothing without bounds")
    func homeKeyNoBounds() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: nil,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .home))

        #expect(handled == false)
        #expect(value == 5)
    }

    @Test("End key does nothing without bounds")
    func endKeyNoBounds() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: nil,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .end))

        #expect(handled == false)
        #expect(value == 5)
    }

    // MARK: - Custom Step Size

    @Test("Works with custom step size")
    func worksWithCustomStep() {
        var value = 50
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...100,
            step: 10
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .right))
        #expect(value == 60)

        _ = handler.handleKeyEvent(KeyEvent(key: .left))
        #expect(value == 50)
    }

    // MARK: - No Bounds

    @Test("Works without bounds")
    func worksWithoutBounds() {
        var value = 0
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: nil,
            step: 1
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .right))
        #expect(value == 1)

        _ = handler.handleKeyEvent(KeyEvent(key: .left))
        _ = handler.handleKeyEvent(KeyEvent(key: .left))
        #expect(value == -1)
    }

    // MARK: - Unhandled Keys

    @Test("Unhandled key returns false")
    func unhandledKeyReturnsFalse() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("x")))

        #expect(handled == false)
        #expect(value == 5)
    }

    @Test("Enter key is not handled")
    func enterKeyNotHandled() {
        var value = 5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .enter))

        #expect(handled == false)
    }

    // MARK: - Custom Callbacks

    @Test("Custom onIncrement callback is called")
    func customOnIncrementCalled() {
        var incrementCalled = false
        let handler = StepperHandler<Int>(
            focusID: "test",
            onIncrement: { incrementCalled = true },
            onDecrement: nil
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .right))

        #expect(incrementCalled == true)
    }

    @Test("Custom onDecrement callback is called")
    func customOnDecrementCalled() {
        var decrementCalled = false
        let handler = StepperHandler<Int>(
            focusID: "test",
            onIncrement: nil,
            onDecrement: { decrementCalled = true }
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .left))

        #expect(decrementCalled == true)
    }

    // MARK: - Clamp Value

    @Test("clampValue fixes out-of-range value")
    func clampValueFixesOutOfRange() {
        var value = 15
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        handler.clampValue()

        #expect(value == 10)
    }

    @Test("clampValue fixes negative value")
    func clampValueFixesNegative() {
        var value = -5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = StepperHandler(
            focusID: "test",
            value: binding,
            bounds: 0...10,
            step: 1
        )

        handler.clampValue()

        #expect(value == 0)
    }
}
