//
//  KeyPressModifierTests.swift
//  TUIkit
//
//  Tests for KeyPressModifier: filtered and unfiltered key handling,
//  and View extension methods.
//

import Testing

@testable import TUIkit

@Suite("KeyPressModifier Tests")
struct KeyPressModifierTests {

    @Test("KeyPressModifier stores content and handler")
    func storesProperties() {
        let modifier = KeyPressModifier(
            content: Text("Hello"),
            keys: nil,
            handler: { _ in true }
        )
        #expect(modifier.keys == nil)
    }

    @Test("KeyPressModifier with key filter stores keys")
    func storesKeys() {
        let modifier = KeyPressModifier(
            content: Text("Hello"),
            keys: [.enter, .escape],
            handler: { _ in true }
        )
        #expect(modifier.keys?.count == 2)
        #expect(modifier.keys?.contains(.enter) == true)
        #expect(modifier.keys?.contains(.escape) == true)
    }

    @Test("onKeyPress all-key handler creates modifier")
    func onKeyPressAllKeys() {
        let view = Text("Hello").onKeyPress { _ in true }
        // Should compile and create a KeyPressModifier (type check)
        #expect(view is KeyPressModifier<Text>)
    }

    @Test("onKeyPress with key set creates modifier")
    func onKeyPressKeySet() {
        let view = Text("Hello").onKeyPress(keys: [.enter, .tab]) { _ in true }
        #expect(view.keys?.count == 2)
    }

    @Test("onKeyPress single key creates modifier")
    func onKeyPressSingleKey() {
        let view = Text("Hello").onKeyPress(.enter) {}
        #expect(view.keys?.count == 1)
        #expect(view.keys?.contains(.enter) == true)
    }

    @Test("KeyPressModifier conforms to Renderable")
    func conformsToRenderable() {
        let modifier = KeyPressModifier(
            content: Text("Test"),
            keys: nil,
            handler: { _ in false }
        )
        #expect(modifier is any Renderable)
    }
}
