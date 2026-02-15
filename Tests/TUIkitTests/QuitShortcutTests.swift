//  🖥️ TUIKit — Terminal UI Kit for Swift
//  QuitShortcutTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("QuitShortcut Tests")
struct QuitShortcutTests {

    // MARK: - Default Preset (.q)

    @Test("Default quit shortcut matches lowercase q")
    func defaultMatchesLowercaseQ() {
        let shortcut = QuitShortcut.q
        let event = KeyEvent(key: .character("q"))
        #expect(shortcut.matches(event))
    }

    @Test("Default quit shortcut matches uppercase Q")
    func defaultMatchesUppercaseQ() {
        let shortcut = QuitShortcut.q
        let event = KeyEvent(key: .character("Q"))
        #expect(shortcut.matches(event))
    }

    @Test("Default quit shortcut does not match other keys")
    func defaultDoesNotMatchOtherKeys() {
        let shortcut = QuitShortcut.q
        #expect(!shortcut.matches(KeyEvent(key: .character("a"))))
        #expect(!shortcut.matches(KeyEvent(key: .escape)))
        #expect(!shortcut.matches(KeyEvent(key: .enter)))
    }

    @Test("Default quit shortcut does not match Ctrl+Q")
    func defaultDoesNotMatchCtrlQ() {
        let shortcut = QuitShortcut.q
        let event = KeyEvent(key: .character("q"), ctrl: true)
        #expect(!shortcut.matches(event))
    }

    // MARK: - Escape Preset

    @Test("Escape preset matches escape key")
    func escapeMatchesEscapeKey() {
        let shortcut = QuitShortcut.escape
        let event = KeyEvent(key: .escape)
        #expect(shortcut.matches(event))
    }

    @Test("Escape preset does not match q key")
    func escapeDoesNotMatchQ() {
        let shortcut = QuitShortcut.escape
        let event = KeyEvent(key: .character("q"))
        #expect(!shortcut.matches(event))
    }

    @Test("Escape preset has correct display symbol")
    func escapeHasCorrectSymbol() {
        let shortcut = QuitShortcut.escape
        #expect(shortcut.shortcutSymbol == Shortcut.escape)
        #expect(shortcut.label == "quit")
    }

    // MARK: - Ctrl+Q Preset

    @Test("Ctrl+Q preset matches Ctrl+Q")
    func ctrlQMatchesCtrlQ() {
        let shortcut = QuitShortcut.ctrlQ
        let event = KeyEvent(key: .character("q"), ctrl: true)
        #expect(shortcut.matches(event))
    }

    @Test("Ctrl+Q preset does not match plain q")
    func ctrlQDoesNotMatchPlainQ() {
        let shortcut = QuitShortcut.ctrlQ
        let event = KeyEvent(key: .character("q"))
        #expect(!shortcut.matches(event))
    }

    @Test("Ctrl+Q preset has correct display symbol")
    func ctrlQHasCorrectSymbol() {
        let shortcut = QuitShortcut.ctrlQ
        #expect(shortcut.shortcutSymbol == Shortcut.ctrl("q"))
        #expect(shortcut.label == "quit")
    }

    // MARK: - Ctrl+C Preset

    @Test("Ctrl+C preset matches Ctrl+C")
    func ctrlCMatchesCtrlC() {
        let shortcut = QuitShortcut.ctrlC
        let event = KeyEvent(key: .character("c"), ctrl: true)
        #expect(shortcut.matches(event))
    }

    @Test("Ctrl+C preset does not match plain c")
    func ctrlCDoesNotMatchPlainC() {
        let shortcut = QuitShortcut.ctrlC
        let event = KeyEvent(key: .character("c"))
        #expect(!shortcut.matches(event))
    }

    @Test("Ctrl+C preset has correct display symbol")
    func ctrlCHasCorrectSymbol() {
        let shortcut = QuitShortcut.ctrlC
        #expect(shortcut.shortcutSymbol == Shortcut.ctrl("c"))
        #expect(shortcut.label == "quit")
    }

    // MARK: - Custom Shortcut

    @Test("Custom shortcut matches configured key")
    func customShortcutMatches() {
        let shortcut = QuitShortcut(
            key: .f12,
            shortcutSymbol: Shortcut.f12,
            label: "exit"
        )
        let event = KeyEvent(key: .f12)
        #expect(shortcut.matches(event))
        #expect(shortcut.label == "exit")
    }

    @Test("Custom shortcut does not match other keys")
    func customShortcutDoesNotMatchOthers() {
        let shortcut = QuitShortcut(
            key: .f12,
            shortcutSymbol: Shortcut.f12,
            label: "exit"
        )
        #expect(!shortcut.matches(KeyEvent(key: .character("q"))))
        #expect(!shortcut.matches(KeyEvent(key: .escape)))
    }

    // MARK: - StatusBarState Integration

    @Test("StatusBarState uses configured quit shortcut for system items")
    func statusBarStateUsesConfiguredShortcut() {
        let state = StatusBarState()
        state.quitShortcut = .escape

        let systemItems = state.currentSystemItems
        let quitItem = systemItems.first { $0.order == .quit }
        #expect(quitItem != nil)
        #expect(quitItem?.shortcut == Shortcut.escape)
        #expect(quitItem?.label == "quit")
    }

    @Test("StatusBarState defaults to q shortcut")
    func statusBarStateDefaultsToQ() {
        let state = StatusBarState()

        let systemItems = state.currentSystemItems
        let quitItem = systemItems.first { $0.order == .quit }
        #expect(quitItem != nil)
        #expect(quitItem?.shortcut == "q")
    }
}
