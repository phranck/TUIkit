//
//  ViewTests.swift
//  TUIkit
//
//  Tests for the View protocol, ViewBuilder, and basic views.
//

import Testing

@testable import TUIkit

@Suite("AnyView Tests")
struct AnyViewTests {

    @Test("AnyView wraps view correctly")
    func anyViewWrapping() {
        let text = Text("Hello")
        let anyView = AnyView(text)
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(anyView, context: context)
        #expect(buffer.lines[0] == "Hello")
    }

    @Test("asAnyView extension works")
    func asAnyViewExtension() {
        let anyView = Text("Test").bold().asAnyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(anyView, context: context)
        #expect(!buffer.isEmpty)
    }
}
