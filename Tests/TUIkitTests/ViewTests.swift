//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("AnyView Tests")
struct AnyViewTests {

    @Test("AnyView wraps view correctly")
    func anyViewWrapping() {
        let text = Text("Hello")
        let anyView = AnyView(text)
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(anyView, context: context)
        #expect(buffer.lines[0].stripped == "Hello")
    }

    @Test("asAnyView extension works")
    func asAnyViewExtension() {
        let anyView = Text("Test").bold().asAnyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(anyView, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "Test")
        #expect(buffer.lines[0].contains("[1;")) // bold ANSI code (combined with color)
    }
}
