//
//  KeyPressModifierTests.swift
//  TUIkit
//
//  Tests for KeyPressModifier.
//

import Testing

@testable import TUIkit

@Suite("KeyPressModifier Tests")
struct KeyPressModifierTests {

    @Test("onKeyPress with key set creates KeyPressModifier")
    func onKeyPressKeySet() {
        let modifier = KeyPressModifier(
            content: Text("Hello"),
            keys: [.enter, .tab],
            handler: { _ in true }
        )
        #expect(modifier.keys?.count == 2)
    }

    @Test("onKeyPress single key creates modifier with that key")
    func onKeyPressSingleKey() {
        let modifier = KeyPressModifier(
            content: Text("Hello"),
            keys: [.enter],
            handler: { _ in true }
        )
        #expect(modifier.keys?.count == 1)
        #expect(modifier.keys?.contains(.enter) == true)
    }
}
