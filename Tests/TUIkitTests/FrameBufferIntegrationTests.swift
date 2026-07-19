//  🖥️ TUIKit — Terminal UI Kit for Swift
//  FrameBufferIntegrationTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("Overlay Tests")
struct OverlayTests {

    @Test("Overlay modifier renders overlay on top of base")
    func overlayRendering() {
        let view = Text("Base Content")
            .overlay(alignment: .center) {
                Text("Top")
            }
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        // The overlay "Top" should be centered on "Base Content"
        #expect(buffer.height >= 1)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Top"))
    }

    @Test("Dimmed modifier strips styling and applies uniform palette colors")
    func dimmedRendering() {
        let view = Text("Dimmed text").dimmed()
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        #expect(buffer.height == 1)
        // Should not use ANSI dim — uses palette-based flat coloring now
        #expect(!buffer.lines[0].contains("\u{1B}[2m"))
        // Visible text must be preserved
        #expect(buffer.lines[0].stripped.contains("Dimmed text"))
    }

    @Test("Modal helper combines dimmed and overlay")
    func modalRendering() {
        let view = Text("Background")
            .modal {
                Text("Modal")
            }
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        // The result should contain both the dimmed background and the modal overlay
        #expect(buffer.height == 1)
        // Overlay compositing should show "Modal" overlaid on "Background"
        let stripped = buffer.lines[0].stripped
        #expect(stripped.contains("Modal"))
        // The visible text shows the overlay positioned over the base
        #expect(buffer.width >= 5) // at least "Modal" width
    }

    @Test("FrameBuffer compositing places overlay at correct position")
    func frameBufferCompositing() {
        let base = FrameBuffer(lines: ["AAAA", "AAAA", "AAAA"])
        let overlay = FrameBuffer(text: "X")

        // Place overlay at position (1, 1)
        let result = base.composited(with: overlay, at: (x: 1, y: 1))

        #expect(result.height == 3)
        #expect(result.lines[0] == "AAAA")
        #expect(result.lines[1].contains("X"))
        #expect(result.lines[2] == "AAAA")
    }

    @Test("FrameBuffer compositing with offset")
    func frameBufferCompositingOffset() {
        let base = FrameBuffer(lines: ["1234567890"])
        let overlay = FrameBuffer(text: "XXX")

        // Place overlay at column 3
        let result = base.composited(with: overlay, at: (x: 3, y: 0))

        #expect(result.lines[0].stripped == "123XXX7890")
    }
}
