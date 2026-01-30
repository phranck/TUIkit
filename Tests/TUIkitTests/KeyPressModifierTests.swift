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

    @Test("onKeyPress with key set creates modifier with correct keys")
    func onKeyPressKeySet() {
        let view = Text("Hello").onKeyPress(keys: [.enter, .tab]) { _ in true }
        #expect(view.keys?.count == 2)
    }

    @Test("onKeyPress single key creates modifier with that key")
    func onKeyPressSingleKey() {
        let view = Text("Hello").onKeyPress(.enter) {}
        #expect(view.keys?.count == 1)
        #expect(view.keys?.contains(.enter) == true)
    }
}
