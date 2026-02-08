//  🖥️ TUIKit — Terminal UI Kit for Swift
//  EnvironmentTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

/// Custom environment key for testing.
private struct TestStringKey: EnvironmentKey {
    static let defaultValue: String = "default"
}

/// Another custom key for independence tests.
private struct TestIntKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    fileprivate var testString: String {
        get { self[TestStringKey.self] }
        set { self[TestStringKey.self] = newValue }
    }

    fileprivate var testInt: Int {
        get { self[TestIntKey.self] }
        set { self[TestIntKey.self] = newValue }
    }
}

// MARK: - EnvironmentValues Tests

@MainActor
@Suite("EnvironmentValues Tests")
struct EnvironmentValuesTests {

    @Test("Empty environment returns default values")
    func emptyDefaults() {
        let env = EnvironmentValues()
        #expect(env[TestStringKey.self] == "default")
        #expect(env[TestIntKey.self] == 0)
    }

    @Test("Set and get value via subscript")
    func setAndGet() {
        var env = EnvironmentValues()
        env[TestStringKey.self] = "custom"
        #expect(env[TestStringKey.self] == "custom")
    }

    @Test("Different keys are independent")
    func independentKeys() {
        var env = EnvironmentValues()
        env[TestStringKey.self] = "hello"
        env[TestIntKey.self] = 42
        #expect(env[TestStringKey.self] == "hello")
        #expect(env[TestIntKey.self] == 42)
    }

    @Test("setting() returns new copy with modified value")
    func settingCopy() {
        let original = EnvironmentValues()
        let modified = original.setting(\.testString, to: "changed")
        #expect(modified.testString == "changed")
        #expect(original.testString == "default")  // original unchanged
    }

    @Test("setting() preserves other values")
    func settingPreservesOthers() {
        var env = EnvironmentValues()
        env.testInt = 99
        let modified = env.setting(\.testString, to: "new")
        #expect(modified.testString == "new")
        #expect(modified.testInt == 99)  // preserved
    }
}

// MARK: - EnvironmentModifier Tests

@MainActor
@Suite("EnvironmentModifier Tests")
struct EnvironmentModifierTests {

    @Test("EnvironmentModifier propagates value to child")
    func propagatesToChild() {
        // Create a view that reads the environment and renders it
        let view = EnvironmentReaderView()
            .environment(\.testString, "injected")

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: EnvironmentValues()
        )

        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("injected"))
    }

    @Test("Environment value inherits through nested views")
    func inheritsThroughNesting() {
        // Wrapper -> Inner -> Reader
        let view = WrapperView {
            InnerView {
                EnvironmentReaderView()
            }
        }
        .environment(\.testString, "nested-value")

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: EnvironmentValues()
        )

        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("nested-value"))
    }

    @Test("Child can override parent environment value")
    func childOverridesParent() {
        let view = WrapperView {
            EnvironmentReaderView()
                .environment(\.testString, "child-value")
        }
        .environment(\.testString, "parent-value")

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: EnvironmentValues()
        )

        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()

        #expect(content.contains("child-value"))
        #expect(!content.contains("parent-value"))
    }
}

// MARK: - Test Helper Views

/// A view with real body that reads an environment value.
private struct EnvironmentReaderView: View, Renderable {
    var body: Never { fatalError() }

    func renderToBuffer(context: RenderContext) -> FrameBuffer {
        let value = context.environment.testString
        return FrameBuffer(lines: ["Value: \(value)"])
    }
}

/// A simple wrapper view with real body.
private struct WrapperView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

/// Another wrapper to test nesting.
private struct InnerView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

// MARK: - ForegroundStyle Propagation Tests

@MainActor
@Suite("ForegroundStyle Propagation Tests")
struct ForegroundStylePropagationTests {

    @Test("foregroundStyle on parent affects Text child")
    func parentStyleAffectsTextChild() {
        // VStack with foregroundStyle should affect Text inside
        let view = VStack {
            Text("Hello")
        }
        .foregroundStyle(.red)

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: EnvironmentValues()
        )

        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()

        // Check that ANSI red color code is present
        // Red foreground is ESC[31m
        #expect(content.contains("\u{1B}[31m"))
    }

    @Test("foregroundStyle propagates through multiple levels")
    func stylePropagatesThroughLevels() {
        let view = VStack {
            HStack {
                Text("Nested")
            }
        }
        .foregroundStyle(.green)

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: EnvironmentValues()
        )

        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()

        // Green foreground is ESC[32m
        #expect(content.contains("\u{1B}[32m"))
    }

    @Test("explicit Text foregroundStyle overrides parent")
    func explicitStyleOverridesParent() {
        let view = VStack {
            Text("Override").foregroundStyle(.blue)
        }
        .foregroundStyle(.red)

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: EnvironmentValues()
        )

        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()

        // Blue foreground is ESC[34m, should have blue, not red
        #expect(content.contains("\u{1B}[34m"))
        #expect(!content.contains("\u{1B}[31m"))
    }

    @Test("without foregroundStyle, Text uses default")
    func withoutStyleUsesDefault() {
        let view = Text("Plain")

        let context = RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            environment: EnvironmentValues()
        )

        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()

        // Should just be "Plain" without color codes (or with reset)
        #expect(content.contains("Plain"))
    }
}
