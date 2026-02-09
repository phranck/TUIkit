//  TUIKit - Terminal UI Kit for Swift
//  SliderTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

@MainActor
@Suite("Slider Tests")
struct SliderTests {

    // MARK: - Basic Rendering

    @Test("Slider renders as single line")
    func rendersSingleLine() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
    }

    @Test("Slider contains left arrow")
    func containsLeftArrow() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("◀"))
    }

    @Test("Slider contains right arrow")
    func containsRightArrow() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("▶"))
    }

    @Test("Slider shows percentage value")
    func showsPercentageValue() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("50%"))
    }

    // MARK: - Track Styles

    @Test("Default block style shows filled and empty blocks")
    func blockStyleShowsBlocks() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let line = buffer.lines[0].stripped
        #expect(line.contains("█"))
        #expect(line.contains("░"))
    }

    @Test("Dot style shows track with dot head")
    func dotStyleShowsDotHead() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
            .trackStyle(.dot)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let line = buffer.lines[0].stripped
        #expect(line.contains("●"))
        #expect(line.contains("▬") || line.contains("─"))
    }

    @Test("Shade style shows shade characters")
    func shadeStyleShowsShadeChars() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
            .trackStyle(.shade)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let line = buffer.lines[0].stripped
        #expect(line.contains("▓"))
        #expect(line.contains("░"))
    }

    // MARK: - Value Display

    @Test("0% value shows 0%")
    func zeroValueShowsZeroPercent() {
        var value = 0.0
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("0%"))
    }

    @Test("100% value shows 100%")
    func fullValueShowsHundredPercent() {
        var value = 1.0
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("100%"))
    }

    @Test("Custom range shows correct percentage")
    func customRangeShowsCorrectPercentage() {
        var value = 50.0
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }), in: 0...100)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.lines[0].contains("50%"))
    }

    // MARK: - Track Width

    @Test("Track uses default width without explicit frame")
    func usesDefaultWidth() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        // Default track width is 20, plus arrows, spaces, value label
        // Total should be around 30+ characters
        #expect(buffer.width > 25)
    }

    // MARK: - Title Initializer

    @Test("Slider with title compiles and renders")
    func titleInitializerWorks() {
        var value = 0.5
        let view = Slider("Volume", value: Binding(get: { value }, set: { value = $0 }))
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        #expect(buffer.height == 1)
        #expect(buffer.lines[0].contains("50%"))
    }
}

@MainActor
@Suite("Slider Track Style Tests")
struct SliderTrackStyleTests {

    @Test("trackStyle modifier changes style")
    func trackStyleModifierChangesStyle() {
        var value = 0.5
        let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
            .trackStyle(.bar)
        let context = testContext()
        let buffer = renderToBuffer(view, context: context)

        let line = buffer.lines[0].stripped
        #expect(line.contains("▌") || line.contains("─"))
    }

    @Test("All track styles render without crashing")
    func allStylesRenderWithoutCrashing() {
        let styles: [TrackStyle] = [.block, .blockFine, .shade, .bar, .dot]

        for style in styles {
            var value = 0.5
            let view = Slider(value: Binding(get: { value }, set: { value = $0 }))
                .trackStyle(style)
            let context = testContext()
            let buffer = renderToBuffer(view, context: context)

            #expect(buffer.height == 1, "Style \(style) should render one line")
            #expect(buffer.lines[0].contains("◀"), "Style \(style) should contain left arrow")
            #expect(buffer.lines[0].contains("▶"), "Style \(style) should contain right arrow")
        }
    }
}
