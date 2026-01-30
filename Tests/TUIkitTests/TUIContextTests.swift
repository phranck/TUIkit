//
//  TUIContextTests.swift
//  TUIkit
//
//  Tests for TUIContext: initialization, service access, and reset.
//

import Testing

@testable import TUIkit

@Suite("TUIContext Tests")
struct TUIContextTests {

    @Test("Default init creates fresh services")
    func defaultInit() {
        let context = TUIContext()
        // All services should be accessible
        #expect(context.lifecycle is LifecycleManager)
        #expect(context.keyEventDispatcher is KeyEventDispatcher)
        #expect(context.preferences is PreferenceStorage)
    }

    @Test("Services are independent per context")
    func independentServices() {
        let contextA = TUIContext()
        let contextB = TUIContext()
        // Each context has its own lifecycle manager
        contextA.lifecycle.recordAppear(token: "a") {}
        #expect(contextA.lifecycle.hasAppeared(token: "a") == true)
        #expect(contextB.lifecycle.hasAppeared(token: "a") == false)
    }

    @Test("reset clears all services")
    func resetClears() {
        let context = TUIContext()
        context.lifecycle.recordAppear(token: "test") {}
        context.preferences.setValue("value", forKey: TestContextStringKey.self)
        context.keyEventDispatcher.addHandler { _ in true }

        context.reset()

        #expect(context.lifecycle.hasAppeared(token: "test") == false)
        #expect(context.preferences.current[TestContextStringKey.self] == "default")
    }

    @Test("Preferences storage is functional")
    func preferencesWork() {
        let context = TUIContext()
        context.preferences.setValue("hello", forKey: TestContextStringKey.self)
        #expect(context.preferences.current[TestContextStringKey.self] == "hello")
    }

    @Test("KeyEventDispatcher is functional")
    func dispatcherWorks() {
        let context = TUIContext()
        nonisolated(unsafe) var handled = false
        context.keyEventDispatcher.addHandler { _ in
            handled = true
            return true
        }
        context.keyEventDispatcher.dispatch(KeyEvent(key: .enter))
        #expect(handled == true)
    }
}

/// Test preference key for TUIContext tests.
private struct TestContextStringKey: PreferenceKey {
    static let defaultValue: String = "default"
}
