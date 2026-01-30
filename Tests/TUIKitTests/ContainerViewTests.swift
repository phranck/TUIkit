//
//  ContainerViewTests.swift
//  TUIKit
//
//  Tests for container views: Alert, Dialog, Menu.
//

import Testing

@testable import TUIKit

@Suite("Alert Tests")
struct AlertTests {

    @Test("Alert can be created with title and message")
    func alertCreation() {
        let alert = Alert(title: "Test", message: "Test message")
        #expect(alert.title == "Test")
        #expect(alert.message == "Test message")
    }

    @Test("Alert renders with border")
    func alertRendering() {
        let alert = Alert(title: "Warning", message: "Something happened")
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(alert, context: context)
        #expect(buffer.height > 2)
        // Should have border characters
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Warning"))
        #expect(allContent.contains("Something happened"))
    }
}

@Suite("Dialog Tests")
struct DialogTests {

    @Test("Dialog can be created with title and content")
    func dialogCreation() {
        let dialog = Dialog(title: "Settings") {
            Text("Option 1")
            Text("Option 2")
        }
        #expect(dialog.title == "Settings")
    }

    @Test("Dialog renders with panel styling")
    func dialogRendering() {
        let dialog = Dialog(title: "Test Dialog") {
            Text("Content here")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(dialog, context: context)
        #expect(buffer.height > 1)
        // Should contain title and content
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Test Dialog"))
        #expect(allContent.contains("Content here"))
    }
}

@Suite("Menu Tests")
struct MenuTests {

    @Test("MenuItem can be created with label")
    func menuItemCreation() {
        let item = MenuItem(label: "Option 1")
        #expect(item.label == "Option 1")
        #expect(item.id == "Option 1")
        #expect(item.shortcut == nil)
    }

    @Test("MenuItem can have shortcut")
    func menuItemWithShortcut() {
        let item = MenuItem(label: "Quit", shortcut: "q")
        #expect(item.label == "Quit")
        #expect(item.shortcut == "q")
    }

    @Test("Menu can be created with items")
    func menuCreation() {
        let menu = Menu(
            title: "Test Menu",
            items: [
                MenuItem(label: "Option 1", shortcut: "1"),
                MenuItem(label: "Option 2", shortcut: "2"),
            ],
            selectedIndex: 0
        )
        #expect(menu.title == "Test Menu")
        #expect(menu.items.count == 2)
        #expect(menu.selectedIndex == 0)
    }

    @Test("Menu renders with title and border")
    func menuRendering() {
        let menu = Menu(
            title: "My Menu",
            items: [
                MenuItem(label: "First"),
                MenuItem(label: "Second"),
            ]
        )
        let context = RenderContext(availableWidth: 80, availableHeight: 24)
        let buffer = renderToBuffer(menu, context: context)
        #expect(!buffer.isEmpty)
        let allContent = buffer.lines.joined()
        // Title should be present
        #expect(allContent.contains("My Menu"))
        // Border characters should be present (rounded style)
        #expect(allContent.contains("╭") || allContent.contains("│"))
    }

    @Test("Menu clamps selectedIndex to valid range")
    func menuClampsIndex() {
        let menu = Menu(
            items: [MenuItem(label: "Only")],
            selectedIndex: 99
        )
        #expect(menu.selectedIndex == 0)
    }
}
