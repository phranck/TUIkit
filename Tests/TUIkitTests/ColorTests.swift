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
}
