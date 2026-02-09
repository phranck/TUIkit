//  🖥️ TUIKit — Terminal UI Kit for Swift
//  StatusBarSystemItemsModifierTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing
@testable import TUIkit

@Suite("StatusBarSystemItemsModifier")
struct StatusBarSystemItemsModifierTests {
    @Test("Default shows only quit item")
    func defaultShowsOnlyQuit() {
        let statusBar = StatusBarState()
        #expect(statusBar.showSystemItems == true)
        #expect(statusBar.showThemeItem == false)
        #expect(statusBar.showAppearanceItem == false)

        let items = statusBar.currentSystemItems
        #expect(items.count == 1)
        #expect(items.first?.shortcut == "q")
    }

    @Test("Theme item can be enabled")
    func themeItemEnabled() {
        let statusBar = StatusBarState()
        statusBar.showThemeItem = true

        let items = statusBar.currentSystemItems
        #expect(items.count == 2)
        #expect(items.contains { $0.shortcut == "q" })
        #expect(items.contains { $0.shortcut == "t" })
    }

    @Test("Appearance item can be enabled")
    func appearanceItemEnabled() {
        let statusBar = StatusBarState()
        statusBar.showAppearanceItem = true

        let items = statusBar.currentSystemItems
        #expect(items.count == 2)
        #expect(items.contains { $0.shortcut == "q" })
        #expect(items.contains { $0.shortcut == "a" })
    }

    @Test("Both theme and appearance can be enabled")
    func bothItemsEnabled() {
        let statusBar = StatusBarState()
        statusBar.showThemeItem = true
        statusBar.showAppearanceItem = true

        let items = statusBar.currentSystemItems
        #expect(items.count == 3)
        #expect(items.contains { $0.shortcut == "q" })
        #expect(items.contains { $0.shortcut == "t" })
        #expect(items.contains { $0.shortcut == "a" })
    }

    @MainActor
    @Test("Modifier creates correct view")
    func modifierCreatesView() {
        let view = Text("Test")
            .statusBarSystemItems(theme: true, appearance: true)

        #expect(view is StatusBarSystemItemsModifier<Text>)
    }
}
