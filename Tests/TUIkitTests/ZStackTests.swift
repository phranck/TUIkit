//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ZStackTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("ZStack Tests")
struct ZStackTests {
    @Test("Default alignment centers every child in the shared surface")
    func defaultCenterAlignment() {
        let stack = ZStack {
            Text("12345")
            Text("X")
        }

        let buffer = render(stack)

        #expect(buffer.width == 5)
        #expect(buffer.height == 1)
        #expect(buffer.lines[0].stripped == "12X45")
    }

    @Test("Bottom-trailing alignment applies on both axes")
    func bottomTrailingAlignment() {
        let stack = ZStack(alignment: .bottomTrailing) {
            Text("ABCD")
            VStack(spacing: 0) {
                Text("X")
                Text("Y")
            }
        }

        let buffer = render(stack)

        #expect(buffer.width == 4)
        #expect(buffer.height == 2)
        #expect(buffer.lines[0].stripped == "   X")
        #expect(buffer.lines[1].stripped == "ABCY")
    }

    private func render<V: View>(_ view: V) -> FrameBuffer {
        let context = RenderContext(
            availableWidth: 40,
            availableHeight: 10,
            tuiContext: TUIContext()
        )
        return renderToBuffer(view, context: context)
    }
}
