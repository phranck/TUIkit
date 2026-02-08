//  🖥️ TUIKit — Terminal UI Kit for Swift
//  ComponentViewTests.swift
//
//  Created by LAYERED.work
//  License: MIT

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - Box Tests

@MainActor
@Suite("Box Tests")
struct BoxTests {

    @Test("Box renders with border around content")
    func boxRendersWithBorder() {
        let box = Box(.line) {
            Text("Hi")
        }
        let context = testContext()
        let buffer = renderToBuffer(box, context: context)

        // Box = border top + content + border bottom = 3 lines minimum
        #expect(buffer.height >= 3)
        // Width = content width + 2 (left + right border)
        #expect(buffer.width >= 4) // "Hi" (2) + borders (2)
    }

    @Test("Box renders empty content")
    func boxEmptyContent() {
        let box = Box(.line) {
            EmptyView()
        }
        let context = testContext()
        let buffer = renderToBuffer(box, context: context)

        // EmptyView produces empty buffer, so bordered empty = empty
        #expect(buffer.isEmpty)
    }

    @Test("Box with multiple children renders vertically")
    func boxMultipleChildren() {
        let box = Box(.line) {
            Text("Line 1")
            Text("Line 2")
        }
        let context = testContext()
        let buffer = renderToBuffer(box, context: context)

        // Top border + 2 content lines + bottom border = 4
        #expect(buffer.height >= 4)
    }

    @Test("Box delegates to body (is composite, not Renderable)")
    func boxIsComposite() {
        let box = Box {
            Text("Test")
        }
        // Box should NOT conform to Renderable — it uses body
        #expect(!(box is Renderable))
    }
}

// MARK: - Card Tests

@MainActor
@Suite("Card Tests")
struct CardTests {

    @Test("Card renders with border")
    func cardRenders() {
        let card = Card(title: "Test") {
            Text("Hello")
        }
        let context = testContext()
        let buffer = renderToBuffer(card, context: context)

        // Should have top border + content + bottom border
        #expect(buffer.height >= 3)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Hello"))
        #expect(allContent.contains("Test")) // title
    }

    @Test("Card without title renders")
    func cardNoTitleRenders() {
        let card = Card {
            Text("Content")
        }
        let context = testContext()
        let buffer = renderToBuffer(card, context: context)

        #expect(buffer.height >= 3)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Content"))
    }

    @Test("Card with footer is taller than without")
    func cardFooterAddsHeight() {
        let cardWithout = Card(title: "Test") {
            Text("Body")
        }
        let cardWith = Card(title: "Test") {
            Text("Body")
        } footer: {
            Text("Footer")
        }
        let context = testContext()

        let bufferWithout = renderToBuffer(cardWithout, context: context)
        let bufferWith = renderToBuffer(cardWith, context: context)

        #expect(bufferWith.height > bufferWithout.height)
    }
}

// MARK: - Panel Tests

@MainActor
@Suite("Panel Tests")
struct PanelTests {

    @Test("Panel renders with border and title")
    func panelRenders() {
        let panel = Panel("Test Panel") {
            Text("Hello")
        }
        let context = testContext()
        let buffer = renderToBuffer(panel, context: context)

        // Top border (with title) + content + bottom border
        #expect(buffer.height >= 3)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Test Panel")) // title
        #expect(allContent.contains("Hello"))
    }

    @Test("Panel with footer is taller")
    func panelFooterAddsHeight() {
        let panelWithout = Panel("Test") {
            Text("Body")
        }
        let panelWith = Panel("Test") {
            Text("Body")
        } footer: {
            Text("Footer")
        }
        let context = testContext()

        let bufferWithout = renderToBuffer(panelWithout, context: context)
        let bufferWith = renderToBuffer(panelWith, context: context)

        #expect(bufferWith.height > bufferWithout.height)
    }
}

// MARK: - ContainerView Tests

@MainActor
@Suite("ContainerView Direct Tests")
struct ContainerViewDirectTests {

    @Test("ContainerView renders with border")
    func containerViewRenders() {
        let container = ContainerView(title: "Test") {
            Text("Content")
        }
        let context = testContext()
        let buffer = renderToBuffer(container, context: context)

        #expect(buffer.height >= 3)
        let allContent = buffer.lines.joined()
        #expect(allContent.contains("Test")) // title
        #expect(allContent.contains("Content"))
    }
}

// MARK: - ForEach Tests

@MainActor
@Suite("ForEach Tests")
struct ForEachTests {

    struct TestItem: Identifiable {
        let id: String
        let name: String
    }

    @Test("ForEach generates correct number of views")
    func forEachViewGeneration() {
        let items = [TestItem(id: "a", name: "Alpha"), TestItem(id: "b", name: "Beta")]
        let forEach = ForEach(items) { item in
            Text(item.name)
        }

        // Verify content closure works
        var generatedTexts: [String] = []
        for item in forEach.data {
            let view = forEach.content(item)
            generatedTexts.append(view.content)
        }
        #expect(generatedTexts == ["Alpha", "Beta"])
    }

    // NOTE: ForEach inside VStack/HStack cannot be tested via renderToBuffer
    // directly. ForEach is flattened into ViewArray by @ViewBuilder.buildArray
    // at compile time — not at render time. Direct construction in tests
    // bypasses the builder, so ForEach remains unflattened and produces
    // an empty buffer. This is expected behavior, matching SwiftUI's pattern.

    @Test("ForEach with empty array produces empty result")
    func forEachEmptyArray() {
        let items: [TestItem] = []
        let forEach = ForEach(items) { item in
            Text(item.name)
        }

        #expect(forEach.data.isEmpty)

        // Also test via ViewArray (which is what @ViewBuilder produces)
        let viewArray = ViewArray<Text>([])
        let context = testContext()
        let buffer = renderToBuffer(viewArray, context: context)
        #expect(buffer.isEmpty)
    }
}
