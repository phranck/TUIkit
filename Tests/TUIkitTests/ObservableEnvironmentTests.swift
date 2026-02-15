//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ObservableEnvironmentTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Observation
import Testing

@testable import TUIkit

// MARK: - Test Observable Classes

@Observable
private class CounterModel {
    var count = 0
    init() {}
}

@Observable
private class NameModel {
    var name = "default"
    init() {}
}

// MARK: - Tests

@MainActor
@Suite("Observable Environment Tests")
struct ObservableEnvironmentTests {

    @Test("Type-based subscript stores and retrieves object")
    func typeBasedSubscript() {
        var env = EnvironmentValues()
        let model = CounterModel()
        model.count = 42

        env[observable: CounterModel.self] = model

        let retrieved = env[observable: CounterModel.self]
        #expect(retrieved != nil)
        #expect(retrieved?.count == 42)
        #expect(retrieved === model)
    }

    @Test("Type-based subscript returns nil when not set")
    func typeBasedSubscriptDefault() {
        let env = EnvironmentValues()
        let retrieved = env[observable: CounterModel.self]
        #expect(retrieved == nil)
    }

    @Test("@Environment reads observable from active environment")
    func environmentReadsObservable() {
        var env = EnvironmentValues()
        let model = CounterModel()
        model.count = 99
        env[observable: CounterModel.self] = model

        StateRegistration.activeEnvironment = env

        let wrapper = Environment(CounterModel.self)
        #expect(wrapper.wrappedValue.count == 99)
        #expect(wrapper.wrappedValue === model)

        StateRegistration.activeEnvironment = nil
    }

    @Test("Inner .environment overrides outer for same type")
    func innerOverridesOuter() {
        let outerModel = CounterModel()
        outerModel.count = 1

        let innerModel = CounterModel()
        innerModel.count = 2

        var outerEnv = EnvironmentValues()
        outerEnv[observable: CounterModel.self] = outerModel

        var innerEnv = EnvironmentValues()
        innerEnv[observable: CounterModel.self] = innerModel

        let wrapper = Environment(CounterModel.self)

        StateRegistration.activeEnvironment = outerEnv
        #expect(wrapper.wrappedValue.count == 1)

        StateRegistration.activeEnvironment = innerEnv
        #expect(wrapper.wrappedValue.count == 2)

        StateRegistration.activeEnvironment = nil
    }

    @Test("Different types coexist in environment")
    func differentTypesCoexist() {
        var env = EnvironmentValues()
        let counter = CounterModel()
        counter.count = 10
        let name = NameModel()
        name.name = "hello"

        env[observable: CounterModel.self] = counter
        env[observable: NameModel.self] = name

        StateRegistration.activeEnvironment = env

        let counterWrapper = Environment(CounterModel.self)
        let nameWrapper = Environment(NameModel.self)

        #expect(counterWrapper.wrappedValue.count == 10)
        #expect(nameWrapper.wrappedValue.name == "hello")

        StateRegistration.activeEnvironment = nil
    }

    @Test("Observable propagates through render pipeline")
    func propagatesThroughRendering() {
        let model = CounterModel()
        model.count = 7

        let view = Text("Hello")
            .environment(model)

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            tuiContext: TUIContext()
        )

        let buffer = renderToBuffer(view, context: context)
        #expect(!buffer.isEmpty)
    }

    @Test("Object stored by reference, not copy")
    func storedByReference() {
        var env = EnvironmentValues()
        let model = CounterModel()
        env[observable: CounterModel.self] = model

        model.count = 100

        let retrieved = env[observable: CounterModel.self]
        #expect(retrieved?.count == 100)
    }
}
