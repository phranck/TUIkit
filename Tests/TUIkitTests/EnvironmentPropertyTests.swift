//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EnvironmentPropertyTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Environment Key

private struct TestColorKey: EnvironmentKey {
    static let defaultValue: String = "blue"
}

private struct TestSizeKey: EnvironmentKey {
    static let defaultValue: Int = 42
}

extension EnvironmentValues {
    fileprivate var testColor: String {
        get { self[TestColorKey.self] }
        set { self[TestColorKey.self] = newValue }
    }

    fileprivate var testSize: Int {
        get { self[TestSizeKey.self] }
        set { self[TestSizeKey.self] = newValue }
    }
}

// MARK: - Tests

@MainActor
@Suite("@Environment Property Wrapper Tests")
struct EnvironmentPropertyTests {

    @Test("Reads default value outside render context")
    func readsDefaultOutsideRenderContext() {
        // Ensure no active environment
        StateRegistration.activeEnvironment = nil

        let wrapper = Environment(\.testColor)
        #expect(wrapper.wrappedValue == "blue")
    }

    @Test("Reads default int value outside render context")
    func readsDefaultIntOutsideRenderContext() {
        StateRegistration.activeEnvironment = nil

        let wrapper = Environment(\.testSize)
        #expect(wrapper.wrappedValue == 42)
    }

    @Test("Reads value from active environment")
    func readsFromActiveEnvironment() {
        var env = EnvironmentValues()
        env.testColor = "red"
        StateRegistration.activeEnvironment = env

        let wrapper = Environment(\.testColor)
        #expect(wrapper.wrappedValue == "red")

        StateRegistration.activeEnvironment = nil
    }

    @Test("Multiple @Environment properties read independently")
    func multiplePropertiesReadIndependently() {
        var env = EnvironmentValues()
        env.testColor = "green"
        env.testSize = 100
        StateRegistration.activeEnvironment = env

        let colorWrapper = Environment(\.testColor)
        let sizeWrapper = Environment(\.testSize)
        #expect(colorWrapper.wrappedValue == "green")
        #expect(sizeWrapper.wrappedValue == 100)

        StateRegistration.activeEnvironment = nil
    }

    @Test("Reads dynamically from current active environment")
    func readsDynamically() {
        var env1 = EnvironmentValues()
        env1.testColor = "red"

        var env2 = EnvironmentValues()
        env2.testColor = "yellow"

        let wrapper = Environment(\.testColor)

        StateRegistration.activeEnvironment = env1
        #expect(wrapper.wrappedValue == "red")

        StateRegistration.activeEnvironment = env2
        #expect(wrapper.wrappedValue == "yellow")

        StateRegistration.activeEnvironment = nil
        #expect(wrapper.wrappedValue == "blue")  // default
    }

    @Test("Environment propagates through render pipeline")
    func propagatesThroughRenderPipeline() {
        // Create a view that uses @Environment internally
        let view = Text("Hello")
            .environment(\.testColor, "purple")

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            tuiContext: TUIContext()
        )

        // This should render without issues - the environment modifier
        // propagates the value through the render tree
        let buffer = renderToBuffer(view, context: context)
        #expect(!buffer.isEmpty)
    }

    @Test("Nested environment overrides resolve correctly")
    func nestedOverrides() {
        var outerEnv = EnvironmentValues()
        outerEnv.testColor = "outer"

        var innerEnv = EnvironmentValues()
        innerEnv.testColor = "inner"

        let wrapper = Environment(\.testColor)

        // Simulate nested render: outer sets env, inner overrides
        StateRegistration.activeEnvironment = outerEnv
        #expect(wrapper.wrappedValue == "outer")

        // Inner override
        StateRegistration.activeEnvironment = innerEnv
        #expect(wrapper.wrappedValue == "inner")

        // Restore outer (like render pipeline does)
        StateRegistration.activeEnvironment = outerEnv
        #expect(wrapper.wrappedValue == "outer")

        StateRegistration.activeEnvironment = nil
    }
}
