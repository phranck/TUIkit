//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ContentUnavailableViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

@MainActor
@Suite("ContentUnavailableView Tests")
struct ContentUnavailableViewTests {

    @Test("Full init renders label, description, and actions")
    func fullInit() {
        let view = ContentUnavailableView {
            Text("Title")
        } description: {
            Text("Description text")
        } actions: {
            Text("[Action]")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()
        #expect(content.contains("Title"))
        #expect(content.contains("Description text"))
        #expect(content.contains("[Action]"))
    }

    @Test("Label-only init renders just the label")
    func labelOnly() {
        let view = ContentUnavailableView {
            Text("Only Label")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()
        #expect(content.contains("Only Label"))
    }

    @Test("String convenience init renders title text")
    func stringInit() {
        let view = ContentUnavailableView("Empty State")
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()
        #expect(content.contains("Empty State"))
    }

    @Test("String with description init renders both")
    func stringWithDescription() {
        let view = ContentUnavailableView("No Items", description: "Add items to get started.")
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()
        #expect(content.contains("No Items"))
        #expect(content.contains("Add items to get started."))
    }

    @Test("Search preset renders 'No Results' text")
    func searchPreset() {
        let view = ContentUnavailableView<Text, Text, EmptyView>.search
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()
        #expect(content.contains("No Results"))
        #expect(content.contains("Check the spelling"))
    }

    @Test("Search with text renders query in title")
    func searchWithText() {
        let view = ContentUnavailableView<Text, Text, EmptyView>.search(text: "swift")
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()
        #expect(content.contains("No Results for 'swift'"))
    }

    @Test("Label and description init renders both sections")
    func labelAndDescription() {
        let view = ContentUnavailableView {
            Text("Header")
        } description: {
            Text("Subtext")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        let content = buffer.lines.joined()
        #expect(content.contains("Header"))
        #expect(content.contains("Subtext"))
    }

    @Test("Content is centered horizontally")
    func horizontalCentering() {
        let view = ContentUnavailableView("Centered")
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        #expect(!buffer.isEmpty)
        // The line should have leading spaces for centering
        if let firstLine = buffer.lines.first {
            let stripped = firstLine.stripped
            let leadingSpaces = stripped.prefix(while: { $0 == " " }).count
            // "Centered" is 8 chars in 80-wide terminal → ~36 leading spaces
            #expect(leadingSpaces > 0)
        }
    }

    @Test("Full init with all sections produces multiple lines")
    func multipleLinesSections() {
        let view = ContentUnavailableView {
            Text("Label")
        } description: {
            Text("Desc")
        } actions: {
            Text("Act")
        }
        let context = RenderContext(availableWidth: 80, availableHeight: 24, tuiContext: TUIContext())
        let buffer = renderToBuffer(view, context: context)
        // Label + spacing + description + spacing + actions = at least 5 lines
        #expect(buffer.height >= 5)
    }
}
