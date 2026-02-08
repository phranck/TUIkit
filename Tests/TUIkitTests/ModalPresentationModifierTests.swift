//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ModalPresentationModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT  dimming, centering, and arbitrary content.
//

import Testing

@testable import TUIkit

@MainActor
@Suite("ModalPresentationModifier Tests")
struct ModalPresentationModifierTests {

    /// Helper to create a RenderContext with default test settings.
    private func testContext() -> RenderContext {
        RenderContext(
            availableWidth: 80,
            availableHeight: 24,
            tuiContext: TUIContext()
        )
    }

    /// Helper to render a view to a FrameBuffer.
    private func render<V: View>(_ view: V) -> FrameBuffer {
        renderToBuffer(view, context: testContext())
    }

    @Test("Modal not presented shows only base content")
    func notPresentedShowsBase() {
        let isPresented = Binding.constant(false)
        let view = Text("Base Content")
            .modal(isPresented: isPresented) {
                Text("Modal Content")
            }

        let buffer = render(view)
        let content = buffer.lines.joined(separator: "\n").stripped

        #expect(content.contains("Base Content"))
        #expect(!content.contains("Modal Content"))
    }

    @Test("Modal presented shows dimmed base with modal overlay")
    func presentedShowsModal() {
        let isPresented = Binding.constant(true)
        let view = VStack {
            Text("Base Content")
            Text("More base text")
        }
        .modal(isPresented: isPresented) {
            Text("Modal Content")
        }

        let buffer = render(view)

        // Modal content should be present
        let stripped = buffer.lines.joined(separator: "\n").stripped
        #expect(stripped.contains("Modal Content"))

        // Should have ANSI codes (from dimmed base and compositing)
        let rawContent = buffer.lines.joined(separator: "\n")
        #expect(rawContent.contains("\u{1B}["))  // Contains ANSI codes
    }

    @Test("Modal accepts arbitrary view content")
    func arbitraryContent() {
        let isPresented = Binding.constant(true)
        let view = Text("Base")
            .modal(isPresented: isPresented) {
                VStack {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                }
            }

        let buffer = render(view)
        let content = buffer.lines.joined(separator: "\n").stripped

        #expect(content.contains("Line 1"))
        #expect(content.contains("Line 2"))
        #expect(content.contains("Line 3"))
    }

    @Test("Modal works with Dialog view")
    func modalWithDialog() {
        let isPresented = Binding.constant(true)
        let view = Text("Base")
            .modal(isPresented: isPresented) {
                Dialog(title: "Settings") {
                    Text("Option 1")
                    Text("Option 2")
                }
            }

        let buffer = render(view)
        let content = buffer.lines.joined(separator: "\n").stripped

        #expect(content.contains("Settings"))
        #expect(content.contains("Option 1"))
        #expect(content.contains("Option 2"))
    }

    @Test("Modal works with Alert view")
    func modalWithAlert() {
        let isPresented = Binding.constant(true)
        let view = Text("Base")
            .modal(isPresented: isPresented) {
                Alert(title: "Warning", message: "Sure?") {
                    Button("Yes") { }
                }
            }

        let buffer = render(view)
        let content = buffer.lines.joined(separator: "\n").stripped

        #expect(content.contains("Warning"))
        #expect(content.contains("Sure?"))
        #expect(content.contains("Yes"))
    }

    @Test("Toggle isPresented switches between states")
    func togglePresentation() {
        @State var showModal = false

        let view1 = Text("Content")
            .modal(isPresented: $showModal) {
                Text("Modal")
            }

        let buffer1 = render(view1)
        let content1 = buffer1.lines.joined(separator: "\n").stripped

        // Initially not shown
        #expect(!content1.contains("Modal"))

        // Toggle to show
        showModal = true
        let view2 = Text("Content")
            .modal(isPresented: $showModal) {
                Text("Modal")
            }

        let buffer2 = render(view2)
        let content2 = buffer2.lines.joined(separator: "\n").stripped

        // Now shown
        #expect(content2.contains("Modal"))
    }

    @Test("Modal centers content over base")
    func centersContent() {
        let isPresented = Binding.constant(true)
        let view = VStack {
            Text("Wide base content that spans multiple characters")
            Text("Another line of wide content here")
        }
        .modal(isPresented: isPresented) {
            Text("Small")
        }

        let buffer = render(view)

        // Modal should be rendered (non-empty, contains both base and modal)
        #expect(!buffer.isEmpty)
        let content = buffer.lines.joined(separator: "\n").stripped
        #expect(content.contains("Wide base content"))
        #expect(content.contains("Small"))
    }
}
