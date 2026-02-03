//
//  ColorTests.swift
//  TUIkit
//
//  Tests for the Color system and ANSI rendering.
//

import Testing

@testable import TUIkit

@Suite("Color Tests")
struct ColorTests {

    @Test("Hex color converts to correct RGB components")
    func hexColor() {
        let color = Color.hex(0xFF8040)
        #expect(color == Color.rgb(255, 128, 64))
    }

    @Test("Standard and bright colors are distinct")
    func standardVsBright() {
        #expect(Color.red != Color.brightRed)
        #expect(Color.blue != Color.brightBlue)
        #expect(Color.green != Color.brightGreen)
    }

    @Test("RGB colors with different components are distinct")
    func rgbDistinct() {
        #expect(Color.rgb(255, 0, 0) != Color.rgb(0, 255, 0))
        #expect(Color.rgb(0, 0, 255) != Color.rgb(0, 0, 254))
    }

    @Test("Palette colors with different indices are distinct")
    func paletteDistinct() {
        #expect(Color.palette(42) != Color.palette(43))
    }

    @Test("lerp at phase 0 returns from color")
    func lerpAtZero() {
        let from = Color.rgb(0, 0, 0)
        let to = Color.rgb(255, 255, 255)
        let result = Color.lerp(from, to, phase: 0)
        #expect(result == from)
    }

    @Test("lerp at phase 1 returns to color")
    func lerpAtOne() {
        let from = Color.rgb(0, 0, 0)
        let to = Color.rgb(255, 255, 255)
        let result = Color.lerp(from, to, phase: 1)
        #expect(result == to)
    }

    @Test("lerp at midpoint produces average")
    func lerpAtMidpoint() {
        let from = Color.rgb(0, 100, 200)
        let to = Color.rgb(100, 200, 50)
        let result = Color.lerp(from, to, phase: 0.5)
        let components = result.rgbComponents!
        #expect(components.red == 50)
        #expect(components.green == 150)
        #expect(components.blue == 125)
    }

    @Test("lerp clamps phase to 0-1 range")
    func lerpClampsPhase() {
        let from = Color.rgb(0, 0, 0)
        let to = Color.rgb(200, 200, 200)
        let underflow = Color.lerp(from, to, phase: -0.5)
        let overflow = Color.lerp(from, to, phase: 1.5)
        #expect(underflow == from)
        #expect(overflow == to)
    }

    @Test("lerp with ANSI colors converts to RGB")
    func lerpWithANSI() {
        let from = Color.black
        let to = Color.white
        let result = Color.lerp(from, to, phase: 0.5)
        // Should produce an RGB color (not crash)
        #expect(result.rgbComponents != nil)
    }
}
