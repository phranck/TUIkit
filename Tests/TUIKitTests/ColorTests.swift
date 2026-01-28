//
//  ColorTests.swift
//  TUIKit
//
//  Tests for the Color system and ANSI rendering.
//

import Testing
@testable import TUIKit

@Suite("Color Tests")
struct ColorTests {

    @Test("Standard colors are available")
    func standardColors() {
        let colors: [Color] = [
            .black, .red, .green, .yellow,
            .blue, .magenta, .cyan, .white
        ]

        #expect(colors.count == 8)
    }

    @Test("Bright colors are available")
    func brightColors() {
        let colors: [Color] = [
            .brightBlack, .brightRed, .brightGreen, .brightYellow,
            .brightBlue, .brightMagenta, .brightCyan, .brightWhite
        ]

        #expect(colors.count == 8)
    }

    @Test("RGB color can be created")
    func rgbColor() {
        let color = Color.rgb(255, 128, 64)
        #expect(color == Color.rgb(255, 128, 64))
    }

    @Test("Hex color can be created")
    func hexColor() {
        let color = Color.hex(0xFF8040)
        #expect(color == Color.rgb(255, 128, 64))
    }

    @Test("Palette color can be created")
    func paletteColor() {
        let color = Color.palette(196)
        #expect(color == Color.palette(196))
    }

    @Test("Semantic colors are defined")
    func semanticColors() {
        _ = Color.primary
        _ = Color.secondary
        _ = Color.accent
        _ = Color.warning
        _ = Color.error
        _ = Color.success
    }
}

@Suite("ANSI Renderer Tests")
struct ANSIRendererTests {

    @Test("Reset code is correct")
    func resetCode() {
        #expect(ANSIRenderer.reset == "\u{1B}[0m")
    }

    @Test("Text without style is returned unchanged")
    func plainText() {
        let result = ANSIRenderer.render("Hello", with: TextStyle())
        #expect(result == "Hello")
    }

    @Test("Bold text has correct code")
    func boldText() {
        var style = TextStyle()
        style.isBold = true
        let result = ANSIRenderer.render("Bold", with: style)
        #expect(result.contains("\u{1B}[1m"))
        #expect(result.contains("\u{1B}[0m"))
    }

    @Test("Cursor movement generates correct codes")
    func cursorMovement() {
        let moveCode = ANSIRenderer.moveCursor(toRow: 5, column: 10)
        #expect(moveCode == "\u{1B}[5;10H")
    }

    @Test("Clear screen generates correct code")
    func clearScreen() {
        #expect(ANSIRenderer.clearScreen == "\u{1B}[2J")
    }
}
