//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EnvironmentPropertyTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing
import TUIkitView

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
        let wrapper = Environment(\.testColor)
        #expect(wrapper.wrappedValue == "blue")
    }

    @Test("Reads default int value outside render context")
    func readsDefaultIntOutsideRenderContext() {
        let wrapper = Environment(\.testSize)
        #expect(wrapper.wrappedValue == 42)
    }

    @Test("Reads value from the scoped runtime environment")
    func readsFromRuntimeEnvironment() {
        var env = EnvironmentValues()
        env.testColor = "red"

        let wrapper = Environment(\.testColor)
        StateRegistration.$runtimeEnvironment.withValue(env) {
            #expect(wrapper.wrappedValue == "red")
        }
    }

    @Test("Multiple @Environment properties read independently")
    func multiplePropertiesReadIndependently() {
        var env = EnvironmentValues()
        env.testColor = "green"
        env.testSize = 100

        let colorWrapper = Environment(\.testColor)
        let sizeWrapper = Environment(\.testSize)
        StateRegistration.$runtimeEnvironment.withValue(env) {
            #expect(colorWrapper.wrappedValue == "green")
            #expect(sizeWrapper.wrappedValue == 100)
        }
    }

    @Test("Reads dynamically from the current scoped environment")
    func readsDynamically() {
        var env1 = EnvironmentValues()
        env1.testColor = "red"

        var env2 = EnvironmentValues()
        env2.testColor = "yellow"

        let wrapper = Environment(\.testColor)

        StateRegistration.$runtimeEnvironment.withValue(env1) {
            #expect(wrapper.wrappedValue == "red")
        }
        StateRegistration.$runtimeEnvironment.withValue(env2) {
            #expect(wrapper.wrappedValue == "yellow")
        }
        #expect(wrapper.wrappedValue == "blue")  // default outside any scope
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

    @Test("Nested environment scopes resolve correctly")
    func nestedOverrides() {
        var outerEnv = EnvironmentValues()
        outerEnv.testColor = "outer"

        var innerEnv = EnvironmentValues()
        innerEnv.testColor = "inner"

        let wrapper = Environment(\.testColor)

        StateRegistration.$runtimeEnvironment.withValue(outerEnv) {
            #expect(wrapper.wrappedValue == "outer")

            StateRegistration.$runtimeEnvironment.withValue(innerEnv) {
                #expect(wrapper.wrappedValue == "inner")
            }

            // The outer scope is restored automatically.
            #expect(wrapper.wrappedValue == "outer")
        }
    }
}
