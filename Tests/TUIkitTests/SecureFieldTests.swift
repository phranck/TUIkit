//  TUIKit - Terminal UI Kit for Swift
//  SecureFieldTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - SecureField Tests

@MainActor
@Suite("SecureField Tests")
struct SecureFieldTests {

    private func testContext(width: Int = 80, height: Int = 24) -> RenderContext {
        RenderContext(availableWidth: width, availableHeight: height)
    }

    // MARK: - Initialization

    @Test("SecureField initializes with title and text binding")
    func initializationBasic() {
        var text = "secret"
        let binding = Binding(get: { text }, set: { text = $0 })

        let secureField = SecureField("Password", text: binding)

        // Should compile and render without error
        let context = testContext()
        let buffer = renderToBuffer(secureField, context: context)
        #expect(buffer.height == 1)
    }

    @Test("SecureField initializes with prompt")
    func initializationWithPrompt() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        let secureField = SecureField("Password", text: binding, prompt: Text("Required"))

        #expect(secureField.prompt != nil)
    }

    // MARK: - Masking Behavior

    @Test("SecureField displays bullets instead of text")
    func displaysBullets() {
        var text = "secret"
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding)
        let context = testContext()

        let buffer = renderToBuffer(secureField, context: context)
        let line = buffer.lines[0].stripped

        // Should contain bullets (●), not the actual text
        #expect(line.contains("●"))
        #expect(!line.contains("secret"))
    }

    @Test("SecureField bullet count matches text length")
    func bulletCountMatchesTextLength() {
        var text = "abc"  // 3 characters
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding)
        let context = testContext()

        let buffer = renderToBuffer(secureField, context: context)
        let line = buffer.lines[0].stripped

        // Count bullets in the output
        let bulletCount = line.filter { $0 == "●" }.count
        #expect(bulletCount == 3)
    }

    @Test("SecureField shows more bullets for longer text")
    func longerTextMoreBullets() {
        var shortText = "ab"
        var longText = "abcdefgh"
        let shortBinding = Binding(get: { shortText }, set: { shortText = $0 })
        let longBinding = Binding(get: { longText }, set: { longText = $0 })

        let shortField = SecureField("Short", text: shortBinding)
        let longField = SecureField("Long", text: longBinding)
        let context = testContext()

        let shortBuffer = renderToBuffer(shortField, context: context)
        let longBuffer = renderToBuffer(longField, context: context)

        let shortBullets = shortBuffer.lines[0].stripped.filter { $0 == "●" }.count
        let longBullets = longBuffer.lines[0].stripped.filter { $0 == "●" }.count

        #expect(longBullets > shortBullets)
        #expect(shortBullets == 2)
        #expect(longBullets == 8)
    }

    // MARK: - Rendering

    @Test("SecureField renders with minimum width")
    func renderMinimumWidth() {
        var text = "hi"
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding)
        let context = testContext()

        let buffer = renderToBuffer(secureField, context: context)

        // Should have some minimum width even with short text
        #expect(buffer.width >= 20)
    }

    @Test("SecureField renders empty field")
    func renderEmptyField() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding)
        let context = testContext()

        let buffer = renderToBuffer(secureField, context: context)

        // Should render without error
        #expect(buffer.height == 1)
        #expect(buffer.width > 0)

        // Should not contain any bullets
        let bulletCount = buffer.lines[0].stripped.filter { $0 == "●" }.count
        #expect(bulletCount == 0)
    }

    // MARK: - Disabled State

    @Test("Disabled SecureField stores disabled state")
    func disabledState() {
        var text = "test"
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding).disabled()

        #expect(secureField.isDisabled == true)
    }

    @Test("Disabled SecureField still shows bullets")
    func disabledShowsBullets() {
        var text = "secret"
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding).disabled()
        let context = testContext()

        let buffer = renderToBuffer(secureField, context: context)
        let line = buffer.lines[0].stripped

        // Should still show bullets when disabled
        #expect(line.contains("●"))
    }

    // MARK: - View Protocol Conformance

    @Test("SecureField conforms to View")
    func viewConformance() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })

        let secureField = SecureField("Test", text: binding)

        // SecureField.body should return some View
        let body = secureField.body

        // Verify it can be rendered
        let context = testContext()
        let buffer = renderToBuffer(body, context: context)
        #expect(buffer.height >= 1)
    }

    @Test("SecureField can be used in VStack")
    func inVStack() {
        var text1 = ""
        var text2 = ""
        let binding1 = Binding(get: { text1 }, set: { text1 = $0 })
        let binding2 = Binding(get: { text2 }, set: { text2 = $0 })

        let view = VStack {
            SecureField("Password", text: binding1)
            SecureField("Confirm", text: binding2)
        }

        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 2)
    }

    // MARK: - onSubmit Modifier

    @Test("SecureField onSubmit modifier stores action")
    func onSubmitStoresAction() {
        var text = ""
        var submitted = false
        let binding = Binding(get: { text }, set: { text = $0 })

        let secureField = SecureField("Password", text: binding)
            .onSubmit { submitted = true }

        #expect(secureField.onSubmitAction != nil)
    }

    // MARK: - Prompt Display

    @Test("SecureField shows prompt when empty and unfocused")
    func promptWhenEmptyUnfocused() {
        var text = ""
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding, prompt: Text("Enter password"))
        let context = testContext()

        let buffer = renderToBuffer(secureField, context: context)
        let line = buffer.lines[0].stripped

        // Should show prompt text when empty
        #expect(line.contains("Enter password"))
    }

    @Test("SecureField hides prompt when has text")
    func promptHiddenWhenHasText() {
        var text = "secret"
        let binding = Binding(get: { text }, set: { text = $0 })
        let secureField = SecureField("Password", text: binding, prompt: Text("Enter password"))
        let context = testContext()

        let buffer = renderToBuffer(secureField, context: context)
        let line = buffer.lines[0].stripped

        // Should show bullets, not prompt
        #expect(line.contains("●"))
        #expect(!line.contains("Enter password"))
    }
}
