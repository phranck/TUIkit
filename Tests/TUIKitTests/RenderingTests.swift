//
//  RenderingTests.swift
//  TUIKit
//
//  Tests for view rendering and layout.
//

import Testing
@testable import TUIKit

@Suite("Rendering Tests")
struct RenderingTests {

    @Test("Text renders to single line buffer")
    func textBuffer() {
        let text = Text("Hello")
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(text, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "Hello")
    }

    @Test("EmptyView renders to empty buffer")
    func emptyViewBuffer() {
        let empty = EmptyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(empty, context: context)
        #expect(buffer.isEmpty)
    }

    @Test("VStack renders children vertically")
    func vstackBuffer() {
        let stack = VStack {
            Text("Line 1")
            Text("Line 2")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 2)
        #expect(buffer.lines[0] == "Line 1")
        #expect(buffer.lines[1] == "Line 2")
    }

    @Test("VStack renders with spacing")
    func vstackWithSpacing() {
        let stack = VStack(spacing: 1) {
            Text("A")
            Text("B")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 3)
        #expect(buffer.lines[0] == "A")
        #expect(buffer.lines[1] == "")
        #expect(buffer.lines[2] == "B")
    }

    @Test("HStack renders children horizontally")
    func hstackBuffer() {
        let stack = HStack {
            Text("Left")
            Text("Right")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "Left Right")
    }

    @Test("HStack renders with custom spacing")
    func hstackCustomSpacing() {
        let stack = HStack(spacing: 3) {
            Text("A")
            Text("B")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(stack, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "A   B")
    }

    @Test("Nested VStack in HStack works")
    func nestedStacks() {
        let layout = HStack(spacing: 2) {
            Text("Label:")
            Text("Value")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(layout, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == "Label:  Value")
    }

    @Test("Composite view renders through body")
    func compositeView() {
        struct MyView: View {
            var body: some View {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }

        let view = MyView()
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(view, context: context)
        #expect(buffer.height == 2)
        #expect(buffer.lines[0] == "Hello")
        #expect(buffer.lines[1] == "World")
    }

    @Test("Divider renders to full width")
    func dividerBuffer() {
        let divider = Divider()
        let context = RenderContext(availableWidth: 20, availableHeight: 24)
        let buffer = renderToBuffer(divider, context: context)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0] == String(repeating: "─", count: 20))
    }

    @Test("Spacer renders empty lines")
    func spacerBuffer() {
        let spacer = Spacer(minLength: 3)
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(spacer, context: context)
        #expect(buffer.height == 3)
    }
}
