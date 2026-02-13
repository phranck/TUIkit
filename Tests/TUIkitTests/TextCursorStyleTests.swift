//  TUIKit - Terminal UI Kit for Swift
//  TextCursorStyleTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing
@testable import TUIkit

@Suite("TextCursorStyle")
struct TextCursorStyleTests {
    // MARK: - Shape Character Tests

    @Test("Block shape returns full block character")
    func blockShapeCharacter() {
        #expect(TextCursorStyle.Shape.block.character == "█")
    }

    @Test("Bar shape returns centered vertical line")
    func barShapeCharacter() {
        #expect(TextCursorStyle.Shape.bar.character == "│")
    }

    @Test("Underscore shape returns lower block")
    func underscoreShapeCharacter() {
        #expect(TextCursorStyle.Shape.underscore.character == "▁")
    }

    // MARK: - Default Values

    @Test("Default style uses block shape with blink animation at regular speed")
    func defaultStyle() {
        let style = TextCursorStyle()
        #expect(style.shape == .block)
        #expect(style.animation == .blink)
        #expect(style.speed == .regular)
    }

    @Test("Static block convenience uses block shape with blink at regular speed")
    func staticBlockConvenience() {
        let style = TextCursorStyle.block
        #expect(style.shape == .block)
        #expect(style.animation == .blink)
        #expect(style.speed == .regular)
    }

    @Test("Static bar convenience uses bar shape with blink at regular speed")
    func staticBarConvenience() {
        let style = TextCursorStyle.bar
        #expect(style.shape == .bar)
        #expect(style.animation == .blink)
        #expect(style.speed == .regular)
    }

    @Test("Static underscore convenience uses underscore shape with blink at regular speed")
    func staticUnderscoreConvenience() {
        let style = TextCursorStyle.underscore
        #expect(style.shape == .underscore)
        #expect(style.animation == .blink)
        #expect(style.speed == .regular)
    }

    // MARK: - Custom Initialization

    @Test("Custom style with bar and blink")
    func customStyleBarBlink() {
        let style = TextCursorStyle(shape: .bar, animation: .blink)
        #expect(style.shape == .bar)
        #expect(style.animation == .blink)
    }

    @Test("Custom style with underscore and no animation")
    func customStyleUnderscoreNone() {
        let style = TextCursorStyle(shape: .underscore, animation: .none)
        #expect(style.shape == .underscore)
        #expect(style.animation == .none)
    }

    // MARK: - Equatable

    @Test("Styles with same values are equal")
    func equalityWithSameValues() {
        let style1 = TextCursorStyle(shape: .bar, animation: .blink)
        let style2 = TextCursorStyle(shape: .bar, animation: .blink)
        #expect(style1 == style2)
    }

    @Test("Styles with different shapes are not equal")
    func inequalityWithDifferentShapes() {
        let style1 = TextCursorStyle(shape: .block, animation: .pulse)
        let style2 = TextCursorStyle(shape: .bar, animation: .pulse)
        #expect(style1 != style2)
    }

    @Test("Styles with different animations are not equal")
    func inequalityWithDifferentAnimations() {
        let style1 = TextCursorStyle(shape: .block, animation: .pulse)
        let style2 = TextCursorStyle(shape: .block, animation: .blink)
        #expect(style1 != style2)
    }

    // MARK: - Shape CaseIterable

    @Test("Shape has exactly three cases")
    func shapeHasThreeCases() {
        #expect(TextCursorStyle.Shape.allCases.count == 3)
    }

    @Test("Shape cases are block, bar, underscore")
    func shapeCasesCorrect() {
        let cases = TextCursorStyle.Shape.allCases
        #expect(cases.contains(.block))
        #expect(cases.contains(.bar))
        #expect(cases.contains(.underscore))
    }

    // MARK: - Animation CaseIterable

    @Test("Animation has exactly three cases")
    func animationHasThreeCases() {
        #expect(TextCursorStyle.Animation.allCases.count == 3)
    }

    @Test("Animation cases are none, blink, pulse")
    func animationCasesCorrect() {
        let cases = TextCursorStyle.Animation.allCases
        #expect(cases.contains(.none))
        #expect(cases.contains(.blink))
        #expect(cases.contains(.pulse))
    }

    // MARK: - Speed

    @Test("Speed has exactly three cases")
    func speedHasThreeCases() {
        #expect(TextCursorStyle.Speed.allCases.count == 3)
    }

    @Test("Speed cases are slow, regular, fast")
    func speedCasesCorrect() {
        let cases = TextCursorStyle.Speed.allCases
        #expect(cases.contains(.slow))
        #expect(cases.contains(.regular))
        #expect(cases.contains(.fast))
    }

    @Test("Slow speed has correct blink cycle")
    func slowSpeedBlinkCycle() {
        #expect(TextCursorStyle.Speed.slow.blinkCycleMs == 1000)
    }

    @Test("Regular speed has correct blink cycle")
    func regularSpeedBlinkCycle() {
        #expect(TextCursorStyle.Speed.regular.blinkCycleMs == 660)
    }

    @Test("Fast speed has correct blink cycle")
    func fastSpeedBlinkCycle() {
        #expect(TextCursorStyle.Speed.fast.blinkCycleMs == 400)
    }

    @Test("Slow speed has correct pulse cycle")
    func slowSpeedPulseCycle() {
        #expect(TextCursorStyle.Speed.slow.pulseCycleMs == 1200)
    }

    @Test("Regular speed has correct pulse cycle")
    func regularSpeedPulseCycle() {
        #expect(TextCursorStyle.Speed.regular.pulseCycleMs == 800)
    }

    @Test("Fast speed has correct pulse cycle")
    func fastSpeedPulseCycle() {
        #expect(TextCursorStyle.Speed.fast.pulseCycleMs == 500)
    }

    @Test("Styles with different speeds are not equal")
    func inequalityWithDifferentSpeeds() {
        let style1 = TextCursorStyle(shape: .block, animation: .pulse, speed: .slow)
        let style2 = TextCursorStyle(shape: .block, animation: .pulse, speed: .fast)
        #expect(style1 != style2)
    }

    // MARK: - Environment Default

    @Test("Environment default is block with blink at regular speed")
    func environmentDefaultValue() {
        let env = EnvironmentValues()
        let style = env.textCursorStyle
        #expect(style.shape == .block)
        #expect(style.animation == .blink)
        #expect(style.speed == .regular)
    }
}
