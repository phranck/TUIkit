//  TUIKit - Terminal UI Kit for Swift
//  SliderHandlerTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("SliderHandler Tests")
struct SliderHandlerTests {

    // MARK: - Initialization

    @Test("Handler initializes with correct values")
    func initializesCorrectly() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        #expect(handler.focusID == "test")
        #expect(handler.value.wrappedValue == 0.5)
        #expect(handler.bounds == 0...1)
        #expect(handler.step == 0.1)
        #expect(handler.canBeFocused == true)
    }

    // MARK: - Increment/Decrement

    @Test("Right arrow increments value by step")
    func rightArrowIncrements() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .right))

        #expect(handled == true)
        #expect(value == 0.6)
    }

    @Test("Left arrow decrements value by step")
    func leftArrowDecrements() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .left))

        #expect(handled == true)
        #expect(value == 0.4)
    }

    @Test("Plus key increments value")
    func plusKeyIncrements() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("+")))

        #expect(handled == true)
        #expect(value == 0.6)
    }

    @Test("Minus key decrements value")
    func minusKeyDecrements() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("-")))

        #expect(handled == true)
        #expect(value == 0.4)
    }

    // MARK: - Bounds Clamping

    @Test("Increment clamps at upper bound")
    func incrementClampsAtUpperBound() {
        var value = 0.95
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .right))

        #expect(value == 1.0)
    }

    @Test("Decrement clamps at lower bound")
    func decrementClampsAtLowerBound() {
        var value = 0.05
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .left))

        #expect(value == 0.0)
    }

    // MARK: - Home/End Keys

    @Test("Home key jumps to minimum")
    func homeKeyJumpsToMinimum() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .home))

        #expect(handled == true)
        #expect(value == 0.0)
    }

    @Test("End key jumps to maximum")
    func endKeyJumpsToMaximum() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .end))

        #expect(handled == true)
        #expect(value == 1.0)
    }

    // MARK: - Custom Range

    @Test("Works with custom range 0 to 100")
    func worksWithCustomRange() {
        var value = 50.0
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...100,
            step: 5
        )

        _ = handler.handleKeyEvent(KeyEvent(key: .right))
        #expect(value == 55.0)

        _ = handler.handleKeyEvent(KeyEvent(key: .left))
        #expect(value == 50.0)

        _ = handler.handleKeyEvent(KeyEvent(key: .end))
        #expect(value == 100.0)

        _ = handler.handleKeyEvent(KeyEvent(key: .home))
        #expect(value == 0.0)
    }

    // MARK: - Unhandled Keys

    @Test("Unhandled key returns false")
    func unhandledKeyReturnsFalse() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .character("x")))

        #expect(handled == false)
        #expect(value == 0.5)
    }

    @Test("Enter key is not handled")
    func enterKeyNotHandled() {
        var value = 0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        let handled = handler.handleKeyEvent(KeyEvent(key: .enter))

        #expect(handled == false)
    }

    // MARK: - Clamp Value

    @Test("clampValue fixes out-of-range value")
    func clampValueFixesOutOfRange() {
        var value = 1.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        handler.clampValue()

        #expect(value == 1.0)
    }

    @Test("clampValue fixes negative value")
    func clampValueFixesNegative() {
        var value = -0.5
        let binding = Binding(get: { value }, set: { value = $0 })
        let handler = SliderHandler(
            focusID: "test",
            value: binding,
            bounds: 0...1,
            step: 0.1
        )

        handler.clampValue()

        #expect(value == 0.0)
    }
}
