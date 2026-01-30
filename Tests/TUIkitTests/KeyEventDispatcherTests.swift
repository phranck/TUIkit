//
//  KeyEventDispatcherTests.swift
//  TUIkit
//
//  Tests for KeyEventDispatcher: handler registration, dispatch order, and cleanup.
//

import Testing

@testable import TUIkit

@Suite("KeyEventDispatcher Tests")
struct KeyEventDispatcherTests {

    @Test("Dispatcher can be created")
    func creation() {
        let dispatcher = KeyEventDispatcher()
        let result = dispatcher.dispatch(KeyEvent(key: .enter))
        #expect(result == false)
    }

    @Test("Dispatcher calls added handler")
    func handlerCalled() {
        let dispatcher = KeyEventDispatcher()
        nonisolated(unsafe) var handledKey: Key?
        dispatcher.addHandler { event in
            handledKey = event.key
            return true
        }
        let consumed = dispatcher.dispatch(KeyEvent(key: .tab))
        #expect(consumed == true)
        #expect(handledKey == .tab)
    }

    @Test("Dispatcher processes handlers in reverse order")
    func reverseOrder() {
        let dispatcher = KeyEventDispatcher()
        nonisolated(unsafe) var callOrder: [String] = []

        dispatcher.addHandler { _ in
            callOrder.append("first")
            return false
        }
        dispatcher.addHandler { _ in
            callOrder.append("second")
            return true // consume
        }

        dispatcher.dispatch(KeyEvent(key: .enter))
        // Second (last added) should be called first, and it consumes
        #expect(callOrder == ["second"])
    }

    @Test("Dispatcher falls through when handler returns false")
    func fallThrough() {
        let dispatcher = KeyEventDispatcher()
        nonisolated(unsafe) var callOrder: [String] = []

        dispatcher.addHandler { _ in
            callOrder.append("first")
            return true // consume
        }
        dispatcher.addHandler { _ in
            callOrder.append("second")
            return false // pass through
        }

        dispatcher.dispatch(KeyEvent(key: .enter))
        // Second doesn't consume, so first also gets called
        #expect(callOrder == ["second", "first"])
    }

    @Test("Dispatcher clearHandlers removes all handlers")
    func clearHandlers() {
        let dispatcher = KeyEventDispatcher()
        dispatcher.addHandler { _ in true }
        dispatcher.addHandler { _ in true }

        dispatcher.clearHandlers()
        let consumed = dispatcher.dispatch(KeyEvent(key: .enter))
        #expect(consumed == false)
    }

    @Test("Dispatcher returns false when no handler consumes")
    func noConsumer() {
        let dispatcher = KeyEventDispatcher()
        dispatcher.addHandler { _ in false }
        dispatcher.addHandler { _ in false }

        let consumed = dispatcher.dispatch(KeyEvent(key: .enter))
        #expect(consumed == false)
    }
}
