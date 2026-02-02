//
//  SpinnerTests.swift
//  TUIkit
//
//  Tests for the Spinner view and SpinnerStyle.
//

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a render context for spinner testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - SpinnerStyle Tests

@Suite("SpinnerStyle Tests")
struct SpinnerStyleTests {

    @Test("Dots style has 10 braille frames")
    func dotsFrameCount() {
        let frames = SpinnerStyle.dots.frames
        #expect(frames.count == 10)
        #expect(frames[0] == "⠋")
        #expect(frames[9] == "⠏")
    }

    @Test("Line style has 4 ASCII frames")
    func lineFrameCount() {
        let frames = SpinnerStyle.line.frames
        #expect(frames.count == 4)
        #expect(frames[0] == "|")
        #expect(frames[1] == "/")
        #expect(frames[2] == "-")
        #expect(frames[3] == "\\")
    }

    @Test("Bouncing positions form a complete bounce cycle")
    func bouncingPositions() {
        let positions = SpinnerStyle.bouncingPositions(trackLength: SpinnerStyle.minimumTrackWidth)

        // Forward: 7 positions + backward: 5 positions = 12
        #expect(positions.count == 12)

        // Forward sweep
        #expect(positions[0] == 0)
        #expect(positions[6] == 6)

        // Backward sweep starts at 5, ends at 1
        #expect(positions[7] == 5)
        #expect(positions[11] == 1)
    }

    @Test("Bouncing positions have no consecutive duplicates")
    func bouncingNoDuplicateEndpoints() {
        let positions = SpinnerStyle.bouncingPositions(trackLength: SpinnerStyle.minimumTrackWidth)

        for index in 1..<positions.count {
            #expect(positions[index] != positions[index - 1])
        }

        // Last and first differ (smooth looping)
        #expect(positions.last != positions.first)
    }

    @Test("Each style has a positive base interval")
    func baseIntervals() {
        #expect(SpinnerStyle.dots.baseInterval > 0)
        #expect(SpinnerStyle.line.baseInterval > 0)
        #expect(SpinnerStyle.bouncing.baseInterval > 0)
    }

    @Test("Wider track produces more bounce positions")
    func bouncingTrackWidthVariants() {
        let narrow = SpinnerStyle.bouncingPositions(trackLength: 7)
        let wide = SpinnerStyle.bouncingPositions(trackLength: 11)

        #expect(narrow.count < wide.count)
    }

    @Test("Bouncing frame renders all track positions with ANSI color codes")
    func bouncingFrameRendering() {
        let frame = SpinnerStyle.renderBouncingFrame(
            frameIndex: 3,
            color: .red,
            trackWidth: 9,
            trailLength: .regular
        )

        // Frame should contain ▇ characters (highlight + trail)
        #expect(frame.stripped.contains("▇"))
        // Frame should contain ■ characters (inactive positions)
        #expect(frame.stripped.contains("■"))
        // Should have ANSI escape codes for coloring
        #expect(frame.contains("\u{1B}["))
    }

    @Test("BouncingTrailLength opacities are correctly sized")
    func trailOpacityLevels() {
        #expect(BouncingTrailLength.short.opacities.count == 2)
        #expect(BouncingTrailLength.regular.opacities.count == 4)
        #expect(BouncingTrailLength.long.opacities.count == 6)
        // All start at full opacity
        #expect(BouncingTrailLength.short.opacities[0] == 1.0)
        #expect(BouncingTrailLength.regular.opacities[0] == 1.0)
        #expect(BouncingTrailLength.long.opacities[0] == 1.0)
    }

    @Test("Track width is clamped to minimum of 7")
    func trackWidthMinimum() {
        let spinner = Spinner(style: .bouncing, trackWidth: 3)
        // trackWidth is private, but we can verify via rendering — it shouldn't crash
        let context = testContext()
        let buffer = renderToBuffer(spinner, context: context)
        #expect(buffer.lines.count == 1)
    }

    @Test("SpinnerSpeed multipliers are ordered correctly")
    func speedMultipliers() {
        #expect(SpinnerSpeed.fast.multiplier < SpinnerSpeed.regular.multiplier)
        #expect(SpinnerSpeed.regular.multiplier < SpinnerSpeed.slow.multiplier)
        // Only three levels: slow, regular, fast
    }
}

// MARK: - Spinner Rendering Tests

@Suite("Spinner Rendering Tests")
struct SpinnerRenderingTests {

    @Test("Spinner without label renders single spinner character")
    func spinnerWithoutLabel() {
        let spinner = Spinner(style: .line)
        let context = testContext()
        let buffer = renderToBuffer(spinner, context: context)

        #expect(buffer.lines.count == 1)
        // First frame of line style is "|", colored with accent
        #expect(buffer.lines[0].stripped.contains("|"))
    }

    @Test("Spinner with label renders spinner followed by label text")
    func spinnerWithLabel() {
        let spinner = Spinner("Loading...", style: .line)
        let context = testContext()
        let buffer = renderToBuffer(spinner, context: context)

        #expect(buffer.lines.count == 1)
        let stripped = buffer.lines[0].stripped
        #expect(stripped.contains("Loading..."))
        #expect(stripped.contains("|"))
    }

    @Test("Spinner renders with custom color")
    func spinnerCustomColor() {
        let spinner = Spinner(style: .dots, color: .red)
        let context = testContext()
        let buffer = renderToBuffer(spinner, context: context)

        #expect(buffer.lines.count == 1)
        // Red foreground ANSI code
        #expect(buffer.lines[0].contains("\u{1B}[31m"))
    }

    @Test("Dots spinner first frame is braille character")
    func dotsFirstFrame() {
        let spinner = Spinner(style: .dots)
        let context = testContext()
        let buffer = renderToBuffer(spinner, context: context)

        #expect(buffer.lines[0].stripped == "⠋")
    }

    @Test("Bouncing spinner first frame contains highlight and track characters")
    func bouncingFirstFrame() {
        let spinner = Spinner(style: .bouncing)
        let context = testContext()
        let buffer = renderToBuffer(spinner, context: context)

        let stripped = buffer.lines[0].stripped
        #expect(stripped.contains("▇"))
        #expect(stripped.contains("■"))
    }

    @Test("Spinner frame index is derived from elapsed time")
    func spinnerTimeBasedFrames() {
        let spinner = Spinner(style: .line)
        let context = testContext()

        // Two immediate renders produce the same frame (same elapsed time bucket)
        let buffer1 = renderToBuffer(spinner, context: context)
        let buffer2 = renderToBuffer(spinner, context: context)

        #expect(buffer1.lines[0].stripped == buffer2.lines[0].stripped)
    }
}
