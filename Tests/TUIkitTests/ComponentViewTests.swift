//
//  ComponentViewTests.swift
//  TUIkit
//
//  Tests for Box, Card, Panel, ContainerConfig, ContainerView, and ForEach views.
//

import Testing

@testable import TUIkit

// MARK: - Test Helpers

/// Creates a default render context for testing.
private func testContext(width: Int = 40, height: Int = 24) -> RenderContext {
    RenderContext(availableWidth: width, availableHeight: height)
}

// MARK: - Box Tests

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

@Suite("Card Tests")
struct CardTests {

    @Test("Card can be created with footer")
    func cardWithFooter() {
        let card = Card(title: "Info") {
            Text("Body")
        } footer: {
            Text("Footer")
        }
        #expect(card.title == "Info")
        #expect(card.footer != nil)
    }

    @Test("Card renders with border")
    func cardRenders() {
        let card = Card(title: "Test") {
            Text("Hello")
        }
        let context = testContext()
        let buffer = card.renderToBuffer(context: context)

        // Should have top border + content + bottom border
        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
    }

    @Test("Card without title renders")
    func cardNoTitleRenders() {
        let card = Card {
            Text("Content")
        }
        let context = testContext()
        let buffer = card.renderToBuffer(context: context)

        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
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

        let bufferWithout = cardWithout.renderToBuffer(context: context)
        let bufferWith = cardWith.renderToBuffer(context: context)

        #expect(bufferWith.height > bufferWithout.height)
    }

}

// MARK: - Panel Tests

@Suite("Panel Tests")
struct PanelTests {

    @Test("Panel can be created with footer")
    func panelWithFooter() {
        let panel = Panel("Info") {
            Text("Content")
        } footer: {
            Text("Done")
        }
        #expect(panel.title == "Info")
        #expect(panel.footer != nil)
    }

    @Test("Panel renders with border and title")
    func panelRenders() {
        let panel = Panel("Test Panel") {
            Text("Hello")
        }
        let context = testContext()
        let buffer = panel.renderToBuffer(context: context)

        // Top border (with title) + content + bottom border
        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
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

        let bufferWithout = panelWithout.renderToBuffer(context: context)
        let bufferWith = panelWith.renderToBuffer(context: context)

        #expect(bufferWith.height > bufferWithout.height)
    }

    @Test("Panel default padding is horizontal only")
    func panelDefaultPadding() {
        let panel = Panel("Test") {
            Text("Content")
        }
        #expect(panel.config.padding.leading == 1)
        #expect(panel.config.padding.trailing == 1)
        #expect(panel.config.padding.top == 0)
        #expect(panel.config.padding.bottom == 0)
    }
}

// MARK: - ContainerConfig Tests

@Suite("ContainerConfig Tests")
struct ContainerConfigTests {

    @Test("Default config has expected values")
    func defaultConfig() {
        let config = ContainerConfig.default
        #expect(config.borderStyle == nil)
        #expect(config.borderColor == nil)
        #expect(config.titleColor == nil)
        #expect(config.padding.leading == 1)
        #expect(config.padding.trailing == 1)
        #expect(config.showFooterSeparator == true)
    }

}

// MARK: - ContainerView Tests

@Suite("ContainerView Direct Tests")
struct ContainerViewDirectTests {

    @Test("ContainerView renders with border")
    func containerViewRenders() {
        let container = ContainerView(title: "Test") {
            Text("Content")
        }
        let context = testContext()
        let buffer = container.renderToBuffer(context: context)

        #expect(buffer.height >= 3)
        #expect(!buffer.isEmpty)
    }

}

// MARK: - ForEach Tests

@Suite("ForEach Tests")
struct ForEachTests {

    struct TestItem: Identifiable {
        let id: String
        let name: String
    }

    @Test("ForEach can be created with Identifiable data")
    func forEachIdentifiable() {
        let items = [TestItem(id: "1", name: "One"), TestItem(id: "2", name: "Two")]
        let forEach = ForEach(items) { item in
            Text(item.name)
        }
        #expect(forEach.data.count == 2)
    }

    @Test("ForEach can be created with explicit ID key path")
    func forEachExplicitId() {
        let names = ["Anna", "Bob", "Clara"]
        let forEach = ForEach(names, id: \.self) { name in
            Text(name)
        }
        #expect(forEach.data.count == 3)
    }

    @Test("ForEach can be created with Range")
    func forEachRange() {
        let forEach = ForEach(0..<5) { index in
            Text("Item \(index)")
        }
        #expect(forEach.data.count == 5)
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
}
