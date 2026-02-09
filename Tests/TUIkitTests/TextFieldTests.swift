//  TUIKit - Terminal UI Kit for Swift
//  TextFieldTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - TextField Tests

@MainActor
@Suite("TextField Tests")
struct TextFieldTests {

    private func testContext(width: Int = 80, height: Int = 24) -> RenderContext {
        RenderContext(availableWidth: width, availableHeight: height)
    }

    // MARK: - Initialization

    @Test("TextField initializes with title and text binding")
    func initializationBasic() {
        var text = "Hello"
        let binding = Binding(get: { text }, set: { text = $0 })

        let textField = TextField("Username", text: binding)

        // Should compile and render without error
        let context = testContext()
        let buffer = renderToBuffer(textField, context: context)
        #expect(buffer.height == 1)
    }

    @Test("TextField initializes with prompt")
    func initializationWithPrompt() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        let textField = TextField("Email", text: binding, prompt: Text("you@example.com"))

        #expect(textField.prompt != nil)
    }

    // MARK: - Rendering

    @Test("TextField renders with brackets only when focused")
    func renderWithBrackets() {
        var text = "test"
        let binding = Binding(get: { text }, set: { text = $0 })
        let textField = TextField("Input", text: binding)
        let context = testContext()

        let buffer = renderToBuffer(textField, context: context)

        #expect(buffer.lines.count == 1)
        let line = buffer.lines[0].stripped

        // Unfocused: no brackets
        #expect(!line.contains("["))
        #expect(!line.contains("]"))
        #expect(line.contains("test"))
    }

    @Test("TextField renders text content")
    func renderTextContent() {
        var text = "hello"
        let binding = Binding(get: { text }, set: { text = $0 })
        let textField = TextField("Input", text: binding)
        let context = testContext()

        let buffer = renderToBuffer(textField, context: context)
        let line = buffer.lines[0].stripped

        #expect(line.contains("hello"))
    }

    @Test("TextField renders with minimum width")
    func renderMinimumWidth() {
        var text = "hi"
        let binding = Binding(get: { text }, set: { text = $0 })
        let textField = TextField("Input", text: binding)
        let context = testContext()

        let buffer = renderToBuffer(textField, context: context)

        // Should have some minimum width even with short text
        #expect(buffer.width >= 20)
    }

    // MARK: - Focus Integration

    @Test("TextField renders successfully")
    func rendersSuccessfully() {
        var text = "test"
        let binding = Binding(get: { text }, set: { text = $0 })
        let textField = TextField("Input", text: binding)
        let context = testContext()

        // TextField should render without errors
        let buffer = renderToBuffer(textField, context: context)

        // Should produce valid output
        #expect(buffer.height == 1)
        #expect(buffer.width > 0)
    }

    // MARK: - Disabled State

    @Test("Disabled TextField cannot be focused")
    func disabledNotFocusable() {
        var text = "test"
        let binding = Binding(get: { text }, set: { text = $0 })
        let textField = TextField("Input", text: binding).disabled()

        // Should compile without error
        #expect(textField.isDisabled == true)
    }

    // MARK: - View Protocol Conformance

    @Test("TextField conforms to View")
    func viewConformance() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        // This test verifies that TextField conforms to View
        // and can be used in view builders
        let textField = TextField("Test", text: binding)

        // TextField.body should return some View
        let body = textField.body

        // Verify it can be rendered
        let context = testContext()
        let buffer = renderToBuffer(body, context: context)
        #expect(buffer.height >= 1)
    }

    @Test("TextField can be used in VStack")
    func inVStack() {
        var text1 = ""
        var text2 = ""
        let binding1 = Binding(get: { text1 }, set: { text1 = $0 })
        let binding2 = Binding(get: { text2 }, set: { text2 = $0 })

        let view = VStack {
            TextField("First", text: binding1)
            TextField("Second", text: binding2)
        }

        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 2)
    }

    // MARK: - ViewBuilder Label

    @Test("TextField with ViewBuilder label")
    func viewBuilderLabel() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        let textField = TextField(text: binding, prompt: Text("Enter text")) {
            Text("Custom Label")
        }

        let context = testContext()
        let buffer = renderToBuffer(textField, context: context)
        #expect(buffer.height == 1)
    }
}
