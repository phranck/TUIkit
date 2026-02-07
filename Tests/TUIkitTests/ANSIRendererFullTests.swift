//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ANSIRendererFullTests.swift
//
//  Created by LAYERED.work
//  License: MIT  cursor control, screen control, and convenience methods.
//

import Testing

@testable import TUIkit

// MARK: - Style Rendering Tests

@MainActor
@Suite("ANSIRenderer Style Rendering Tests")
struct ANSIRendererStyleTests {

    @Test("Plain text without style returns unchanged")
    func plainText() {
        let result = ANSIRenderer.render("Hello", with: TextStyle())
        #expect(result == "Hello")
    }

    @Test("Bold text wraps with bold code")
    func boldText() {
        var style = TextStyle()
        style.isBold = true
        let result = ANSIRenderer.render("Bold", with: style)
        #expect(result.contains("\u{1B}[1m"))
        #expect(result.contains("Bold"))
        #expect(result.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Dim text wraps with ESC[2m dim code")
    func dimText() {
        var style = TextStyle()
        style.isDim = true
        let result = ANSIRenderer.render("Dim", with: style)
        #expect(result.contains("\u{1B}[2m"))
        #expect(result.contains("Dim"))
        #expect(result.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Italic text wraps with ESC[3m italic code")
    func italicText() {
        var style = TextStyle()
        style.isItalic = true
        let result = ANSIRenderer.render("Italic", with: style)
        #expect(result.contains("\u{1B}[3m"))
        #expect(result.contains("Italic"))
        #expect(result.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Underlined text wraps with ESC[4m underline code")
    func underlinedText() {
        var style = TextStyle()
        style.isUnderlined = true
        let result = ANSIRenderer.render("Underline", with: style)
        #expect(result.contains("\u{1B}[4m"))
        #expect(result.contains("Underline"))
        #expect(result.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Blink text wraps with ESC[5m blink code")
    func blinkText() {
        var style = TextStyle()
        style.isBlink = true
        let result = ANSIRenderer.render("Blink", with: style)
        #expect(result.contains("\u{1B}[5m"))
        #expect(result.contains("Blink"))
        #expect(result.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Inverted text wraps with ESC[7m inverse code")
    func invertedText() {
        var style = TextStyle()
        style.isInverted = true
        let result = ANSIRenderer.render("Inv", with: style)
        #expect(result.contains("\u{1B}[7m"))
        #expect(result.contains("Inv"))
        #expect(result.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Strikethrough text wraps with ESC[9m strikethrough code")
    func strikethroughText() {
        var style = TextStyle()
        style.isStrikethrough = true
        let result = ANSIRenderer.render("Strike", with: style)
        #expect(result.contains("\u{1B}[9m"))
        #expect(result.contains("Strike"))
        #expect(result.hasSuffix(ANSIRenderer.reset))
    }

    @Test("Combined styles produce semicolon-separated codes")
    func combinedStyles() {
        var style = TextStyle()
        style.isBold = true
        style.isUnderlined = true
        let result = ANSIRenderer.render("Both", with: style)
        #expect(result.contains("\u{1B}[1;4m"))
    }

    @Test("Foreground color produces correct code")
    func foregroundColor() {
        var style = TextStyle()
        style.foregroundColor = .red
        let result = ANSIRenderer.render("Red", with: style)
        #expect(result.contains("\u{1B}[31m"))
    }

    @Test("Background color produces correct code")
    func backgroundColor() {
        var style = TextStyle()
        style.backgroundColor = .blue
        let result = ANSIRenderer.render("Blue", with: style)
        #expect(result.contains("\u{1B}[44m"))
    }

    @Test("RGB foreground uses 38;2;r;g;b format")
    func rgbForeground() {
        var style = TextStyle()
        style.foregroundColor = Color.rgb(255, 128, 0)
        let result = ANSIRenderer.render("RGB", with: style)
        #expect(result.contains("38;2;255;128;0"))
    }

    @Test("RGB background uses 48;2;r;g;b format")
    func rgbBackground() {
        var style = TextStyle()
        style.backgroundColor = Color.rgb(0, 255, 128)
        let result = ANSIRenderer.render("RGB", with: style)
        #expect(result.contains("48;2;0;255;128"))
    }

    @Test("Palette256 foreground uses 38;5;n format")
    func palette256Foreground() {
        var style = TextStyle()
        style.foregroundColor = Color.palette(42)
        let result = ANSIRenderer.render("Pal", with: style)
        #expect(result.contains("38;5;42"))
    }

    @Test("Palette256 background uses 48;5;n format")
    func palette256Background() {
        var style = TextStyle()
        style.backgroundColor = Color.palette(200)
        let result = ANSIRenderer.render("Pal", with: style)
        #expect(result.contains("48;5;200"))
    }

    @Test("Bright foreground uses correct code")
    func brightForeground() {
        var style = TextStyle()
        style.foregroundColor = .brightRed
        let result = ANSIRenderer.render("Bright", with: style)
        #expect(result.contains("\u{1B}[91m"))
    }

    @Test("Bright background uses correct code")
    func brightBackground() {
        var style = TextStyle()
        style.backgroundColor = .brightBlue
        let result = ANSIRenderer.render("Bright", with: style)
        #expect(result.contains("\u{1B}[104m"))
    }
}

// MARK: - Convenience Methods Tests

@MainActor
@Suite("ANSIRenderer Convenience Tests")
struct ANSIRendererConvenienceTests {

    @Test("colorize with foreground applies color")
    func colorizeForeground() {
        let result = ANSIRenderer.colorize("Hello", foreground: .green)
        #expect(result.contains("\u{1B}[32m"))
        #expect(result.stripped == "Hello")
    }

    @Test("colorize with background applies color")
    func colorizeBackground() {
        let result = ANSIRenderer.colorize("Hello", background: .red)
        #expect(result.contains("\u{1B}[41m"))
    }

    @Test("colorize with bold applies bold")
    func colorizeBold() {
        let result = ANSIRenderer.colorize("Hello", bold: true)
        #expect(result.contains("\u{1B}[1m"))
    }

    @Test("colorize with all options applies foreground, background, and bold")
    func colorizeAll() {
        let result = ANSIRenderer.colorize("Hello", foreground: .white, background: .blue, bold: true)
        #expect(result.stripped == "Hello")
        #expect(result.contains("\u{1B}[1;37;44m"))
    }

    @Test("colorize without options returns plain text")
    func colorizeNoOptions() {
        let result = ANSIRenderer.colorize("Plain")
        #expect(result == "Plain")
    }

    @Test("backgroundCode produces correct sequence")
    func backgroundCodeMethod() {
        let code = ANSIRenderer.backgroundCode(for: .green)
        #expect(code == "\u{1B}[42m")
    }

    @Test("applyPersistentBackground wraps with bg code")
    func persistentBackground() {
        let result = ANSIRenderer.applyPersistentBackground("Text", color: .blue)
        #expect(result.contains("\u{1B}[44m"))
    }

    @Test("applyPersistentBackground replaces inner resets")
    func persistentBackgroundReplacesResets() {
        let input = "Before\(ANSIRenderer.reset)After"
        let result = ANSIRenderer.applyPersistentBackground(input, color: .red)
        // After reset, the bg code should be re-applied
        let bgCode = ANSIRenderer.backgroundCode(for: .red)
        // The reset in the middle should be followed by the bg code
        #expect(result.contains(ANSIRenderer.reset + bgCode))
    }
}

// MARK: - Cursor Control Tests

@MainActor
@Suite("ANSIRenderer Cursor Control Tests")
struct ANSIRendererCursorTests {

    @Test("moveCursor generates correct sequence")
    func moveCursor() {
        let result = ANSIRenderer.moveCursor(toRow: 5, column: 10)
        #expect(result == "\u{1B}[5;10H")
    }

    @Test("hideCursor and showCursor codes")
    func cursorVisibility() {
        #expect(ANSIRenderer.hideCursor == "\u{1B}[?25l")
        #expect(ANSIRenderer.showCursor == "\u{1B}[?25h")
    }

    @Test("Alternate screen codes")
    func alternateScreen() {
        #expect(ANSIRenderer.enterAlternateScreen == "\u{1B}[?1049h")
        #expect(ANSIRenderer.exitAlternateScreen == "\u{1B}[?1049l")
    }
}
